#!/bin/bash
set -euo pipefail

# Config
NETWORK_NAME="my-network"
MYSQL_CONTAINER="my-mysql"
JOOMLA_CONTAINER="my-joomla"
MYSQL_ROOT_PASSWORD="my-secret-pw"
MYSQL_DATABASE="joomla_db"
MYSQL_PORT="3306"
JOOMLA_PORT="8080"

echo "🚀 Starting fresh Joomla + MySQL Docker environment..."

# Step 1: Create Docker network (if not exists)
if ! docker network ls | grep -q "$NETWORK_NAME"; then
  echo "🔧 Creating Docker network: $NETWORK_NAME"
  docker network create "$NETWORK_NAME"
else
  echo "✅ Docker network $NETWORK_NAME already exists."
fi

# Step 2: Remove any existing containers (optional but safe)
for container in "$MYSQL_CONTAINER" "$JOOMLA_CONTAINER"; do
  if docker ps -a --format '{{.Names}}' | grep -qw "$container"; then
    echo "🧹 Removing existing container: $container"
    docker rm -f "$container"
  fi
done

# Step 3: Start MySQL container
echo "📦 Creating MySQL container..."
docker run -d \
  --name "$MYSQL_CONTAINER" \
  --network "$NETWORK_NAME" \
  -e MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
  -e MYSQL_DATABASE="$MYSQL_DATABASE" \
  -p "$MYSQL_PORT":3306 \
  mysql:latest

# Wait for MySQL to initialize
echo "⏳ Waiting for MySQL to initialize (20s)..."
sleep 20

# Step 4: Start Joomla container
echo "🌐 Creating Joomla container..."
docker run -d \
  --name "$JOOMLA_CONTAINER" \
  --network "$NETWORK_NAME" \
  -e JOOMLA_DB_HOST="$MYSQL_CONTAINER" \
  -e JOOMLA_DB_USER="root" \
  -e JOOMLA_DB_PASSWORD="$MYSQL_ROOT_PASSWORD" \
  -e JOOMLA_DB_NAME="$MYSQL_DATABASE" \
  -p "$JOOMLA_PORT":80 \
  joomla:latest

# Step 5: Display access info
IP=$(hostname -I | awk '{print $1}')
echo ""
echo "✅ Joomla + MySQL setup is complete!"
echo "🌍 Access your Joomla site at: http://$IP:$JOOMLA_PORT"
echo "🛠️  You can now complete Joomla installation via the web interface."

