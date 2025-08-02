#!/bin/bash

# Config
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="backup"
SQL_FILE="$BACKUP_DIR/joomla_db_$TIMESTAMP.sql"
FILES_BACKUP="$BACKUP_DIR/joomla_files_$TIMESTAMP.tar.gz"
MYSQL_CONTAINER="my-mysql"
JOOMLA_CONTAINER="my-joomla"
MYSQL_ROOT_PASSWORD="my-secret-pw"
MYSQL_DATABASE="joomla_db"

# Create backup directory if not exists
mkdir -p $BACKUP_DIR

echo "📦 Backing up Joomla + MySQL..."

# Step 1: Backup MySQL database
echo "🗄️  Dumping MySQL database..."
docker exec $MYSQL_CONTAINER \
  mysqldump -uroot -p$MYSQL_ROOT_PASSWORD $MYSQL_DATABASE > $SQL_FILE

if [ $? -eq 0 ]; then
  echo "✅ MySQL database saved to $SQL_FILE"
else
  echo "❌ MySQL backup failed!"
  exit 1
fi

# Step 2: Backup Joomla site files (from container path /var/www/html)
echo "🗃️  Backing up Joomla site files from container..."
docker exec $JOOMLA_CONTAINER tar czf - /var/www/html > $FILES_BACKUP

if [ $? -eq 0 ]; then
  echo "✅ Joomla files saved to $FILES_BACKUP"
else
  echo "❌ Joomla files backup failed!"
  exit 1
fi

# Final message
echo "🎉 Backup completed at $TIMESTAMP"
