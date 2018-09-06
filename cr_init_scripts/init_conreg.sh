#!/bin/bash


source ../.env

echo "Starting the initialisation of Content Registry"


wget https://raw.githubusercontent.com/digital-agenda-data/scoreboard.contreg/master/sql/virtuoso-preparation-before-schema-created.sql 
wget https://raw.githubusercontent.com/digital-agenda-data/scoreboard.contreg/master/sql/initial-data-after-schema-created.sql

sed -i "s/'xxx',/'$CR_DB_PASSWORD',/g" virtuoso-preparation-before-schema-created.sql

sed -i "s/'yyy',/'$CR_DB_RO_PASSWORD',/g" virtuoso-preparation-before-schema-created.sql


mv virtuoso-preparation-before-schema-created.sql ../virtuoso-scripts/

mv initial-data-after-schema-created.sql ../virtuoso-scripts/

cd ..

docker-compose exec virtuoso sh -c "/opt/virtuoso-opensource/bin/isql 1111 dba dba /virtuoso-scripts/virtuoso-preparation-before-schema-created.sql"

docker-compose exec cr sh -c "cd /var/local/cr/build; mvn liquibase:update"

docker-compose exec cr sh -c "rm -rf /usr/local/tomcat/webapps/data; cp -pr /var/local/cr/build/target/cr-das /usr/local/tomcat/webapps/data" 

docker-compose exec virtuoso sh -c "/opt/virtuoso-opensource/bin/isql 1111 dba dba /virtuoso-scripts/initial-data-after-schema-created.sql"

docker-compose restart cr



