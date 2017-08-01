#!/bin/sh

filename=Hrms_production_`date +%Y%m%d`_dump.sql
#mongodump -d airline_hrms -o $filename
mysqldump -uroot --databases Hrms_production > $filename

tar zcvf $filename.tar.gz $filename
cp -rf $filename.tar.gz /var/www/backup/
rm -rf $filename.tar.gz

scp /var/www/backup/$filename.tar.gz avatar@114.215.142.122:/data_disk/db_sync/148/
scp /var/www/backup/$filename.tar.gz avatar@114.215.142.105:/data_disk/db_sync/148/

# 删除30天以前的备份
find /var/www/backup/ -mtime +30 -name "*.*" -exec rm -rf {} \;
