#!/bin/bash

# Display welcome message and wait for 4 seconds
echo "HEY I AM HALO"
sleep 4

# Ask for VANA Private Key and save it
read -p "Please enter your VANA Private Key: " VANA_PRIVATE_KEY

# Ask for VANA Network (moksha as default)
read -p "Which network do you want to use? (Press ENTER for moksha or type satori): " VANA_NETWORK

# If network is empty, set moksha as the default
if [[ -z "$VANA_NETWORK" ]]; then
    VANA_NETWORK="moksha"
fi

# Install Docker
sudo apt update -y && sudo apt upgrade -y
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update -y && sudo apt upgrade -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Create directories
mkdir -p sixgpt
cd sixgpt

# Create Docker Compose file
cat <<EOF > docker-compose.yml
version: '3.8'

services:
  ollama:
    image: ollama/ollama:0.3.12
    ports:
      - "11435:11434"
    volumes:
      - ollama:/root/.ollama
    restart: unless-stopped

  sixgpt3:
    image: sixgpt/miner:latest
    ports:
      - "3015:3000"
    depends_on:
      - ollama
    environment:
      - VANA_PRIVATE_KEY=\${VANA_PRIVATE_KEY}
      - VANA_NETWORK=\${VANA_NETWORK}
    restart: always

volumes:
  ollama:
EOF

# Set environment variables
export VANA_PRIVATE_KEY=$VANA_PRIVATE_KEY
export VANA_NETWORK=$VANA_NETWORK

# Start the miner
docker compose up -d

# Show logs
docker compose logs -fn 100
