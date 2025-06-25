echo "[*] Initializing and applying Terraform..."
export TF_VAR_public_key_path=$(pwd)/Dev-VM_key.pub
cd terra
terraform init
cd ..


# Create the service principal with Contributor role
SP_NAME="DevVM-SP"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SP_OUTPUT_FILE="sp_credentials.json"

az ad sp create-for-rbac \
  --name $SP_NAME \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --sdk-auth > $SP_OUTPUT_FILE

echo "✅ Service Principal created and saved to $SP_OUTPUT_FILE"clea