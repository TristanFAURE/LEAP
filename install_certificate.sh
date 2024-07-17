#!/bin/bash

# Check if the script is run as sudo
if [[ "$EUID" -ne 0 ]]; then
  echo "This script must be run as sudo."
  exit 1
fi

# Function to install a package if not already installed
install_if_not_installed() {
  local package="$1"
  if ! command -v "$package" &> /dev/null; then
    echo "$package is not installed. Installing $package..."
    if [[ -f /etc/debian_version ]]; then
      apt-get update && apt-get install -y "$package"
    elif [[ -f /etc/redhat-release ]]; then
      yum install -y "$package"
    elif grep -qi "SUSE" /etc/os-release; then
      zypper install -y "$package"
    else
      echo "Unsupported operating system for package installation."
      exit 1
    fi
    if ! command -v "$package" &> /dev/null; then
      echo "Failed to install $package. Please install it manually and try again."
      exit 1
    fi
  fi
}

# Install curl if not installed
if ! command -v curl &> /dev/null; then
  install_if_not_installed "curl"
fi

# If curl installation failed, install wget
if ! command -v curl &> /dev/null; then
  install_if_not_installed "wget"
fi

# Check if curl or wget is available now
if command -v curl &> /dev/null; then
  DOWNLOAD_TOOL="curl"
elif command -v wget &> /dev/null; then
  DOWNLOAD_TOOL="wget"
else
  echo "Neither curl nor wget could be installed. Please install one of them manually and try again."
  exit 1
fi

# Install unzip if not installed
install_if_not_installed "unzip"

# URLs of the certificates to download
CERT_URLS=(
  "https://doc-network.mcs.thalesdigital.io/assets/files/ZscalerRootCerts-Tunnel2.0-391a32d30045db061f3cc22011049c8e.zip"
  "http://crl.pki.thalesgroup.com/ThalesRootCAV3.crt"
  "http://crl.pki.thalesgroup.com/ThalesDevicesCAV4.crt"
  "http://crl.pki.thalesgroup.com/ThalesDevicesLevel2CAV4.crt"
  "http://crl.pki.thalesgroup.com/ThalesDevicesLevel1CAV4.crt"
  "http://crl.pki.thalesgroup.com/ThalesDevicesLevel3CAV4.crt"
)

# Function to download and install a certificate
download_and_install_cert() {
  local url="$1"
  local filename=$(basename "$url")
  local cert_dir=""

  if [[ -f /etc/debian_version ]]; then
    # Use /usr/local/share/ca-certificates if it exists, otherwise /etc/ssl/certs
    if [[ -d /usr/local/share/ca-certificates ]]; then
      cert_dir="/usr/local/share/ca-certificates"
    else
      cert_dir="/etc/ssl/certs"
    fi
  elif [[ -f /etc/redhat-release ]]; then
    cert_dir="/etc/pki/ca-trust/source/anchors"
  elif grep -qi "SUSE" /etc/os-release; then
    cert_dir="/usr/share/pki/trust/anchors"
  else
    echo "Unsupported operating system."
    exit 1
  fi

  local cert_path="$cert_dir/$filename"

  if [[ "$DOWNLOAD_TOOL" == "curl" ]]; then
    curl --insecure -o "$filename" "$url"
  elif [[ "$DOWNLOAD_TOOL" == "wget" ]]; then
    wget --no-check-certificate -O "$filename" "$url"
  fi

  if [[ ! -f "$filename" ]]; then
    echo "Failed to download $filename."
    exit 1
  fi

  if [[ "$filename" == *.zip ]]; then
    unzip -o -qq "$filename" -d .
    rm "$filename"
    for cert in ZscalerRootCerts/*.crt; do
      local cert_filename=$(basename "$cert")
      local cert_dest="$cert_dir/$cert_filename"
      if [[ ! -f "$cert_dest" ]]; then
        cp "$cert" "$cert_dest"
      fi
    done
    rm -rf "ZscalerRootCerts"
  else
    if [[ ! -f "$cert_path" ]]; then
	cp "$filename" "$cert_path"
    fi
    rm "$filename"
  fi
}

# Download and install each certificate
for url in "${CERT_URLS[@]}"; do
  download_and_install_cert "$url"
done

# Function to update CA certificates
update_certificates() {
  if [[ -f /etc/debian_version ]] || [[ -f /etc/ubuntu-release ]] || [[ -f /etc/linuxmint-release ]]; then
    # Debian, Ubuntu, Linux Mint
    update-ca-certificates
  elif [[ -f /etc/redhat-release ]]; then
    # Red Hat, Fedora
    update-ca-trust
  elif grep -qi "SUSE" /etc/os-release; then
    # SUSE and openSUSE
    update-ca-certificates
  else
    echo "Unsupported operating system for updating CA certificates."
    exit 1
  fi
}

# Update CA certificates for the installed certificates
update_certificates

echo "Certificates installed and CA certificates updated successfully."
