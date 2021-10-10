echo "Setting up vault in DEV MODE"
export VAULT_ADDR=http://127.0.0.1:8200

until curl -I -s -f -o /dev/null "http://localhost:8200/ui/"
do
  echo "Waiting for vault..."
  sleep 1
done

# login
echo "root" | vault login - 

# Enable kv2 
vault secrets enable -version=2 kv || true

# enable approles
vault auth enable approle || true

echo 'path "secret/*" {  capabilities = ["read"]}' | vault policy write renovate-policy - || true

# create a new role: renovate-role
vault write auth/approle/role/renovate-role policies=renovate-policy token_max_ttl=30m || true

# get the credentials
role_id=$(vault read auth/approle/role/renovate-role/role-id -format=json | jq -r '.data.role_id')
secret_id=$(vault write -f auth/approle/role/renovate-role/secret-id -format=json | jq -r '.data.secret_id')

echo "--------"
echo "export VAULT_ROLE_ID=${role_id}"
echo "export VAULT_SECRET_ID=${secret_id}"
echo "export TEST_SECRET=vault:secret/data/redis#password"
echo "--------"

# store them in kubernetes
kubectl delete secret renovate-vault
kubectl create secret generic renovate-vault \
  --from-literal=role_id="${role_id}" \
  --from-literal=secret_id="${secret_id}"

# REDIS SECRET
vault kv put secret/redis password=myredispassword2 -cas=0 || true

# MINIO SECRET
vault kv put secret/minio access_key=myaccesskey secret_key=mysecretkey -cas=0 || true

