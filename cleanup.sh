#!/bin/bash

# Project-specific names
JOOMLA_CONTAINER="my-joomla"
MYSQL_CONTAINER="my-mysql"
NETWORK_NAME="my-network"
BACKUP_DIR="backup"

echo "⚠️ WARNING: This will delete all containers, network, and optionally backups."
read -p "Are you sure you want to continue? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
  echo "❌ Cleanup canceled."
  exit 1
fi

echo "🗑️ Stopping and removing containers..."
docker rm -f $JOOMLA_CONTAINER $MYSQL_CONTAINER 2>/dev/null

echo "🔌 Removing Docker network..."
docker network rm $NETWORK_NAME 2>/dev/null

# Optional: remove backup files
read -p "Do you also want to delete the backup files in '$BACKUP_DIR'? (y/n): " DELETE_BACKUPS
if [[ "$DELETE_BACKUPS" == "y" ]]; then
  rm -rf $BACKUP_DIR
  echo "🧹 Deleted backup folder: $BACKUP_DIR"
fi

# Optional: remove associated images
read -p "Delete Joomla and MySQL images too? (y/n): " DELETE_IMAGES
if [[ "$DELETE_IMAGES" == "y" ]]; then
  docker rmi joomla mysql 2>/dev/null
  echo "🖼️  Deleted Joomla and MySQL images"
fi

echo "✅ Cleanup complete."
