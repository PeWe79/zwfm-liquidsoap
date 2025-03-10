#!/usr/bin/env bash

# Load the functions library
FUNCTIONS_LIB_PATH="/tmp/functions.sh"
FUNCTIONS_LIB_URL="https://raw.githubusercontent.com/oszuidwest/bash-functions/main/common-functions.sh"

# Download the latest version of the functions library
rm -f "${FUNCTIONS_LIB_PATH}"
if ! curl -sLo "${FUNCTIONS_LIB_PATH}" "${FUNCTIONS_LIB_URL}"; then
  echo -e "*** Failed to download the functions library. Please check your network connection! ***"
  exit 1
fi

# Source the functions library
# shellcheck source=/tmp/functions.sh
source "${FUNCTIONS_LIB_PATH}"

# Define base variables
INSTALL_DIR="/opt/liquidsoap"
GITHUB_BASE="https://raw.githubusercontent.com/oszuidwest/zwfm-liquidsoap/main"

# Docker files
DOCKER_COMPOSE_URL="${GITHUB_BASE}/docker-compose.yml"
DOCKER_COMPOSE_PATH="${INSTALL_DIR}/docker-compose.yml"
DOCKER_COMPOSE_ST_URL="${GITHUB_BASE}/docker-compose.stereotool.yml"
DOCKER_COMPOSE_ST_PATH="${INSTALL_DIR}/docker-compose.stereotool.yml"
DOCKER_COMPOSE_DAB_URL="${GITHUB_BASE}/docker-compose.dabplus.yml"
DOCKER_COMPOSE_DAB_PATH="${INSTALL_DIR}/docker-compose.dabplus.yml"

# Liquidsoap configuration
LIQUIDSOAP_CONFIG_URL_ZUIDWEST="${GITHUB_BASE}/conf/zuidwest.liq"
LIQUIDSOAP_CONFIG_URL_RUCPHEN="${GITHUB_BASE}/conf/rucphen.liq"
LIQUIDSOAP_CONFIG_PATH="${INSTALL_DIR}/scripts/radio.liq"

AUDIO_FALLBACK_URL="https://upload.wikimedia.org/wikipedia/commons/6/66/Aaron_Dunn_-_Sonata_No_1_-_Movement_2.ogg"
AUDIO_FALLBACK_PATH="${INSTALL_DIR}/audio/fallback.ogg"

# StereoTool configuration
STEREO_TOOL_VERSION="1051"
STEREO_TOOL_BASE_URL="https://download.thimeo.com"
STEREO_TOOL_ZIP_URL="${STEREO_TOOL_BASE_URL}/Stereo_Tool_Generic_plugin_${STEREO_TOOL_VERSION}.zip"
STEREO_TOOL_ZIP_PATH="/tmp/stereotool.zip"
STEREO_TOOL_INSTALL_DIR="${INSTALL_DIR}/stereotool"

# Open Digital Radio Encoder configuration
ODR_AUD_VERSION="v3.6.0"
ODR_AUD_BASE_URL="https://github.com/oszuidwest/zwfm-odrbuilds/releases/download/odr-audioenc-${ODR_AUD_VERSION}"
ODR_AUD_INSTALL_DIR="${INSTALL_DIR}/dabplus"
ODR_SOCKETS_DIR="${INSTALL_DIR}/dabplus/sockets"

# ODR PAD Encoder configuration
ODR_PAD_VERSION="v3.0.0"
ODR_PAD_BASE_URL="https://github.com/oszuidwest/zwfm-odrbuilds/releases/download/odr-padenc-${ODR_PAD_VERSION}"
ODR_PAD_INSTALL_DIR="${INSTALL_DIR}/dabplus"
ODR_PAD_DLS_DIR="${INSTALL_DIR}/dabplus/dls"
ODR_PAD_SLIDES_DIR="${INSTALL_DIR}/dabplus/slides"

# RDS configuration
RDS_RADIOTEXT_URL="https://rds.zuidwestfm.nl/?rt"
RDS_RADIOTEXT_PATH="${INSTALL_DIR}/metadata/rds_rt.txt"

# General configuration
TIMEZONE="Europe/Amsterdam"
DIRECTORIES=(
  "${INSTALL_DIR}/scripts"
  "${INSTALL_DIR}/audio"
  "${INSTALL_DIR}/metadata"
)
OS_ARCH=$(dpkg --print-architecture)

# Environment setup
set_colors
check_user_privileges privileged
is_this_linux
is_this_os_64bit
set_timezone "${TIMEZONE}"

# Ensure Docker is installed
require_tool "docker"

# Display a welcome banner
clear
cat << "EOF"
 ______     _     ___          __       _     ______ __  __
