#! /bin/bash

# If file exists, set fileValue to contents. Otherwise set fileValue to default value.
# Usage: get_file_value FILE DEFAULT_VALUE
fileValue=""
get_file_value() {
    local file="$1"    

    fileValue="$2"

    if [ -e "${file}" ]
    then
	fileValue=$(cat "${file}")
    fi
}

# Grab configuration values possibly stored in files

get_file_value ${MYSQL_DATABASE_FILE} ${MYSQL_DATABASE}
DB_NAME=${fileValue}

get_file_value ${MYSQL_USER_FILE} ${MYSQL_USER}
DB_USER=${fileValue}

get_file_value ${MYSQL_PASSWORD_FILE} ${MYSQL_PASSWORD}
DB_PASS=${fileValue}

get_file_value ${MYSQL_ROOT_PASSWORD_FILE} ${MYSQL_ROOT_PASSWORD}
DB_ROOT_PASS=${fileValue}

# Lutece war must be modified before being deployed with secret config values.
# Only modify and deploy war if needed.

sourcewar=/lutece.war
deploywar=/webapps/lutece.war
extractdir=/lutece
dbconfigfile=${extractdir}/WEB-INF/conf/db.properties

if [ ! -f ${deploywar} ] || [ ${sourcewar} -nt ${deploywar} ]
then
    rm -f ${deploywar}

    unzip -q ${sourcewar} -d ${extractdir}

    # Set LANG to work around rpl bug
    LANG=en_US.UTF-8 rpl -q "#DB_NAME#" "${DB_NAME}" ${dbconfigfile}
    LANG=en_US.UTF-8 rpl -q "#DB_USER#" "${DB_USER}" ${dbconfigfile}
    LANG=en_US.UTF-8 rpl -q "#DB_PASS#" "${DB_PASS}" ${dbconfigfile}
    LANG=en_US.UTF-8 rpl -q "#DB_HOST#" "${DB_HOST}" ${dbconfigfile}    

    cd ${extractdir} && jar cf ${deploywar} *
fi

# Wait for mysql

echo "Waiting for mysql server"

while ! mysqladmin ping -h${DB_HOST} --silent; do
    sleep 1
done

echo "Found mysql server"

# If needed, init mysql db

TABLE="core_datastore"

echo "Checking if table <$TABLE> exists ..."

mysql -u ${DB_USER} -p${DB_PASS} -h ${DB_HOST} -e "desc $TABLE" ${DB_NAME} > /dev/null 2>&1

if [ $? -eq 0 ]
then
    echo "Database already initialized"
else
    echo "Initializing database..."

    rm -rf ${extractdir}
    unzip -q ${deploywar} -d ${extractdir}
 
    cd ${extractdir}/WEB-INF/sql && ant
fi
