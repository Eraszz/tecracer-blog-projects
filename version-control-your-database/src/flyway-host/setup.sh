#!/usr/bin/env bash

yum update -y
wget -qO- https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/${flyway_version}/flyway-commandline-${flyway_version}-linux-x64.tar.gz | tar xvz && sudo ln -s `pwd`/flyway-${flyway_version}/flyway /usr/local/bin

cat >/flyway-${flyway_version}/conf/${flyway_conf} <<EOL
flyway.url=${flyway_url}
flyway.user=${flyway_db_user}
flyway.password=${flyway_db_pw}
flyway.baselineOnMigrate=true
EOL