|___  /    (_)   | \ \        / /      | |   |  ____|  \/  |
   / /_   _ _  __| |\ \  /\  / /__  ___| |_  | |__  | \  / |
  / /| | | | |/ _` | \ \/  \/ / _ \/ __| __| |  __| | |\/| |
 / /_| |_| | | (_| |  \  /\  /  __/\__ \ |_  | |    | |  | |
/_____\__,_|_|\__,_|   \/  \/ \___||___/\__| |_|    |_|  |_|
EOF
echo -e "${GREEN}⎎ Liquidsoap and StereoTool Installation${NC}\n"

# Prompt user for input
ask_user "STATION_CONFIG" "zuidwest" "Which station configuration would you like to use? (zuidwest/rucphen)" "str"

# Validate station configuration
if [[ ! "$STATION_CONFIG" =~ ^(zuidwest|rucphen)$ ]]; then
    echo -e "${RED}Error: Invalid station configuration. Must be either 'zuidwest' or 'rucphen'.${NC}"
    exit 1
fi
ask_user "USE_ST" "n" "Would you like to use StereoTool for sound processing? (y/n)" "y/n"
ask_user "USE_DAB" "n" "Would you like to install DAB+ encoding support? (y/n)" "y/n"
ask_user "DO_UPDATES" "y" "Would you like to perform all OS updates? (y/n)" "y/n"

if [ "${DO_UPDATES}" == "y" ]; then
  update_os silent
fi

# Create required directories
echo -e "${BLUE}►► Creating directories...${NC}"
for dir in "${DIRECTORIES[@]}"; do
  mkdir -p "${dir}"
done

# Backup and download configuration files
echo -e "${BLUE}►► Downloading configuration files...${NC}"

# Set configuration URL based on user choice
if [ "${STATION_CONFIG}" == "zuidwest" ]; then
  LIQUIDSOAP_CONFIG_URL="${LIQUIDSOAP_CONFIG_URL_ZUIDWEST}"
else
  LIQUIDSOAP_CONFIG_URL="${LIQUIDSOAP_CONFIG_URL_RUCPHEN}"
fi

backup_file "${LIQUIDSOAP_CONFIG_PATH}"
if ! curl -sLo "${LIQUIDSOAP_CONFIG_PATH}" "${LIQUIDSOAP_CONFIG_URL}"; then
  echo -e "${RED}Error: Unable to download the Liquidsoap configuration for ${STATION_CONFIG}.${NC}"
  exit 1
fi

backup_file "${DOCKER_COMPOSE_PATH}"
if ! curl -sLo "${DOCKER_COMPOSE_PATH}" "${DOCKER_COMPOSE_URL}"; then
  echo -e "${RED}Error: Unable to download docker-compose.yml.${NC}"
  exit 1
fi

backup_file "${AUDIO_FALLBACK_PATH}"
if ! curl -sLo "${AUDIO_FALLBACK_PATH}" "${AUDIO_FALLBACK_URL}"; then
  echo -e "${RED}Error: Unable to download the audio fallback file.${NC}"
  exit 1
fi

if [ "${USE_ST}" == "y" ]; then
  echo -e "${BLUE}►► Installing StereoTool...${NC}"
  install_packages silent unzip

  # Add RDS update cronjob if it doesn't exist yet (TODO: Integrate this in Liquidsoap)
  if ! crontab -l | grep -q "${RDS_RADIOTEXT_PATH}"; then
    echo "0 * * * * curl -s ${RDS_RADIOTEXT_URL} > ${RDS_RADIOTEXT_PATH} 2>/dev/null" | crontab -
  fi

  # Download the StereoTool-specific docker-compose configuration
  backup_file "${DOCKER_COMPOSE_ST_PATH}"
  if ! curl -sLo "${DOCKER_COMPOSE_ST_PATH}" "${DOCKER_COMPOSE_ST_URL}"; then
    echo -e "${RED}Error: Unable to download docker-compose.stereotool.yml.${NC}"
    exit 1
  fi

  # Download RDS metadata
  if ! curl -sLo "${RDS_RADIOTEXT_PATH}" "${RDS_RADIOTEXT_URL}"; then
    echo -e "${RED}Error: Unable to download RDS metadata.${NC}"
    exit 1
  fi

  # Create installation directory
  mkdir -p "${STEREO_TOOL_INSTALL_DIR}"

  # Download and extract StereoTool
  if ! curl -sLo "${STEREO_TOOL_ZIP_PATH}" "${STEREO_TOOL_ZIP_URL}"; then
    echo -e "${RED}Error: Unable to download StereoTool.${NC}"
    exit 1
  fi
  TMP_DIR=$(mktemp -d)
  unzip -o "${STEREO_TOOL_ZIP_PATH}" -d "${TMP_DIR}"

  # Locate the extracted directory
  EXTRACTED_DIR=$(find "${TMP_DIR}" -maxdepth 1 -type d -name "libStereoTool_*" | head -n 1)
  if [ ! -d "${EXTRACTED_DIR}" ]; then
    echo -e "${RED}Error: Unable to find the extracted StereoTool directory.${NC}"
    exit 1
  fi

  # Copy the appropriate library based on the architecture
  case "${OS_ARCH}" in
    amd64)
      LIB_PATH="${EXTRACTED_DIR}/lib/Linux/IntelAMD/64/libStereoTool_intel64.so"
      ;;
    arm64)
      LIB_PATH="${EXTRACTED_DIR}/lib/Linux/ARM/64/libStereoTool_arm64.so"
      ;;
    *)
      echo -e "${RED}Unsupported architecture: ${OS_ARCH}${NC}"
      exit 1
      ;;
  esac

  if [ ! -f "${LIB_PATH}" ]; then
    echo -e "${RED}Error: StereoTool library not found at ${LIB_PATH}.${NC}"
    exit 1
  fi

  cp "${LIB_PATH}" "${STEREO_TOOL_INSTALL_DIR}/st_plugin.so"

  # Clean up temporary files
  rm -rf "${TMP_DIR}" "${STEREO_TOOL_ZIP_PATH}"

  # Write StereoTool configuration
  STEREOTOOL_RC_PATH="${STEREO_TOOL_INSTALL_DIR}/.st_plugin.so.rc"
  cat <<EOL > "${STEREOTOOL_RC_PATH}"
[Stereo Tool Configuration]
Enable web interface=1
Whitelist=/0
EOL
else
  # Remove StereoTool configuration from the Liquidsoap script if not in use
  sed -i '/# StereoTool implementation/,/output.dummy(.*)/d' "${LIQUIDSOAP_CONFIG_PATH}"
fi

# Install DAB+ encoder if requested
if [ "${USE_DAB}" == "y" ]; then
  echo -e "${BLUE}►► Installing DAB+ components...${NC}"
  
  # Create DAB installation directory
  mkdir -p "${ODR_AUD_INSTALL_DIR}"

  # Create DAB metadata sockets directory
  mkdir -p "${ODR_SOCKETS_DIR}"  
  
  # Create DAB PAD encoder directories
  mkdir -p "${ODR_PAD_DLS_DIR}"
  mkdir -p "${ODR_PAD_SLIDES_DIR}"
  
  # Determine the correct package based on architecture
  case "${OS_ARCH}" in
    amd64)
      ODR_AUD_PACKAGE="odr-audioenc-${ODR_AUD_VERSION}-minimal-debian-amd64"
      ODR_PAD_PACKAGE="odr-padenc-${ODR_PAD_VERSION}-debian-amd64"
      ;;
    arm64)
      ODR_AUD_PACKAGE="odr-audioenc-${ODR_AUD_VERSION}-minimal-debian-arm64"
      ODR_PAD_PACKAGE="odr-padenc-${ODR_PAD_VERSION}-debian-arm64"
      ;;
    *)
      echo -e "${RED}Unsupported architecture: ${OS_ARCH}${NC}"
      exit 1
      ;;
  esac

  # Download the appropriate ODR AudioEnc package
  ODR_AUD_DOWNLOAD_URL="${ODR_AUD_BASE_URL}/${ODR_AUD_PACKAGE}"

  echo -e "${BLUE}►► Downloading and installing ODR AudioEnc...${NC}"
  if ! curl -sLo "${ODR_AUD_INSTALL_DIR}/odr-audioenc" "${ODR_AUD_DOWNLOAD_URL}"; then
    echo -e "${RED}Error: Unable to download ODR AudioEnc package.${NC}"
    exit 1
  fi

  # Set executable permission
  chmod +x "${ODR_AUD_INSTALL_DIR}/odr-audioenc"
  
  # Download the appropriate ODR PADEnc package
  ODR_PAD_DOWNLOAD_URL="${ODR_PAD_BASE_URL}/${ODR_PAD_PACKAGE}"
  
  echo -e "${BLUE}►► Downloading and installing ODR PADEnc...${NC}"
  if ! curl -sLo "${ODR_PAD_INSTALL_DIR}/odr-padenc" "${ODR_PAD_DOWNLOAD_URL}"; then
    echo -e "${RED}Error: Unable to download ODR PADEnc package.${NC}"
    exit 1
  fi
  
  # Set executable permission
  chmod +x "${ODR_PAD_INSTALL_DIR}/odr-padenc"

  # Download the DAB-specific docker-compose configuration
  backup_file "${DOCKER_COMPOSE_DAB_PATH}"
  if ! curl -sLo "${DOCKER_COMPOSE_DAB_PATH}" "${DOCKER_COMPOSE_DAB_URL}"; then
    echo -e "${RED}Error: Unable to download docker-compose.dabplus.yml.${NC}"
    exit 1
  fi
fi

# Adjust ownership for the directories
echo -e "${BLUE}►► Setting ownership for ${INSTALL_DIR}...${NC}"
chown -R 10000:10001 "${INSTALL_DIR}"

echo -e "${GREEN}Installation completed successfully for ${STATION_CONFIG} configuration!${NC}"