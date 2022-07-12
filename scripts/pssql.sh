
#!/bin/bash

sudo tee /etc/yum.repos.d/pgdg.repo<<EOF
[pgdg13]
name=PostgreSQL 13 for RHEL/CentOS 7 - x86_64
baseurl=https://download.postgresql.org/pub/repos/yum/13/redhat/rhel-7-x86_64
enabled=1
gpgcheck=0
EOF

sudo yum update -y


sudo yum install postgresql13 postgresql13-server -y


sudo /usr/pgsql-13/bin/     initdb

sudo systemctl enable --now postgresql-13


