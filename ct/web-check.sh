#!/usr/bin/env bash
#source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
source <(curl -s https://raw.githubusercontent.com/CrazyWolf13/ProxmoxVE/refs/heads/CrazyWolf13-add-web-check/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Lissy93/web-check

APP="web-check"
TAGS="network;analysis"
var_cpu="4"
var_ram="4096"
var_disk="12"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /opt/web-check ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    RELEASE=$(curl -s https://api.github.com/repos/Lissy93/web-check/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    if [[ "${RELEASE}" != "$(cat /opt/web-check_version.txt)" ]] || [[ ! -f /opt/web-check_version.txt ]]; then
        msg_info "Stopping $APP"
        systemctl stop web-check
        msg_ok "Stopped $APP"

        msg_info "Backup Data"
        mkdir -p /opt/web-check-backup
        cp /opt/web-check/.env /opt/web-check-backup/.env
        msg_ok "Backed up Data"

        msg_info "Updating $APP to v${RELEASE}"
        $STD apt-get update
        $STD apt-get -y upgrade
        temp_dir=$(mktemp -d)
        temp_file=$(mktemp)
        cd $temp_dir
        wget -q "https://github.com/Lissy93/web-check/archive/refs/tags/v${RELEASE}.tar.gz" -O $temp_file
        tar xzf $temp_file
        cp -rf web-check-${RELEASE}/* /opt/web-check
        cd /opt/web-check
        $STD yarn install --frozen-lockfile --network-timeout 100000
        $STD yarn build --production
        mv /opt/web-check-backup/.env /opt/web-check/.env
        msg_ok "Updated $APP to v${RELEASE}"

        msg_info "Starting $APP"
        systemctl start web-check
        msg_ok "Started $APP"

        msg_info "Cleaning Up"
        rm -rf /opt/web-check-backup
        rm -rf $temp_file
        rm -rf $temp_dir
        msg_ok "Cleanup Completed"

        echo "${RELEASE}" >/opt/web-check_version.txt
        msg_ok "Update Successful"
    else
        msg_ok "No update required. ${APP} is already at v${RELEASE}"
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
