#!/bin/bash
set -euo pipefail

echo "🔴 Stopping any running Langfuse stack..."
docker compose down

echo "🧹 Cleaning up old ClickHouse volumes (if any)..."
docker volume rm langfuse_ch_data langfuse_ch_logs 2>/dev/null || true

echo "🚀 Starting ZooKeeper..."
docker compose up -d zookeeper
sleep 5
docker compose logs --tail=10 zookeeper

echo "🚀 Starting ClickHouse..."
docker compose up -d clickhouse
sleep 5
curl -s http://127.0.0.1:8124/ping || { echo "❌ ClickHouse not ready"; exit 1; }

echo "📊 Verifying ClickHouse cluster config..."
docker compose exec clickhouse clickhouse-client -q \
  "SELECT cluster, shard_num, replica_num, host_address FROM system.clusters" || true

echo "🚀 Starting the rest of the stack..."
docker compose up -d

echo "✅ Langfuse should now be available at http://localhost:3001"