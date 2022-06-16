
sudo apt update
sudo apt install apache2 \
                 ghostscript \
                 libapache2-mod-php \
                 mariadb-server \
                 php \
                 php-bcmath \
                 php-curl \
                 php-imagick \
                 php-intl \
                 php-json \
                 php-mbstring \
                 php-mysql \
                 php-xml \
                 php-zip
#connect as a root usual

sudo su

#Connexion sur MariaDb

mysql -h mydemoserver.mariadb.database.azure.com -u myadmin@mydemoserver -p


#Création d’une nouvelle base de données

CREATE DATABASE wordpressdb;

#Création d’un nouvel utilisateur MariaDB et attribution des droits sur la nouvelle base de données

GRANT ALL ON wordpressdb.* TO 'wordpress_user'@'localhost' IDENTIFIED BY 'password';

#Appliquer les privilèges 

FLUSH PRIVILEGES;

#Quitter MariaDB

EXIT;

#Se diriger dans le répertoire /var/www/html

cd /var/www/html/

#Installer WordPress sur Debian 11 :
#Télécharger WordPress

curl -O https://wordpress.org/latest.tar.gz


#Décompression de l’archive de WordPress

tar -xvf latest.tar.gz

#Suppression de l’archive

rm latest.tar.gz

#Attribution des droit au serveur Web

chown -R www-data:www-data /var/www/html/wordpress

#Rendez-vous dans le dossier wordpress

cd wordpress

#Copie du fichier de configuration 

cp wp-config-sample.php wp-config.php

#Edition du fichier de configuration

nano wp-config.php

#// ** MySQL settings - You can get this info from your web host ** //
#/** The name of the database for WordPress */ 
#define( 'DB_NAME', 'wordpressdb' );
#/* MySQL database username */ 
#define( 'DB_USER', 'wpuser1' );
#/* MySQL database password */
#define( 'DB_PASSWORD', 'YOUR PASSWORD' );
#/* MySQL hostname, change the IP here if external DB set up */ 
#define( 'DB_HOST', 'localhost' );
#/* Database Charset to use in creating database tables. */
#define( 'DB_CHARSET', 'utf8' );
#/* The Database Collate type. Don't change this if in doubt. */
#define( 'DB_COLLATE', '' );

#Suppression du fichier readme.html

rm /var/www/html/wordpress/readme.html

#Depuis votre navigateur vous devriez accéder à la configuration de WordPress

http://votreip/wordpress