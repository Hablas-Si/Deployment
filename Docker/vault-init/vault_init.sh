export VAULT_ADDR="http://localhost:8200"
export VAULT_TOKEN="00000000-0000-0000-0000-000000000000"

# give some time for Vault to start and be ready
sleep 10

vault kv put -mount secret hemmeligheder Secret=7Y6v8P0QrcdPlrV9UfY6+bMTjx5u8zPC Issuer=MinAuthService ConnectionAuctionDB=mongodb+srv://admin:admin@auctionhouse.dfo2bcd.mongodb.net/ RedisPW=0rIwX58ixdvj6btmfJrxvsxaMn3s4uta redisConnect=redis-16675.c56.east-us.azure.redns.redis-cloud.com:16675

# Loop forever to prevent container from terminatingg

while :
do
	sleep 3600
done
