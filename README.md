# scoreboard.docker
Scoreboard docker setup

## Scoreboard stack deploy steps - all environments

Because of the differences between the staging, production and development environments, you need to update the following files with the correct values:

### .env file 

If you are restoring the database, please make sure you set the same passwords 

1. SCOREBOARD_URL - the url will be used in the Content Registry app, 
2. ELDA_BASE_URL=test.digital-agenda-data.eu
3. CR_DB_PASSWORD=xxx
4. CR_DB_RO_PASSWORD=yyy
MARIADB_PASSWORD=piwikroot
MARIADB_PIWIK_PASSWORD=piwiktest
TZ=Europe/Copenhagen
SOLR_SCOREBOARD_LOCATION=/core-template/scoreboardtest
VIRTUOSO_DBA_PASSWORD=dba

### Docker compose file

Set NGINX port in the docker-compose file




1. 
If CSS does not look good on the Plone:
http://test.digital-agenda-data.eu/portal_css/manage_cssForm - Uncheck reset.css and click SAVE
