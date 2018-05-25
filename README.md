# scoreboard.docker
Scoreboard docker setup

## Scoreboard stack deploy steps - all environments

### Clone repository locally:

    git clone git@github.com:digital-agenda-data/scoreboard.docker.git
    
 If it's already saved, make sure it's on the latest version

    cd scoreboard.docker
    git pull
 
### Edit .env file 

#### URLs
1. DEPLOY_TYPE - can be TEST, PROD - will be used in NGINX, SOLR and CRONTAB configuration
1. SCOREBOARDBASE_URL - the main url under which the site will be used:
    * FOR PRODUCTION must be digital-agenda-data.eu
    * For TEST must be test.digital-agenda-data.eu
2. SCOREBOARD_URL - used in CONTENT REGISTRY application, must be the one that is accessed from the browser - example:
 http://$SCOREBOARDBASE_URL, or  http://$SCOREBOARDBASE_URL:8080 or  https://$SCOREBOARDBASE_URL
3. SPARQL_EXT_URI - used in ELDA, is the way to access the SPARQL Virtuoso url both from the browser and the container. In case of Development environment $SCOREBOARDBASE_URL:81 
 
#### VIRTUOSO DB PASSWORDS 
If you are restoring the database from another environment, please copy here the same passwords that are saved in the database:

3. VIRTUOSO_DBA_PASSWORD - dba user password
4. CR_DB_PASSWORD - cr3user password
5. CR_DB_RO_PASSWORD - cr3rouser password


#### MARIADB PASSWORDS 

6. MARIADB_PASSWORD - Mariadb root password 
7. MARIADB_PIWIK_PASSWORD - Mariadb piwik user password - save it for the PIWIK configuration

#### Other variables
8. TZ - default Timezone for all containers - Europe/Copenhagen


### docker-compose.yml file

You need to set the NGINX port to an available value in the docker-compose file. It is in the nginx->ports and has the format:
`- <HOST_PORT>:<CONTAINER_PORT>`

For example, if port 80 is not available, but 81 is we modify this:

```
  nginx:
    image: nginx:1.13
    depends_on:
    - haproxy
    - piwik
    - solr
    restart: always
    ports:
    - 80:80
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
    - 81:80
```

    links:
    - nginx:${SCOREBOARDBASE_URL}






### Prepare configuration files:

#### NGNIX configuration

You need to make sure that the url you saved in the .env file - 

#### Only for dev:

ports


### Start stack

docker-compose up -d --scale plone=2

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


### Test





### Tips
If CSS does not look good on the Plone:
http://test.digital-agenda-data.eu/portal_css/manage_cssForm - Uncheck reset.css and click SAVE
