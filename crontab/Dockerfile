FROM python:3.6-stretch

RUN apt-get update \
 && apt-get install --no-install-recommends -y rsyslog cron curl virtuoso-opensource-6.1-bin \
 && apt-get clean \
 &&  pip install pysolr \
 && rm -rf /var/lib/apt/lists/* \
 && sed -i '/#cron./c\cron.*                          \/proc\/1\/fd\/1'  /etc/rsyslog.conf \
 && sed -i '/cron.*/a root.*                          \/proc\/1\/fd\/1' /etc/rsyslog.conf


COPY docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["cron", "-f"]

