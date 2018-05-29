# scoreboard.docker
Scoreboard docker setup

## Scoreboard stack deploy steps - all environments

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
2. SCOREBOARDBASE_URL - the main url under which the site will be used:
    * FOR PRODUCTION must be digital-agenda-data.eu
    * For TEST must be test.digital-agenda-data.eu
3. SPARQL_EXT_URI - used in ELDA, is the way to access the SPARQL Virtuoso url both from the browser and the container.
4. SCOREBOARD_URL - used in CONTENT REGISTRY application, must be the one that is accessed from the browser - example:
 http://digital-agenda-data.eu, or  http://test.digital-agenda-data.eu or  https://test.digital-agenda-data.eu:81

 
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
    image: digitalagendadata/scoreboard.plone:1.0
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
    image: digitalagendadata/scoreboard.plone.staging
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

### Start stack

#### PRODUCTION - multiple plone servers
    docker-compose up -d --scale plone=2

#### DEV, TEST - one plone server  
    docker-compose up -d

### Import data

#### Import plone data

1. Stop zeo server

    docker-compose stop zeoserver
    
2. Identify zeo docker name - <ZEO_DOCKER_NAME>:
      docker-compose ps  | grep zeo

3. Copy blobstorage and filestorage directories from the source plone site and put it into the current directory

4. Copy blobstorage and filestorage directories  to the zeoserver data volume:
    docker cp blobstorage <ZEO_DOCKER_NAME>:/data/
    docker cp filestorage <ZEO_DOCKER_NAME>:/data/
5. Start server
    docker-compose start zeoserver
6. Run chown on the /data directory from the server to make sure all the files have the correct permissions
    docker-compose exec zeoserver sh -c "chown -R 500:500 /data"
7. Restart zeoserver 
    docker-compose restart zeoserver
8. Check zeoserver logs for errors
    docker-compose logs -f zeoserver
9. Restart plone 
    docker-compose restart plone
8. Check zeoserver logs for errors
    docker-compose logs -f plone    
    

#### Import virtuoso db data

1. Stop virtuoso server

    docker-compose stop virtuoso
    
2. Identify zeo docker name - <VIRTUOSO_DOCKER_NAME> ( check first column on the following command) :
      docker-compose ps  | grep virtuoso

3. Copy database backup from source database and name it virtuoso.db

4. Identify volume location on the host - <VIRTUOSO_VOLUME_PATH>

    docker inspect <VIRTUOSO_DOCKER_NAME> | grep volume

<VIRTUOSO_VOLUME_PATH> should be similar to /var/lib/docker/volumes/<STACKNAME>_virtuoso_db/_data
  
5. Clean-up the volume:
   sudo rm -rf <VIRTUOSO_VOLUME_PATH>/* 
   
6. Copy the database:
   sudo cp virtuoso.db <VIRTUOSO_VOLUME_PATH>/

5. Start server
    docker-compose start virtuoso

6. Check virtuoso logs for errors
    docker-compose logs -f zeoserver



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
     $ cd init_scripts
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

### Testing

1. Plone - <SCOREBOARD_URL>
2. Elda - http://semantic.<SCOREBOARDBASE_URL>/dataset
3. Content Registry - <SCOREBOARD_URL>/data/
4. Download - <SCOREBOARD_URL>/datasets/desi#download
5. Sparql - <SCOREBOARD_URL>/sparql
6. Piwik - <SCOREBOARD_URL>/analytics/piwik/index.php





### Tips

#### Plone CSS
If CSS does not look right on the Plone site:
<SCOREBOARD_URL>/portal_css/manage_cssForm - Uncheck reset.css and click SAVE

