#!/usr/bin/env bash
# OpenCart LXC installer for Proxmox VE (community-scripts style)
# Repo: https://github.com/vikdon/opencart-proxmox
# Source: https://github.com/opencart/opencart
# License: MIT

source <(curl -fsSL https://git.community-scripts.org/community-scripts/ProxmoxVE/raw/branch/main/misc/build.func)

# --- TRACE (debug) ---
TRACE="${TRACE:-1}"
if [[ "${TRACE}" == "1" ]]; then
  export PS4='+ [TRACE] ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]}(): '
  set -x
fi
# --- /TRACE ---

APP="OpenCart"

# --- Default CT resources / OS ---
var_tags="${var_tags:-ecommerce;shop;cms}"
var_disk="${var_disk:-8}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

# OpenCart version (override: var_oc_version=4.1.0.3)
var_oc_version="${var_oc_version:-4.1.0.3}"

# Your repo installer script URL
GIT_USER="${GIT_USER:-vikdon}"
GIT_REPO="${GIT_REPO:-opencart-proxmox}"
GIT_BRANCH="${GIT_BRANCH:-main}"
INSTALL_SCRIPT_URL="${INSTALL_SCRIPT_URL:-https://raw.githubusercontent.com/${GIT_USER}/${GIT_REPO}/${GIT_BRANCH}/install/opencart-install.sh}"

header_info "$APP"
variables
color
catch_errors



update_script() {
  header_info
  check_container_storage
  check_container_resources

  if pct exec "$CTID" -- bash -lc '[[ -d /var/www/html/opencart ]]'; then
    msg_error "OpenCart is recommended to be updated via official procedure (backup + files + DB), not via this script."
    exit 1
  else
    msg_error "No ${APP} Installation Found!"
    exit 1
  fi
}

# Override install step to pull install script from THIS repo
install_script() {
  msg_info "Installing ${APP} inside LXC (Patience)"

  # Ensure CT exists before exec
  if ! pct status "$CTID" >/dev/null 2>&1; then
    msg_error "CT ${CTID} does not exist. Container build step failed or CTID is wrong."
    exit 1
  fi

  # Run install script inside container
  if pct exec "$CTID" -- env OC_VERSION="${var_oc_version}" TRACE="${TRACE}" bash -lc "curl -fsSL '${INSTALL_SCRIPT_URL}' | bash"; then
    msg_ok "Installed ${APP}"
  else
    msg_error "OpenCart install failed inside CT ${CTID}"
    exit 1
  fi
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

# Show DB creds if present
DB_CREDS="$(pct exec "$CTID" -- bash -lc 'cat /root/.opencart_db_credentials 2>/dev/null || true')"
if [[ -n "${DB_CREDS}" ]]; then
  echo -e "${INFO}${YW} MariaDB credentials (stored in /root/.opencart_db_credentials):${CL}"
  echo -e "${TAB}${DB_CREDS}"
fi
