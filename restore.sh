#!/bin/bash

# === CONFIGURATION ===
GIT_REPO="https://github.com/your-username/joomla-backup.git"
CLONE_DIR="joomla-restore"
MYSQL_CONTAINER="my-mysql"
JOOMLA_CONTAINER="my-joomla"
MYSQL_ROOT_PASSWORD="my-secret-pw"
MYSQL_DATABASE="joomla_db"
JOOMLA_VOLUME="joomla_data"
JOOMLA_PORT="8080"

echo "📥 Cloning backup repository..."
rm -rf $CLONE_DIR
git clone $GIT_REPO $CLONE_DIR || { echo "❌ Failed to clone repository"; exit 1; }

# Find backup files
SQL_FILE=$(find $CLONE_DIR -name "*.sql" | head -n 1)
TAR_FILE=$(find $CLONE_DIR -name "*.tar.gz" | head -n 1)

if [[ ! -f "$SQL_FILE" || ! -f "$TAR_FILE" ]]; then
  echo "❌ Backup files not found in repo!"
  exit 1
fi

echo "🛑 Stopping Joomla and MySQL containers..."
docker stop $JOOMLA_CONTAINER $MYSQL_CONTAINER

echo "🗄️ Removing Joomla and MySQL containers..."
docker rm $JOOMLA_CONTAINER $MYSQL_CONTAINER

echo "🗃️ Restoring Joomla files into Docker volume..."
# Make sure the volume exists
docker volume create $JOOMLA_VOLUME

# Extract Joomla files into volume
docker run --rm \
  -v $JOOMLA_VOLUME:/var/www/html \
  -v "$(pwd)/$CLONE_DIR":/backup \
  alpine sh -c "apk add --no-cache tar && tar -xzf /backup/$(basename $TAR_FILE) -C /var/www/html --strip-components=2"

echo "🚀 Starting MySQL container..."
docker run -d \
  --name $MYSQL_CONTAINER \
  --network my-network \
  -e MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
  -e MYSQL_DATABASE=$MYSQL_DATABASE \
  -p 3306:3306 \
  mysql:latest

echo "⏳ Waiting for MySQL to initialize..."
sleep 20

echo "💾 Restoring database backup..."
export MYSQL_PWD=$MYSQL_ROOT_PASSWORD
cat $SQL_FILE | docker exec -i $MYSQL_CONTAINER mysql -uroot $MYSQL_DATABASE

echo "🚀 Starting Joomla container..."
docker run -d \
  --name $JOOMLA_CONTAINER \
  --network my-network \
  -e JOOMLA_DB_HOST=$MYSQL_CONTAINER \
  -e JOOMLA_DB_USER=root \
  -e JOOMLA_DB_PASSWORD=$MYSQL_ROOT_PASSWORD \
  -e JOOMLA_DB_NAME=$MYSQL_DATABASE \
  -p $JOOMLA_PORT:80 \
  -v $JOOMLA_VOLUME:/var/www/html \
  joomla

IP=$(hostname -I | awk '{print $1}')
echo ""
echo "✅ Restore complete!"
echo "🌍 Visit your Joomla site at: http://$IP:$JOOMLA_PORT"
