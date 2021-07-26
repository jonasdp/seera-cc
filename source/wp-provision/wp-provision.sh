#!/bin/bash
sudo apt update -y
sleep 10
sudo apt install wordpress php libapache2-mod-php php-mysql -y
sleep 10
#sudo cp /tmp/wp-config.php /etc/wordpress/config-localhost.php
#sudo cp /tmp/apache.conf /etc/apache2/sites-available/wordpress.conf

# Move to remote-exe
sudo a2ensite wordpress
sudo a2enmod rewrite
sudo service apache2 reload