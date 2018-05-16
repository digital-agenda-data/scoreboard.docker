#!/bin/bash


source ../.env

echo "Starting the initialisation of Content Registry"


git clone https://github.com/digital-agenda-data/scoreboard.contreg.git
sed -i "s/'xxx',/'$CR_DB_PASSWORD',/g" scoreboard.contreg/sql/virtuoso-preparation-before-schema-created.sql

sed -i "s/'yyy',/'$CR_DB_RO_PASSWORD',/g" scoreboard.contreg/sql/virtuoso-preparation-before-schema-created.sql


mv scoreboard.contreg/sql/virtuoso-preparation-before-schema-created.sql ../virtuoso/

mv scoreboard.contreg/sql/initial-data-after-schema-created.sql ../virtuoso/


docker-compose exec virtuoso  sh -c "/opt/virtuoso-opensource/bin/isql 1111 dba dba /opt/virtuoso-opensource/database/virtuoso-preparation-before-schema-created.sql"

docker-compose exec  content_registry sh -c "cd /var/local/cr/build; mvn liquibase:update"


docker-compose exec virtuoso sh -c "/opt/virtuoso-opensource/bin/isql 1111 dba dba /opt/virtuoso-opensource/database/initial-data-after-schema-created.sql"

rm -rf scoreboard.contreg




docker-compose restart content_registry



