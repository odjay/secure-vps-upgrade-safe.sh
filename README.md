# Secure VPS Setup with Docker and Portainer

This repository contains a Bash script (`secure-vps-upgrade-safe.sh`) to set up or upgrade a secure Ubuntu-based VPS with SSH key authentication, Docker, Portainer for container management, and Fail2ban for intrusion prevention. It’s designed to be safe for both fresh installs and existing systems, with checks to avoid breaking current configurations and a prompt to prevent SSH lockout.

## Features
- **SSH Security**: Optional key-only authentication, root login disabled, and user restriction.
- **Firewall**: Configures UFW with minimal open ports (SSH and Portainer).
- **Intrusion Prevention**: Installs/upgrades Fail2ban with SSH protection.
- **Docker**: Installs or updates Docker and adds the user to the docker group.
- **Portainer**: Deploys or updates Portainer for Docker management on port 9443.
- **Automatic Updates**: Sets up unattended-upgrades for security patches.
- **Upgrade-Friendly**: Detects existing components and updates them without disruption.

## Prerequisites
- Ubuntu-based VPS (tested on 20.04/22.04).
- Root or sudo access.
- Basic familiarity with SSH and terminal usage.

## Installation Steps

### 1. Clone the Repository
Download the script to your VPS:
```bash
git clone https://github.com/yourusername/secure-vps-setup.git
cd secure-vps-setup
