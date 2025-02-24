#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to prompt for yes/no with default no
prompt_yn() {
    local prompt="$1"
    local default="${2:-n}"
    local response

    while true; do
        read -p "$prompt [y/N]: " response
        response=${response:-$default}
        case $response in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

echo -e "${GREEN}Starting secure VPS setup/upgrade...${NC}"

# 1. System Update
echo "Updating system packages..."
apt update -y && apt upgrade -y

# 2. Create new admin user (if not exists)
read -p "Enter desired admin username: " username
if id "$username" >/dev/null 2>&1; then
    echo "User $username already exists, skipping creation."
else
    adduser --gecos "" "$username"
    usermod -aG sudo "$username"
fi

# 3. SSH Key Setup (skip if authorized_keys exists unless forced)
echo -e "${GREEN}Checking SSH key authentication${NC}"
mkdir -p /home/"$username"/.ssh
chmod 700 /home/"$username"/.ssh
if [ -f "/home/$username/.ssh/authorized_keys" ] && ! prompt_yn "SSH keys exist. Replace them?"; then
    echo "Keeping existing SSH keys."
else
    if prompt_yn "Generate a new SSH key pair?"; then
        ssh-keygen -t ed25519 -f /home/"$username"/.ssh/id_ed25519 -N ""
        chown "$username":"$username" /home/"$username"/.ssh/id_ed25519*
        echo "Your public key is:"
        cat /home/"$username"/.ssh/id_ed25519.pub
        echo "Copy this key to your local machine's ~/.ssh/authorized_keys"
    else
        read -p "Paste your public SSH key: " ssh_key
        echo "$ssh_key" > /home/"$username"/.ssh/authorized_keys
    fi
    chmod 600 /home/"$username"/.ssh/authorized_keys
    chown "$username":"$username" /home/"$username"/.ssh/authorized_keys
fi

# 4. Secure SSH Configuration (only if user agrees)
echo "Current SSH login settings:"
grep -E "PermitRootLogin|PasswordAuthentication|PubkeyAuthentication|AllowUsers" /etc/ssh/sshd_config | grep -v "^#" || echo "No custom settings found."
if prompt_yn "Update SSH settings to enforce key-only access and disable root login?"; then
    echo "Hardening SSH configuration..."
    if ! grep -q "PermitRootLogin no" /etc/ssh/sshd_config; then
        sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    fi
    if ! grep -q "PasswordAuthentication no" /etc/ssh/sshd_config; then
        sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    fi
    if ! grep -q "PubkeyAuthentication yes" /etc/ssh/sshd_config; then
        sed -i 's/#PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
    fi
    if ! grep -q "AllowUsers $username" /etc/ssh/sshd_config; then
        echo "AllowUsers $username" >> /etc/ssh/sshd_config
    fi
    systemctl restart sshd
    echo "SSH updated to key-only access. Test your connection before closing this session!"
else
    echo "Skipping SSH configuration changes. Current settings preserved."
fi

# 5. Install and configure UFW firewall (skip if active)
echo "Checking firewall..."
if command -v ufw >/dev/null && ufw status | grep -q "active"; then
    echo "UFW already active, ensuring required ports are open..."
    ufw allow OpenSSH >/dev/null 2>&1
    ufw allow 9443 >/dev/null 2>&1
else
    apt install ufw -y
    ufw allow OpenSSH
    ufw allow 9443  # For Portainer
    ufw --force enable
fi
ufw status

# 6. Install/Upgrade Fail2ban
if command -v fail2ban-client >/dev/null; then
    echo "Fail2ban already installed, updating..."
    apt install fail2ban -y --only-upgrade
else
    echo "Installing fail2ban..."
    apt install fail2ban -y
    systemctl enable fail2ban
    systemctl start fail2ban
fi
# Ensure SSH jail is configured
if [ ! -f /etc/fail2ban/jail.local ]; then
    cat << EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 5
bantime = 3600
EOF
    systemctl restart fail2ban
fi

# 7. Setup automatic security updates (skip if configured)
if dpkg -l | grep -q unattended-upgrades; then
    echo "Unattended-upgrades already installed, skipping configuration."
else
    echo "Configuring automatic security updates..."
    apt install unattended-upgrades -y
    dpkg-reconfigure --priority=low unattended-upgrades
fi

# 8. Install/Upgrade Docker
if command -v docker >/dev/null; then
    echo "Docker already installed, checking for updates..."
    apt install docker.io -y --only-upgrade
else
    echo "Installing Docker..."
    apt install docker.io -y
    systemctl start docker
    systemctl enable docker
fi
usermod -aG docker "$username"

# 9. Install/Upgrade Portainer
if docker ps -a --format '{{.Names}}' | grep -q "^portainer$"; then
    echo "Portainer detected, updating..."
    docker stop portainer
    docker rm portainer
    docker pull portainer/portainer-ce:latest
    docker run -d -p 9443:9443 --name portainer \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:latest
else
    echo "Installing Portainer..."
    docker volume create portainer_data
    docker run -d -p 9443:9443 --name portainer \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v portainer_data:/data \
        portainer/portainer-ce:latest
fi
echo "Portainer running. Access it via https://YOUR_VPS_IP:9443"

# 10. Basic security headers (apply if not set)
echo "Checking security configurations..."
if ! grep -q "fs.suid_dumpable = 0" /etc/sysctl.conf; then
    echo "fs.suid_dumpable = 0" >> /etc/sysctl.conf
fi
if ! grep -q "kernel.randomize_va_space = 2" /etc/sysctl.conf; then
    echo "kernel.randomize_va_space = 2" >> /etc/sysctl.conf
fi
sysctl -p >/dev/null

echo -e "${GREEN}VPS Setup/Upgrade Complete!${NC}"
echo "Current status:"
echo "- SSH: Configured per your choice (check settings above)"
echo "- Firewall: SSH and Portainer (9443) allowed"
echo "- Fail2ban: Protecting SSH"
echo "- Docker: Installed/Updated with Portainer"
echo "Next steps:"
echo "1. If new SSH key generated, save it securely"
echo "2. Test SSH: ssh $username@YOUR_VPS_IP"
echo "3. Check Portainer: https://YOUR_VPS_IP:9443"
echo "4. Replace YOUR_VPS_IP with your actual server IP"
