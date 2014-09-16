#!/bin/bash
###
# Простая система бекапа баз данных MySQL
#
# Проходит по списку баз данных, бекапит их в соответствующие директории,
# проставляет права конечным файлам бекапа.
#
# Можно выполнять в кроне, например, так:
# ````
# # Сообщения об ошибках шлём на указанную почту 
# MAILTO="mail@example.com"
#
# # Выполняем каждый день в 5:30 от имени пользователя `root`, лог записываем в файл `/backup/mysql-backup.log`
# 30 5      * * *   root    /backup/mysql-backup.sh  >>  /backup/mysql-backup.log
# ````
#
# Параметры:
# @param  $baseDir      Базовый каталог, от которого считаются пути директорий
# @param  $mysqlConfig  Конфигурационный файл с данными подключения к MySQL
# @param  $owner        Владелец и группа, назначаемые файлу бекапа
#
# @author MaximAL
# @date 2014-09-16
# @copyright ©  MaximAL, Sijeko  2014
# @link http://maximals.ru/
# @link http://sijeko.ru/
# На основании конфигурации собственного скрипта от 2013-06-27.
###

####################
# Настройки

# Директория со всеми бекапами
baseDir='/backup/db'

# Откуда брать параметры для подключения к базам
mysqlConfig='/etc/mysql/debian.cnf'
# Файл формата как /etc/mysql/debian.cnf с одной секцией [client]
#     [client]
#     host     = localhost
#     user     = username
#     password = password
#     # socket = /var/run/mysqld/mysqld.sock

# Владелец и группа, назначаемые файлу бекапа
owner='maximal:maximal'


####################
# Поехали!

# Текущий день (используется в именах файлов бекапов)
date=`date +%F_%H`

echo "@`date +%FT%H:%M:%S%:z` — делаем бекапы баз данных…"

# Запрос получения имён баз данных для бекапа
query="SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME NOT IN ('information_schema', 'performance_schema', 'mysql')"

for dbname in `echo $query | mysql --defaults-file=$mysqlConfig --skip-column-names information_schema`; do
	# Имя каталога и файла
	dirname=`printf '%s/%s' $baseDir $dbname`
	filename=`printf '%s/%s_%s.sql.gz' $dirname $dbname $date`
	echo "    $dbname  →  $filename"

	# Создаём каталог, если его нет, и ставим ему права
	mkdir -p $dirname
	chown  $owner  $dirname
	chmod  750  $dirname

	# Делаем бекап и ставим файлу нужные права
	mysqldump  --defaults-extra-file=$mysqlConfig  $dbname  |  gzip > $filename
	chown  $owner  $filename
	chmod  640  $filename
done

echo "Готово."
