#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.craftycontrol.com/pages/getting-started/installation/linux/

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies (a lot of patience)"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  git \
  sed \
  lsb-release \
  apt-transport-https \
  coreutils \
  python3 \
  python3-dev \
  python3-pip \
  python3-venv \
  software-properties-common \
  openjdk-17-jdk \
  openjdk-17-jre
msg_info "Adding more recent java version"
wget -q https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.deb
$STD sudo dpkg -i jdk-21_linux-x64_bin.deb
msg_ok "Installed Dependencies"

msg_info "Setting up Crafty-Controller User"
useradd crafty -m -s /bin/bash

msg_info "Installing Craty-Controller (Patience)"
cd /opt
mkdir -p /opt/crafty-controller/crafty /opt/crafty-controller/server
RELEASE=$(curl -s "https://gitlab.com/api/v4/projects/20430749/releases" | grep -o '"tag_name":"v[^"]*"' | head -n 1 | sed 's/"tag_name":"v//;s/"//')
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
wget -q "https://gitlab.com/crafty-controller/crafty-4/-/archive/v${RELEASE}/crafty-4-v${RELEASE}.zip"
unzip -q crafty-4-v${RELEASE}.zip
mv crafty-4-v${RELEASE} /opt/crafty-controller/crafty/crafty-4

msg_info "Setting up python venv and installing dependencies"
cd /opt/crafty-controller/crafty
python3 -m venv .venv
chown -R crafty:crafty /opt/crafty-controller/
$STD sudo -u crafty bash <<EOF
    # Activate virtual environment
    source /opt/crafty-controller/crafty/.venv/bin/activate
    
    # Navigate to Crafty 4 directory
    cd /opt/crafty-controller/crafty/crafty-4
    
    # Install dependencies
    pip3 install --no-cache-dir -r requirements.txt
EOF
msg_ok "Installed Craft-Controller and dependencies"

msg_info "Creating Crafty 4 service and startup file"
cat > /opt/run_crafty-controller.sh << EOF
#!/bin/bash
cd /opt/crafty-controller/crafty
source .venv/bin/activate
cd crafty-4
exec python3 main.py
EOF
chmod +x /opt/run_crafty-controller.sh

cat <<EOF >/etc/systemd/system/crafty-controller.service
[Unit]
Description=Crafty 4
After=network.target

[Service]
Type=simple
User=crafty
WorkingDirectory=/opt/crafty-controller/crafty
ExecStart=/opt/run_crafty-controller.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

msg_info "Enabling and starting Crafty-Controller service"
systemctl enable --now crafty-controller.service


motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/crafty-4-v${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
# Wait for creds generation
sleep 10
echo -e "${TAB}${BL}Username: $(grep -oP '(?<="username": ")[^"]*' /opt/crafty-controller/crafty/crafty-4/app/config/default-creds.txt)${CL}"
echo -e "${TAB}${BL}Password: $(grep -oP '(?<="password": ")[^"]*' /opt/crafty-controller/crafty/crafty-4/app/config/default-creds.txt)${CL}"
