#!/usr/bin/env bash
source <(curl -fsSL https://git.community-scripts.org/community-scripts/ProxmoxVE/raw/branch/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG | vikdon
# Author: vikdon
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/opencart/opencart

## App Default Values
APP="OpenCart"
var_tags="${var_tags:-ecommerce;shop;cms}"
var_disk="${var_disk:-8}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

# OpenCart defaults (можна перевизначити перед запуском, напр. var_oc_version=4.1.0.3)
var_oc_version="${var_oc_version:-4.1.0.3}"

# Ваш репозиторій (raw) з install-скриптом
GIT_USER="${GIT_USER:-vikdon}"
GIT_REPO="${GIT_REPO:-opencart-proxmox}"
GIT_BRANCH="${GIT_BRANCH:-main}"
INSTALL_SCRIPT_URL="${INSTALL_SCRIPT_URL:-https://raw.githubusercontent.com/${GIT_USER}/${GIT_REPO}/${GIT_BRANCH}/install/opencart-install.sh}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if pct exec "$CTID" -- bash -c '[[ -d /var/www/html/opencart ]]'; then
    msg_error "OpenCart рекомендується оновлювати згідно офіційної процедури (backup + файли + DB), а не через цей скрипт."
    exit 1
  else
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi
}

# Перевизначаємо install_script(), щоб брати install-скрипт з вашого репозиторію
function install_script() {
  msg_info "Installing ${APP} inside LXC (Patience)"
  pct exec "$CTID" -- env OC_VERSION="${var_oc_version}" bash -c "curl -fsSL '${INSTALL_SCRIPT_URL}' | bash"
  msg_ok "Installed ${APP}"
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN} ${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}/${CL}"
echo -e "${INFO}${YW} OpenCart installer:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}/install/${CL}"

# Спроба показати DB-креденшали (створюються install-скриптом)
DB_CREDS="$(pct exec "$CTID" -- bash -c 'cat /root/.opencart_db_credentials 2>/dev/null || true')"
if [[ -n "${DB_CREDS}" ]]; then
  echo -e "${INFO}${YW} MariaDB credentials (збережено в /root/.opencart_db_credentials):${CL}"
  echo -e "${TAB}${DB_CREDS}"
fi
