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

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  git \
  sed \
  coreutils \
  python3 \
  python3-dev \
  python3-pip \
  software-properties-common \
  openjdk \
  openjdk-8-jdk \
  openjdk-8-jre \  
msg_ok "Installed Dependencies"

msg_info "Setting up Crafty-Controller User"
useradd crafty -s /bin/bash

msg_info "Installing Craty-Controller (Patience)"
cd /opt
RELEASE=$(curl -s "https://gitlab.com/api/v4/projects/20430749/releases" | grep -o '"tag_name":"v[^"]*"' | head -n 1 | sed 's/"tag_name":"v//;s/"//')
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
wget -q "https://gitlab.com/crafty-controller/crafty-4/-/archive/v${RELEASE}/crafty-4-v${RELEASE}.zip"
unzip -q crafty-4-v${RELEASE}.zip
mv crafty-4-v${RELEASE} /opt/crafty-controller 
mkdir -p /opt/crafty-controller/ /opt/crafty-controller_data/minecraft/server
chown -R crafty:crafty /opt/craft-controller_data/
chown -R crafty:crafty /opt/craft-controller/
cd /opt/crafty-controller

msg_ok "Installed Craft-Controller"



msg_info "Creating Crafty 4 service file"
cat <<EOF >$SERVICE_FILE
[Unit]
Description=Crafty 4
After=network.target

[Service]
Type=simple
User=crafty
WorkingDirectory=
ExecStart=$BASH_BIN $RUN_SCRIPT
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

msg_info "Enabling and starting Crafty-Controller service"
systemctl enable --now crafty-controller.service




motd_ssh
customize

msg_info "Cleaning up"
rm -rf /opt/v${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
