#!/bin/bash

GIT_REPO=https://github.com/lianAshkenazi/project_docker.git
GIT_BRANCH=backup
CLONE_DIR=project_docker

MYSQL_CONTAINER=my-mysql
JOOMLA_CONTAINER=my-joomla
MYSQL_ROOT_PASSWORD=my-secret-pw
MYSQL_DATABASE=joomla_db
JOOMLA_PORT=8080
MYSQL_PORT=3306
JOOMLA_FILES_DIR=./joomla_files
NETWORK_NAME=my-network

echo '📥 Cloning backup repository...'
rm -rf "$CLONE_DIR"
git clone --branch "$GIT_BRANCH" "$GIT_REPO" "$CLONE_DIR"

SQL_FILE=$(find "$CLONE_DIR/backup/" -name '*.sql' | head -n 1)
TAR_FILE=$(find "$CLONE_DIR/backup/" -name '*.tar.gz' | head -n 1)

if [[ ! -f "$SQL_FILE" ]] || [[ ! -f "$TAR_FILE" ]]; then
  echo "❌ Backup files missing in repository. Exiting."
  exit 1
fi

echo '🛑 Stopping existing containers (if running)...'
docker stop "$JOOMLA_CONTAINER" "$MYSQL_CONTAINER" || true
docker rm "$JOOMLA_CONTAINER" "$MYSQL_CONTAINER" || true

echo '🧹 Cleaning up previous Joomla files...'
rm -rf "$JOOMLA_FILES_DIR"
mkdir -p "$JOOMLA_FILES_DIR"

echo '📦 Extracting Joomla site files...'
tar -xzf "$TAR_FILE" -C "$JOOMLA_FILES_DIR" --strip-components=2

if ! docker network ls | grep -q "$NETWORK_NAME"; then
  docker network create "$NETWORK_NAME"
  echo "✅ Docker network $NETWORK_NAME created."
else
  echo "✅ Docker network $NETWORK_NAME already exists."
fi

echo '🚀 Starting MySQL container...'
docker run -d --name "$MYSQL_CONTAINER" --network "$NETWORK_NAME" \
  -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
  -e MYSQL_DATABASE="$MYSQL_DATABASE" \
  -p "$MYSQL_PORT":3306 \
  mysql:latest

echo '⏳ Waiting for MySQL to initialize...'
sleep 20

echo '💾 Restoring database...'
export MYSQL_PWD="$MYSQL_ROOT_PASSWORD"
cat "$SQL_FILE" | docker exec -i "$MYSQL_CONTAINER" mysql -uroot --password="$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"

echo '🚀 Starting Joomla container...'
docker run -d --name "$JOOMLA_CONTAINER" --network "$NETWORK_NAME" \
  -e JOOMLA_DB_HOST="$MYSQL_CONTAINER" \
  -e JOOMLA_DB_USER=root \
  -e JOOMLA_DB_PASSWORD="$MYSQL_ROOT_PASSWORD" \
  -e JOOMLA_DB_NAME="$MYSQL_DATABASE" \
  -p "$JOOMLA_PORT":80 \
  -v "$(pwd)/$JOOMLA_FILES_DIR":/var/www/html \
  joomla

IP=$(hostname -I | awk '{print $1}')

echo ''
echo '✅ Restore complete!'
echo "🌍 Visit your Joomla site at: http://$IP:$JOOMLA_PORT"

