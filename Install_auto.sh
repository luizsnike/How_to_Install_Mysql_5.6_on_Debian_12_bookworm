#!/bin/bash
if [ $UID -ne 0 ]; then
    echo "Run as root"
    exit 1
fi
DB_ROOT_PASSWD='pswd'
DB_BASE_FOLDER='/dados/mysql'
MYSQL_FILE='mysql-5.6.23-linux-glibc2.5-x86_64.tar.gz'
apt update
apt install libaio1 libncursesw5 libncurses5 wget -y
cd /usr/local
if [ -e "$MYSQL_FILE" ] ; then
        mv $MYSQL_FILE mysql.tar.gz
else
        wget "https://downloads.mysql.com/archives/get/p/23/file/$MYSQL_FILE"
        mv $MYSQL_FILE mysql.tar.gz
fi
groupadd mysql
useradd -g mysql mysql
tar -xvf mysql.tar.gz
rm mysql.tar.gz
mv mysql-* mysql
chown root:root mysql
cd mysql
chown -R mysql:mysql *
mkdir -p "$DB_BASE_FOLDER/log/"
cp -R data/ "$DB_BASE_FOLDER/data/"
chown -R mysql:mysql $DB_BASE_FOLDER/
sed -i 's,basedir=foo,basedir=/usr/local/mysql,g' /usr/local/mysql/scripts/mysql_install_db
sed -i "s,datadir=bar,datadir=$DB_BASE_FOLDER/data/,g" /usr/local/mysql/scripts/mysql_install_db
scripts/mysql_install_db --user=mysql --datadir=$DB_BASE_FOLDER/data/
chown -R root .
chown -R mysql:mysql $DB_BASE_FOLDER/
cp support-files/my-default.cnf /etc/my.cnf
sed -i 's,# basedir = .....,basedir=/usr/local/mysql,g' /etc/my.cnf
sed -i "s,# datadir = .....,datadir=$DB_BASE_FOLDER/data/,g" /etc/my.cnf
sed -i 's,# port = .....,port=3306,g' /etc/my.cnf
sed -i 's,# socket = .....,socket=/tmp/mysql.sock,g' /etc/my.cnf
echo 'pid-file=/tmp/mysqld.pid' >> /etc/my.cnf
echo "log-error=$DB_BASE_FOLDER/log/log-error.log" >> /etc/my.cnf
bin/mysqld_safe --user=mysql & cp support-files/mysql.server /etc/init.d/mysql.server
sleep 5
/etc/init.d/mysql.server start
sleep 5
bin/mysqladmin -u root password "$DB_ROOT_PASSWD"
sleep 5
/etc/init.d/mysql.server stop
sleep 5
update-rc.d -f mysql.server defaults
ln -s /usr/local/mysql/bin/mysql /usr/local/bin/mysql
ln -s /usr/local/mysql/bin/mysqldump /usr/local/bin/mysqldump
sleep 5
/etc/init.d/mysql.server start
sleep 5
/etc/init.d/mysql.server status
echo "Process finished, you now have mysql with the basic configurations installed. Enjoy."