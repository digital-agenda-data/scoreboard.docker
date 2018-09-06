# Scoreboard docker stack
Scoreboard docker setup

## Scoreboard stack - first deploy steps

### Clone repository locally:

    git clone git@github.com:digital-agenda-data/scoreboard.docker.git
    
 If it's already saved, make sure it's on the latest version

    cd scoreboard.docker
    git pull
 
### Configuring the environment variables - .env file

#### Create the .env file from the appropriate .env.<DEPLOY> file 
    
* Production:    
    cp .env.PROD .env
* Test/Staging:    
    cp .env.TEST .env    
* Development:    
    cp .env.DEV .env       

#### URLs
1. DEPLOY_TYPE - should be set to  TEST, PROD or DEV - will be used in NGINX, SOLR and CRONTAB configuration
2. SCOREBOARDBASE_URL - the main domain name under which the site will be used:
    * FOR PRODUCTION it is digital-agenda-data.eu
    * For TEST it is test.digital-agenda-data.eu
    * For DEV it is dev.digital-agenda-data.eu
    * Note: to change these URLs, you must also edit nginx/project-${DEPLOY_TYPE} config files (nginx server_name and Plone VirtualHostBase)
3. ELDA_SPARQL_ENDPOINT - used by ELDA, is the way to access the SPARQL Virtuoso url both from the browser and the container.
4. SCOREBOARD_URL - the main URL (the one that is accessed from the browser), used by Content Registry - example:
 https://digital-agenda-data.eu, or  http://test.digital-agenda-data.eu or http://dev.digital-agenda-data.eu:81


#### VIRTUOSO DB PASSWORDS 
If you are restoring the database from another environment, please copy here the same passwords that are saved in the database:

5. VIRTUOSO_DBA_PASSWORD - dba user password
6. CR_DB_PASSWORD - cr3user password
7. CR_DB_RO_PASSWORD - cr3rouser password


#### MARIADB PASSWORDS 

8. MARIADB_PASSWORD - Mariadb root password 
9. MARIADB_PIWIK_PASSWORD - Mariadb piwik user password - save it for the PIWIK configuration

#### Other variables
10. TZ - default Timezone for all containers - Europe/Copenhagen


### Editing the docker-compose.yml file - NGINX port

You need to set the NGINX port to an available value in the docker-compose file. It is located in the nginx->ports section and has the format:
`- <HOST_PORT>:<CONTAINER_PORT>`

For example, if port 81 is not available, but 82 is, we modify this:

```
  nginx:
    image: nginx:1.13
    depends_on:
    - haproxy
    - piwik
    - solr
    restart: always
    ports:
    - 81:80
```
into:

```
  nginx:
    image: nginx:1.13
    depends_on:
    - haproxy
    - piwik
    - solr
    restart: always
    ports:
    - 82:80
```

    links:
    - nginx:${SCOREBOARDBASE_URL}


### Editing the docker-compose.yml file - plone image

If you want to deploy another version on plone site ( DEV or TEST) you need to set the correct **image** name in the **plone** section of the docker-compose.yml:


So:
```
  plone:
    image: digitalagendadata/plone:latest
    restart: always
    depends_on:
    - zeoserver
    - memcached
    environment:
      ZEO_ADDRESS: "zeoserver:8080"
      MEMCACHE_SERVER: "memcached:11211"
      SOLR_URL: "http://solr:8983/solr/scoreboard"
```
will become
```
  plone:
    image: digitalagendadata/plone.staging
    restart: always
    depends_on:
    - zeoserver
    - memcached
    environment:
      ZEO_ADDRESS: "zeoserver:8080"
      MEMCACHE_SERVER: "memcached:11211"
      SOLR_URL: "http://solr:8983/solr/scoreboard"
```

### Prepare URLs: NGINX files and DNS or /etc/hosts entries:

#### PROD

