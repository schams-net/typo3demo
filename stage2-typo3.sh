#!/bin/bash

MYSQL_DATABASE="typo3demo"
MYSQL_USERNAME="typo3demo"
MYSQL_PASSWORD="123456"

curl -sL https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

sudo mysql -e "CREATE DATABASE ${MYSQL_DATABASE}"
sudo mysql -e "CREATE USER '${MYSQL_USERNAME}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}'"
sudo mysql -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USERNAME}'@'%'"
sudo mysql -e "FLUSH PRIVILEGES"

cd /var/www/typo3demo/
git clone https://gitlab.typo3.org/services/demo.typo3.org/site.git
cd site/
composer install

#composer require helhum/typo3-console

PASSWORD=$(php -r 'echo password_hash("password", PASSWORD_ARGON2I, ["memory_cost" => 128000, "time_cost" => 30, "threads" => 4]);' | sed 's/\$/\\$/g')
ENCRYPTION_KEY=$(openssl rand -hex 64)

cat <<EOF > .env
#TYPO3_CONTEXT="Development"
TYPO3_INSTALLER_PASSWORD="${PASSWORD}"
TYPO3_ENCRYPTION_KEY="${ENCRYPTION_KEY}"
TYPO3_DB_DATABASE="${MYSQL_DATABASE}"
TYPO3_DB_HOST="localhost"
TYPO3_DB_PASSWORD="${MYSQL_PASSWORD}"
TYPO3_DB_SOCKET=""
TYPO3_DB_USERNAME="${MYSQL_USERNAME}"
EOF

#touch web/typo3conf/ENABLE_INSTALL_TOOL

cd /var/www/

sudo rm -rf html
sudo ln -s typo3demo/site/web html
sudo systemctl restart apache2

cd /var/www/typo3demo/

sed -e 's/https/http/g;s/demo\.typo3\.org/localhost/' -i site/config/sites/main/config.yaml

#./site/bin/typo3cms install:setup
./site/bin/typo3cms database:updateschema *.add
./site/bin/typo3cms backend:createadmin admin password
./site/bin/typo3 extension:deactivate content_sync
./site/bin/typo3 extension:deactivate demologin

wget --quiet -O site.zip "https://gitlab.typo3.org/services/demo.typo3.org/site/-/package_files/5/download"
unzip -q site.zip
mv dump/fileadmin /var/www/typo3demo/site/web/

echo "["$(date +"%c")"] Importing database"
. /var/www/typo3demo/site/.env
zcat dump/dump.sql.gz | sed 's/https:\/\/demo\.typo3\.org\/typo3\//\/typo3/g' | mysql --user ${TYPO3_DB_USERNAME} -p${TYPO3_DB_PASSWORD} ${TYPO3_DB_DATABASE}

cat <<EOF | mysql --user ${TYPO3_DB_USERNAME} -p${TYPO3_DB_PASSWORD} ${TYPO3_DB_DATABASE}
TRUNCATE TABLE tx_scheduler_task;
EOF

cd /var/www/typo3demo/site/src/webpack/
nvm install v14.16.0
nvm use

yarn install
yarn build-prod

cd /var/www/typo3demo/site/web/
wget -O .htaccess https://git.typo3.org/Packages/TYPO3.CMS.git/blob_plain/HEAD:/typo3/sysext/install/Resources/Private/FolderStructureTemplateFiles/root-htaccess
