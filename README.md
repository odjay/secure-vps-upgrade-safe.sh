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

chmod +x secure-vps-upgrade-safe.sh
sudo ./secure-vps-upgrade-safe.sh


Follow Interactive Prompts
The script will guide you through:
Admin Username: Enter a username (skips if it exists).
SSH Keys: 
If keys exist, asks to replace them.
Option to generate a new key pair or paste an existing public key.
SSH Settings: 
Shows current settings (e.g., PermitRootLogin, PasswordAuthentication).
Asks: "Update SSH settings to enforce key-only access and disable root login? [y/N]".
Say "No" to preserve current login method and avoid lockout.
Other components (Docker, Portainer, etc.) install/upgrade automatically with status checks.
Post-Setup Verification
1. Test SSH Access
If you updated SSH settings:
bash
ssh <username>@<YOUR_VPS_IP>
Use the new/generated key.
Test before closing your current session to avoid lockout.
If unchanged, use your existing login method.
2. Check Portainer
Access the web interface:
URL: https://<YOUR_VPS_IP>:9443
Set up an admin user on first login.
Verify Docker containers are manageable.
3. Verify Fail2ban
Check SSH protection:
bash
fail2ban-client status sshd
Should show active jails and any banned IPs.
4. Review Firewall
Confirm open ports:
bash
ufw status
Expect: SSH (22) and Portainer (9443).
Customization
Additional Ports: Manually add rules (e.g., ufw allow 80) for web servers.
SSH Port: Edit /etc/ssh/sshd_config and update ufw allow <port> if not using 22.
Fail2ban: Adjust /etc/fail2ban/jail.local for custom ban settings.
Safety Features
SSH Lockout Prevention: Prompts before enforcing key-only access.
Upgrade Checks: Skips redundant steps if components are installed.
Preserves Data: Portainer updates retain existing volumes.
Troubleshooting
Locked Out?: Use VPS provider’s console (e.g., via web portal) to revert /etc/ssh/sshd_config.
Portainer Not Starting?: Check docker logs portainer for errors.
UFW Blocking?: Temporarily disable with ufw disable and reconfigure.
Contributing
Feel free to fork, submit issues, or PRs to improve the script! Suggestions for additional monitoring tools or security tweaks welcome.
License
MIT License - see LICENSE file for details.
Notes for GitHub
Repo Setup: Create a repo named secure-vps-setup (or your choice), upload the script, and paste this README.md.
License: Add a LICENSE file with MIT text if you’re okay with that (GitHub can generate it).
Username: Replace yourusername with your actual GitHub handle.
Script Name: Matches the latest version (secure-vps-upgrade-safe.sh).