* digital-agenda-data.eu should be pointing to the server you are installing the stack in DNS
* HTTPS and letsencrypt should be configured on the Apache that is installed on the same server
* The Apache should redirect to the port configured to the nginx in the docker-compose [file](#editing-the-docker-compose.yml-file---nginx-port)

#### TEST

* test.digital-agenda-data.eu should be pointing to the server you are installing the stack in DNS
* HTTPS and letsencrypt should be configured on the Apache that is installed on the same server
* The Apache should redirect to the port configured to the nginx in the docker-compose [file](#editing-the-docker-compose.yml-file---nginx-port)


#### DEV

* <SCOREBOARDBASE_URL> host should be pointing to the server you are installing the stack in /etc/hosts
* The configuration files from the repository are an example of a <SCOREBOARDBASE_URL> that is configured on a different port than 80
* The **elda** container needs access to the external SPARQL link from inside the container. If you are using /etc/hosts, the url will need to be redirected to the NGINX server. That is why the NGINX exposed port must be added to NGINX configuration, in the server that has the /sparql location configured.
* If you are changing the default URLs from the .env.DEV file, you also need to updated them accordingly in the NGINX configuration file - nginx/project-DEV.conf


### Add SSH key to the cron container  - Only on production

The `exportcl.sh` script that updates the [RDF repository](https://github.com/digital-agenda-data/rdf) runs daily on production. It needs to use a SSH private key that has write access to the GIT repo.

####  Copy existing SSH configurations from the current `exportcl.sh` host

1. Connect to the existing host using the scoreboard user
2. Copy the ~/.ssh contents
3. Move them to the cron/ssh directory

If you are using the same user/host, you need just to:

     cd <SCOREBOARD.DOCKER_HOME>
     cp ~/.ssh/* cron/ssh/
     
####  Generate new key

Run in <SCOREBOARD.DOCKER_HOME>: 

1. Create a new key 

        ssh-keygen -t rsa -b 4096 -C "scoreboard@digital-agenda-data.eu" -N '' -f cron/ssh/id_rsa
    
2. Open the public key file an copy its contents:

        cat cron/ssh/id_rsa.pub 

3. Copy the file contents in: https://github.com/digital-agenda-data/rdf/settings/keys/new    

4. Keep the existing `cron/ssh/known_hosts` file because it contains the github servers


### Start stack

#### PRODUCTION - multiple plone servers

    docker-compose up -d --scale plone=2

#### DEV, TEST - one plone server

    docker-compose up -d

### Import data

#### Import plone data


1. Identify zeo docker name - <ZEO_DOCKER_NAME>:

      docker-compose ps  | grep zeo

2. Copy blobstorage and filestorage directories from the source plone site and put it into the current directory

3. Copy blobstorage and filestorage directories  to the zeoserver data volume:

    docker cp blobstorage <ZEO_DOCKER_NAME>:/data/
    docker cp filestorage <ZEO_DOCKER_NAME>:/data/

4. Run chown on the /data directory from the server to make sure all the files have the correct permissions
    docker-compose exec zeoserver sh -c "chown -R 500:500 /data"

5. Restart zeoserver 

    docker-compose restart zeoserver

6. Check zeoserver logs for errors

    docker-compose logs -f zeoserver

7. Restart plone

    docker-compose restart plone

8. Check plone logs for errors

    docker-compose logs -f plone


#### Import virtuoso db data

1. Stop virtuoso server

    docker-compose stop virtuoso

2. Identify virtuoso docker name - <VIRTUOSO_DOCKER_NAME> ( check first column on the following command) :

      docker-compose ps  | grep virtuoso

3. Copy database backup from source database and name it virtuoso.db

4. Identify volume location on the host - <VIRTUOSO_VOLUME_PATH>

    docker inspect <VIRTUOSO_DOCKER_NAME> | grep volume

or

    docker ps --filter expose=8890 --format "{{.Names}}" | xargs docker inspect | grep virtuoso_db

## TODO: rewrite so it works also on Windows

<VIRTUOSO_VOLUME_PATH> should be similar to /var/lib/docker/volumes/<STACKNAME>_virtuoso_db/_data

5. Clean-up the volume:

   sudo rm -rf <VIRTUOSO_VOLUME_PATH>/* 

6. Copy the database:

   sudo cp virtuoso.db <VIRTUOSO_VOLUME_PATH>/

7. Start server

    docker-compose start virtuoso

8. Check virtuoso logs for errors

    docker-compose logs -f virtuoso


#### Import CR data



#### Import PIWIK data - MARIADB

1. Run a backup on the source database. If you are not sure of the database password you can check it in the piwik directory:
    $ cd <PIWIK_LOCATION>
    $ grep password config/config.ini.php

2. Run the piwik database backup, providing the password:
    $ mysqldump -u piwik -p  piwik > /tmp/piwik.dump

3. Copy the database dump to the destination host using [scp](#copy-from-production)
  
4. Identify the docker name of the mariadb container <MARIADB_DOCKER_NAME>  ( run from the docker-compose.yml file location )
     docker-compose ps  | grep virtuoso

5. copy the database dump to the mariadb container  
    docker cp piwik.dump <MARIADB_DOCKER_NAME>:/tmp/piwik.dump
       
6. Import the database, providing the password set in the .env file:
    $ docker-compose exec mariadb bash
    $ mysql -u piwik -p piwik < /tmp/piwik.dump
      Enter password:
    $ exit
    
7. Restart the container and watch the logs for errors
    $ docker-compose restart mariadb
    $ docker-compose logs -f mariadb



#### Content registry configuration

1. Go to the init script location
     $ cd cr_init_scripts
2.
  * If you did not import the database, you need to run:
     $ ./init_conreg.sh
  * If you imported the database so all the users are already created, you need to run:     
     $ ./init_conreg_db_restore.sh



### Piwik configuration

1. Go to <SCOREBOARD_URL>/analytics/piwik/index.php?action=databaseSetup
2. Fill:
 * **Database Server** -db
 * **Login** - piwik
 * **Password** - <MARIADB_PIWIK_PASSWORD>
 * **Database Name** - piwik
 * **Table Prefix** - piwik_
 * **Adapter**  - PDO\MYSQL
3. Press **Next**
4. You will receive the message: ` Some tables in your database have the same names as the tables Matomo is trying to create `
Press **Reuse the existing tables »**
5. You will receive - **Reusing the Tables** - Press **Next**
6. Press **CONTINUE TO MATOMO**
7. Remember to configure the tracking url in Plone (<SCOREBOARD_URL>/portal_skins/custom/analytics.js/manage_main)

### Available URLs

1. Plone - <SCOREBOARD_URL>
2. Elda - always http://semantic.digital-agenda-data.eu/dataset (must be added in /etc/hosts for local development)
3. Content Registry - <SCOREBOARD_URL>/data/
4. Download - <SCOREBOARD_URL>/datasets/desi#download
5. Sparql - <SCOREBOARD_URL>/sparql
6. Piwik - <SCOREBOARD_URL>/analytics/index.php



## Scoreboard stack - upgrade 

### Pull the latest repository version

### If needed, update the images in docker-compose.yml

Manually modify docker-compose.yml with the new image version.

For example:
```
  plone:
    image: digitalagendadata/plone:1.0
 ```
to
```
  plone:
    image: digitalagendadata/plone:2.0
 ```

If you are updating the **PRODUCTION**  image version, you need to save the changes in [GIT](#push-modifications-in-git)  

### Update the environment variables values

Change environment variable value in the .env file.

### Update the configuration files

Update the available configuration files. Any update on PRODUCTION and TEST environments for  **cron/***, **solr/***, **nginx/*** should be saved in [GIT](#push-modifications-in-git).

### Upgrade an existing stack

#### Restart stack for configuration file changes:

If you only changed the configuration file, it's enough to run restart on the containers:

* For cron/ changes:
        
        docker-compose restart cron

* For nginx/ changes:
        
        docker-compose restart nginx

* For solr/ changes:
        
        docker-compose restart solr

#### Upgrade stack for environment or docker-compose.yml changes:

First you should take note how many plone instances you have running:

      docker-compose ps | grep -c plone

Use the number of running instances to run the upgrade:

      docker-compose up -d --scale plone=<NUMBER_OF_PLONE_INSTANCES>
     
      
## Docker images release

### To release a new Crontab image

The docker hub automated build can be found on https://hub.docker.com/r/digitalagendadata/scoreboard.cron/

The steps to create a new release, follow this steps on your Dev environment:

1. Update files located in [crontab directory](https://github.com/digital-agenda-data/scoreboard.docker/tree/master/crontab) -  docker image files and [cron directory](https://github.com/digital-agenda-data/scoreboard.docker/tree/master/cron) - scripts and crontab files )

2. Push the changes on master

       git add -A
       git commit
       git push

4. On every push to the master branch, a new digitalagendadata/scoreboard.cron:latest image is created. You can view the build status on: https://hub.docker.com/r/digitalagendadata/scoreboard.cron/builds/

4. Once the digitalagendadata/scoreboard.cron:latest image is succesfully built, you can test ( if needed ), and then create a new release. 
   
5. View most recent tag on git:

        git describe --tags
        
6. Choose a new tag, bigger than the latest one, using a MAJOR.MINOR format. Save it in a variable:

       export NEW_TAG="<NEW_TAG>"
       
7. Create and push tag on repo:       
     
       git tag -a "$NEW_TAG" -m "$NEW_TAG"
       git push origin $NEW_TAG

8. Follow the release on docker hub https://hub.docker.com/r/digitalagendadata/scoreboard.cron/builds/. The new image will have the following format:

       digitalagendadata/scoreboard.cron:$NEW_TAG
       
9. Update docker-compose.yml with the new image:
   
       sed -i 's/image: digitalagendadata\/scoreboard.cron.*/image: digitalagendadata\/scoreboard.cron:$NEW_TAG/' docker-compose.yml

10. Push the change on the GIT repo:
      
        git add docker-compose.yml
        git commit -m "Updated cron image to $NEW_TAG"
        git push




### To release a new Elda image

The docker hub automated build can be found on https://hub.docker.com/r/digitalagendadata/scoreboard.elda/

The steps to create a new release, follow this steps on your Dev environment:

1. Update files located in [elda directory](https://github.com/digital-agenda-data/scoreboard.docker/tree/master/elda)

2. Push the changes on master

       git add -A
       git commit
       git push

4. On every push to the master branch, a new digitalagendadata/scoreboard.elda:latest image is created. You can view the build status on: https://hub.docker.com/r/digitalagendadata/scoreboard.elda/builds/

4. Once the digitalagendadata/scoreboard.elda:latest image is succesfully built, you can test ( if needed ), and then create a new release. 
   
5. View most recent tag on git:

        git describe --tags
        
6. Choose a new tag, bigger than the latest one, using a MAJOR.MINOR format. Save it in a variable:

       export NEW_TAG="<NEW_TAG>"
       
7. Create and push tag on repo:       
     
       git tag -a "$NEW_TAG" -m "$NEW_TAG"
       git push origin $NEW_TAG

8. Follow the release on docker hub https://hub.docker.com/r/digitalagendadata/scoreboard.elda/builds/. The new image will have the following format:

       digitalagendadata/scoreboard.elda:$NEW_TAG
       
9. Update docker-compose.yml with the new image:
   
       sed -i 's/image: digitalagendadata\/scoreboard.elda.*/image: digitalagendadata\/scoreboard.elda:$NEW_TAG/' docker-compose.yml

10. Push the change on the GIT repo:
      
        git add docker-compose.yml
        git commit -m "Updated elda image to $NEW_TAG"
        git push



### To release a new Plone image


The docker hub automated build for the production plone images can be found:


| Environment        | Dockerfile location        | Base image    | Dockerhub  | How to trigger |
| ------------- |-------------|-------------|-------------|-----|
| PRODUCTION     | https://github.com/digital-agenda-data/scoreboard.docker/tree/master/plone | plone:4.3.17 | https://hub.docker.com/r/digitalagendadata/plone | Push on master or Tag |
| STAGING     | https://github.com/digital-agenda-data/scoreboard.docker/tree/master/plone/staging | digitalagendadata/plone:latest | https://hub.docker.com/r/digitalagendadata/plone.staging/ | New digitalagendadata/plone:latest |
| DEVEL     | https://github.com/digital-agenda-data/scoreboard.docker/tree/master/plone/devel | digitalagendadata/plone:latest | https://hub.docker.com/r/digitalagendadata/plone.devel/ | New digitalagendadata/plone:latest |


#### Create a new plone production release: 

1. Update files in https://github.com/digital-agenda-data/scoreboard.docker/tree/master/plone directory

2. Push the changes on master

       git add -A
       git commit
       git push

4. On every push to the master branch, a new digitalagendadata/plone:latest image is created. You can view the build status on: https://hub.docker.com/r/digitalagendadata/plone/builds/.

5. View most recent tag on git:

        git describe --tags
        
6. Choose a new tag, bigger than the latest one, using a MAJOR.MINOR format. Save it in a variable:

       export NEW_TAG="<NEW_TAG>"
       
7. Create and push tag on repo:       
     
       git tag -a "$NEW_TAG" -m "$NEW_TAG"
       git push origin $NEW_TAG

8. Follow the release on docker hub https://hub.docker.com/r/digitalagendadata/plone/builds/. The new image will have the following format:

       digitalagendadata/plone:$NEW_TAG
       
9. Update docker-compose.yml with the new image:
   
       sed -i 's/image: digitalagendadata\/plone.*/image: digitalagendadata\/plone:$NEW_TAG/' docker-compose.yml

10. Push the change on the GIT repo:
      
        git add docker-compose.yml
        git commit -m "Updated plone image to $NEW_TAG"
        git push


#### Create a new plone staging image:

The docker image is based on the digitalagendadata/plone:latest image. To reduce the image building time, if you need to do changes on production and on the staging image, try to combine them in a single commit.


1. Update files in the https://github.com/digital-agenda-data/scoreboard.docker/tree/master/plone/staging  directory

2. Push the changes on master

       git add -A
       git commit
       git push

4. On every push to the master branch, a new digitalagendadata/plone:latest image is created. You can view the build status on: https://hub.docker.com/r/digitalagendadata/plone/builds/. After the image is created, a new build will be started on https://hub.docker.com/r/digitalagendadata/plone.staging/builds/




#### Create a new plone devel image: 

The docker image is based on the digitalagendadata/plone:latest image. To reduce the image building time, if you need to do changes on production and on the devel image, try to combine them in a single commit.


1. Update files in the https://github.com/digital-agenda-data/scoreboard.docker/tree/master/plone/devel  directory

2. Push the changes on master

       git add -A
       git commit
       git push

4. On every push to the master branch, a new digitalagendadata/plone:latest image is created. You can view the build status on: https://hub.docker.com/r/digitalagendadata/plone/builds/. After the image is created, a new build will be started on https://hub.docker.com/r/digitalagendadata/plone.devel/builds/




## Tips

#### Plone CSS
If CSS does not look right on the Plone site:
<SCOREBOARD_URL>/portal_css/manage_cssForm - Uncheck reset.css and click SAVE


## TODO: Fix PIWIK - configure geoip2 for nginx
