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

# Function to install the certificates on Debian-based systems
update_certificates_debian() {
  update-ca-certificates
}

# Function to install the certificates on Red Hat-based systems
update_certificates_redhat() {
  update-ca-trust
}

# Detect the OS and update the certificate store accordingly
if [[ -f /etc/debian_version ]]; then
  # Debian, Ubuntu, Linux Mint
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    if [[ "$ID" == "debian" ]]; then
      update_certificates_debian
      echo "Certificates installed successfully on Debian."
    elif [[ "$ID" == "ubuntu" ]]; then
      update_certificates_debian
      echo "Certificates installed successfully on Ubuntu."
    elif [[ "$ID" == "linuxmint" ]]; then
      update_certificates_debian
      echo "Certificates installed successfully on Linux Mint."
    else
      echo "Unsupported Debian-based distribution: $ID"
      exit 1
    fi
  fi
elif [[ -f /etc/redhat-release ]]; then
  # Red Hat, Fedora
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    if [[ "$ID" == "rhel" ]]; then
      update_certificates_redhat
      echo "Certificates installed successfully on Red Hat."
    elif [[ "$ID" == "fedora" ]]; then
      update_certificates_redhat
      echo "Certificates installed successfully on Fedora."
    else
      echo "Unsupported Red Hat-based distribution: $ID"
      exit 1
    fi
  fi
else
  echo "Unsupported operating system."
  exit 1
fi

echo "Certificates installed successfully."
