#!/bin/bash

# === Phase 1: Generate SSH Key ===
echo "[*] Generating SSH key pair..."
ssh-keygen -t rsa -b 4096 -f Dev-VM_key -N ""

# Create the service principal with Contributor role
SP_NAME="DevVM-SP"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SP_OUTPUT_FILE="sp_credentials.json"

az ad sp create-for-rbac \
  --name $SP_NAME \
  --role contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --sdk-auth > $SP_OUTPUT_FILE

echo "✅ Service Principal created and saved to $SP_OUTPUT_FILE"

# === Phase 2: Terraform Init and Apply ===
echo "[*] Initializing and applying Terraform..."
export TF_VAR_public_key_path=$(pwd)/Dev-VM_key.pub
cd terra
terraform init
terraform apply -auto-approve

# === Phase 3: Extract IP and Setup Inventory ===
echo "[*] Extracting public IP..."
VM_IP=$(terraform output -raw public_ip)
cd ..

echo "[*] Creating Ansible inventory..."
cat <<EOF > inventory
[azurevm]
$VM_IP ansible_user=azureuser ansible_ssh_private_key_file=./Dev-VM_key ansible_python_interpreter=/usr/bin/python3
EOF

echo "[*] Waiting 20 seconds for VM to be ready..."
sleep 20

echo "[*] Testing SSH access..."
ssh -i Dev-VM_key -o StrictHostKeyChecking=no azureuser@$VM_IP "echo 'SSH successful!'"

# === Phase 4: Run Ansible Playbook ===
echo "[*] Running Ansible Playbook..."
ansible-playbook -i inventory main.yaml
