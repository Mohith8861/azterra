#!/bin/bash

# === Phase 1: Generate SSH Key ===
echo "[*] Generating SSH key pair..."
ssh-keygen -t rsa -b 4096 -f Dev-VM_key -N ""

# === Phase 2: Terraform Init and Apply ===
echo "[*] Initializing and applying Terraform..."
export TF_VAR_public_key_path=$(pwd)/Dev-VM_key.pub
cd terra
# terraform init
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

echo "Applying deployment to Kubernetes"
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \chmod +x kubectl && \sudo mv kubectl /usr/local/bin/ && \kubectl version --client
az aks get-credentials --resource-group DevEnvironment-RG --name Dev-AKS --overwrite-existing
kubectl apply -f deployment.yaml

# echo "Cluster Health Check"
# apt update && \ apt install -y wget apt-transport-https software-properties-common && \wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb && \sudo dpkg -i packages-microsoft-prod.deb && \sudo apt update && \sudo apt install -y powershell
# pwsh ./health-check.ps1
