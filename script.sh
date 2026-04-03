#!/bin/bash
set -euo pipefail

DIR="/opt/backup"
NTW="shvirtd-example-python_backend"
ENV_FILE="/opt/shvirtd-example-python/.env"
DB_HOST="shvirtd-example-python-db-1"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
FILE_NAME="dumps_${TIMESTAMP}.sql"

set -a
source "$ENV_FILE"
set +a

docker exec -i "$DB_HOST" mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "
ALTER USER '$MYSQL_USER'@'%' IDENTIFIED WITH mysql_native_password BY '$MYSQL_PASSWORD';
FLUSH PRIVILEGES;"

docker run --rm --entrypoint "" \
  -v "$DIR:/backup" \
  --network "$NTW" \
  schnitzler/mysqldump \
  mysqldump  --opt --no-tablespaces -h "$DB_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" "--result-file=/backup/$FILE_NAME" "$MYSQL_DATABASE"
