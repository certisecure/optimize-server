#!/bin/bash

# Enable strict error handling
set -e

echo "Starting server optimization..."

# Step 1: Update and Upgrade Packages
echo "Updating system packages..."
sudo apt update -y && sudo apt upgrade -y

# Step 2: Set Up Swap File (4GB)
SWAP_SIZE_GB=4
SWAP_FILE="/swapfile"

if [ ! -f $SWAP_FILE ]; then
    echo "Creating a ${SWAP_SIZE_GB}GB swap file..."
    sudo fallocate -l ${SWAP_SIZE_GB}G $SWAP_FILE
    sudo chmod 600 $SWAP_FILE
    sudo mkswap $SWAP_FILE
    sudo swapon $SWAP_FILE
    echo "$SWAP_FILE none swap sw 0 0" | sudo tee -a /etc/fstab
else
    echo "Swap file already exists, skipping swap creation."
fi

# Step 3: Set Swappiness and Cache Pressure
echo "Configuring swappiness and cache pressure..."
sudo sysctl vm.swappiness=10
sudo sysctl vm.vfs_cache_pressure=50
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf

# Step 4: Configure File Descriptors Limit
echo "Configuring file descriptors limit..."
echo "* soft nofile 65535" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65535" | sudo tee -a /etc/security/limits.conf
echo "fs.file-max=100000" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Step 5: Enable UFW and Allow Basic Ports
echo "Setting up UFW firewall rules..."
sudo apt install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw --force enable

# Step 6: Install Common Server Utilities
echo "Installing useful server utilities..."
sudo apt install -y htop curl wget fail2ban unattended-upgrades

# Step 7: Configure Unattended Upgrades (Security Updates)
echo "Configuring automatic security updates..."
sudo apt install -y unattended-upgrades
sudo unattended-upgrade -d

# Step 8: Optimize Network Settings (TCP)
echo "Optimizing TCP settings for better network performance..."
echo "net.core.somaxconn=1024" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_syncookies=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_tw_reuse=1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.ip_local_port_range=2000 65000" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog=3240000" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_fin_timeout=15" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

echo "Server optimization completed successfully!"
