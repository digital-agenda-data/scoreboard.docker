all:

dirs:
	mkdir -p ./src

git:
	cd ./src \
	&& git clone git@github.com:digital-agenda-data/scoreboard.visualization.git \
	&& git clone git@github.com:digital-agenda-data/edw.datacube.git \
	&& git clone git@github.com:digital-agenda-data/scoreboard.theme.git

perms:
	sudo setfacl  -R -m u:500:rwX,g:500:rwX,u:${USER}:rwX src/
	sudo setfacl -dR -m u:500:rwX,g:500:rwX,u:${USER}:rwX src/


devel-setup: dirs git perms

devel-clean:
	rm -rf ./src/

devel-start:
	docker-compose -f docker-compose.yml -f docker-compose.devel.yml up -d

devel-build:
	docker-compose build

devel-stop:
	docker-compose stop
