#!/bin/bash


source ../.env

echo "Starting the initialisation of Content Registry"


wget https://raw.githubusercontent.com/digital-agenda-data/scoreboard.contreg/master/sql/initial-data-after-schema-created.sql

mv initial-data-after-schema-created.sql ../virtuoso/

cd ..

docker-compose exec  content_registry sh -c "cd /var/local/cr/build; mvn liquibase:update"

docker-compose exec  content_registry sh -c "rm -rf /usr/local/tomcat/webapps/data; cp -pr /var/local/cr/build/target/cr-das /usr/local/tomcat/webapps/data"

docker-compose exec virtuoso sh -c "/opt/virtuoso-opensource/bin/isql 1111 dba dba /opt/virtuoso-opensource/database/initial-data-after-schema-created.sql"


docker-compose restart content_registry



