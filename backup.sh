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
GIT_REPO_DIR="."        # Local git repo directory (adjust if needed)
GIT_COMMIT_MSG="Backup on $TIMESTAMP"

# Ensure backup directory exists
mkdir -p $BACKUP_DIR

echo "📦 Backing up Joomla + MySQL..."

# Step 1: Backup MySQL database
echo "🗄️  Dumping MySQL database..."
export MYSQL_PWD=$MYSQL_ROOT_PASSWORD
docker exec $MYSQL_CONTAINER \
  mysqldump -uroot $MYSQL_DATABASE > $SQL_FILE

if [ $? -eq 0 ]; then
  echo "✅ MySQL database saved to $SQL_FILE"
else
  echo "❌ MySQL backup failed!"
  exit 1
fi

# Step 2: Backup Joomla site files
echo "🗃️  Backing up Joomla site files from container..."
docker exec $JOOMLA_CONTAINER tar czf - /var/www/html > $FILES_BACKUP

if [ $? -eq 0 ]; then
  echo "✅ Joomla files saved to $FILES_BACKUP"
else
  echo "❌ Joomla files backup failed!"
  exit 1
fi

# Step 3: Commit and push to Git
echo "🔧 Adding backup files to Git repository..."

cd $GIT_REPO_DIR || { echo "❌ Git repo directory not found!"; exit 1; }

git add $SQL_FILE $FILES_BACKUP

git commit -m "$GIT_COMMIT_MSG"

if git push; then
  echo "✅ Backup files pushed to Git successfully!"
else
  echo "❌ Failed to push backup files to Git."
  exit 1
fi

echo "🎉 Backup and push complete."
