#!/bin/bash

apt-get install --yes --no-install-recommends -q lsb-release ca-certificates apt-transport-https
apt-get install --yes --no-install-recommends -q ssh locales vim screen rsync bzip2 unzip less curl git bc less sudo screen htop openssh-server gnupg wget patch

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen ; locale-gen --purge en_US.UTF-8 ; dpkg-reconfigure --frontend=noninteractive locales ; update-locale LANG=en_US.UTF-8
echo "content-disposition = on" >> /etc/wgetrc

apt-get update && apt-get --yes upgrade

apt-get install --yes --no-install-recommends -q apache2 imagemagick mcrypt sqlite3 mariadb-server
apt-get install --yes --no-install-recommends -q php php-apcu php-cgi php-curl php-gd php-intl php-mbstring php-mysql php-xml php-soap php-xml php-zip php-sqlite3 libapache2-mod-php

curl -sL https://deb.nodesource.com/setup_14.x | bash -
apt-get install --yes nodejs

curl --silent -o yarnpkg.gpg.pub https://dl.yarnpkg.com/debian/pubkey.gpg ; sudo apt-key --keyring /etc/apt/trusted.gpg.d/yarnpkg.gpg add yarnpkg.gpg.pub
echo "deb https://dl.yarnpkg.com/debian/ stable main" >> /etc/apt/sources.list.d/yarn.list
apt-get update
apt-get install --yes --no-install-recommends yarn

curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

echo "typo3 ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/typo3
chmod 600 /etc/sudoers.d/typo3

mkdir /var/www/typo3demo
chown typo3: /var/www/typo3demo

exit 0
