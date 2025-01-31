#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/CrazyWolf13/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.craftycontrol.com/pages/getting-started/installation/linux/

# App Default Values
APP="Crafty-Controller"
var_tags="gaming"
var_cpu="2"
var_ram="4096"
var_disk="16"
var_os="debian"
var_version="12"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /opt/crafty-controller ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
   
    RELEASE=$(curl -s "https://gitlab.com/api/v4/projects/20430749/releases" | grep -o '"tag_name":"v[^"]*"' | head -n 1 | sed 's/"tag_name":"v//;s/"//')
    if [[ ! -f /opt/$crafty-controller_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/crafty-controller_version.txt)" ]]; then
      
      msg_info "Stopping Crafty-Controller"
      systemctl stop crafty.service
      msg_ok "Stopped Crafty-Controller"
      
      msg_info "Updating Crafty-Controller to v${RELEASE}"
      cd /opt
      wget -q "https://gitlab.com/crafty-controller/crafty-4/-/archive/v${RELEASE}/crafty-4-v${RELEASE}.zip"
      unzip -q crafty-4-v${RELEASE}.zip
      mv crafty-4-v${RELEASE} /opt/crafty-controller 
      cd /opt/crafty-controller

      # Update instructions
      
      echo "${RELEASE}" >"/opt/craft-controller_version.txt"
      rm -rf /opt/crafty-4-v${RELEASE}.zip
      msg_ok "Updated Crafty-Controller to v${RELEASE}"

      msg_info "Starting Crafty-Controller"
      systemctl start crafty.service
      msg_ok "Started Crafty-Controller"

      msg_ok "Updated Successfully"
      exit
  else
    msg_ok "No update required. Crafty-Controller is already at v${RELEASE}."
  fi
}


start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:8443${CL}"
echo -e "${TAB}${BL}Username: $(grep -oP '(?<="username": ")[^"]*' /opt/crafty-controller/crafty/crafty-4/app/config/default-creds.txt)${CL}"
echo -e "${TAB}${BL}Password: $(grep -oP '(?<="password": ")[^"]*' /opt/crafty-controller/crafty/crafty-4/app/config/default-creds.txt)${CL}"

