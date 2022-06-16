#!/bin/bash

sudo su

cd /var/www/html/

curl -O https://wordpress.org/latest.tar.gz

tar -xvf latest.tar.gz

rm latest.tar.gz

chown -R www-data:www-data /var/www/html/wordpress

cd wordpress

cp wp-config-sample.php wp-config.php

nano wp-config.php