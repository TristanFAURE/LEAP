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

# URL of the ZIP file to download
ZIP_URL="https://doc-network.mcs.thalesdigital.io/assets/files/ZscalerRootCerts-Tunnel2.0-391a32d30045db061f3cc22011049c8e.zip"
ZIP_FILE="ZscalerRootCerts-Tunnel2.0.zip"
CERT_PATH="ZscalerRootCerts/ZscalerRootCertificate-2048-SHA256.crt"

# Download the ZIP file
if [[ "$DOWNLOAD_TOOL" == "curl" ]]; then
  curl --insecure -o "$ZIP_FILE" "$ZIP_URL"
elif [[ "$DOWNLOAD_TOOL" == "wget" ]]; then
  wget --no-check-certificate -O "$ZIP_FILE" "$ZIP_URL"
fi

if [[ ! -f "$ZIP_FILE" ]]; then
  echo "Failed to download the ZIP file."
  exit 1
fi

# Unzip the file silently
unzip -o -qq "$ZIP_FILE" -d .

if [[ ! -f "$CERT_PATH" ]]; then
  echo "Failed to find the certificate in the extracted files."
  exit 1
fi

echo "Certificate extracted successfully."

# Function to install the certificate on Debian
install_cert_debian() {
  cp "$CERT_PATH" /usr/local/share/ca-certificates/
  update-ca-certificates
}

# Function to install the certificate on Ubuntu
install_cert_ubuntu() {
  cp "$CERT_PATH" /usr/local/share/ca-certificates/
  update-ca-certificates
}

# Function to install the certificate on Red Hat
install_cert_redhat() {
  cp "$CERT_PATH" /etc/pki/ca-trust/source/anchors/
  update-ca-trust
}

# Function to install the certificate on Fedora
install_cert_fedora() {
  cp "$CERT_PATH" /etc/pki/ca-trust/source/anchors/
  update-ca-trust
}

# Function to install the certificate on Linux Mint
install_cert_linuxmint() {
  cp "$CERT_PATH" /usr/local/share/ca-certificates/
  update-ca-certificates
}

# Detect the OS and install the certificate accordingly
if [[ -f /etc/debian_version ]]; then
  # Debian or Ubuntu
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    if [[ "$ID" == "debian" ]]; then
      install_cert_debian
      echo "Certificate installed successfully on Debian."
    elif [[ "$ID" == "ubuntu" ]]; then
      install_cert_ubuntu
      echo "Certificate installed successfully on Ubuntu."
    elif [[ "$ID" == "linuxmint" ]]; then
      install_cert_linuxmint
      echo "Certificate installed successfully on Linux Mint."
    else
      echo "Unsupported Debian-based distribution: $ID"
      exit 1
    fi
  fi
elif [[ -f /etc/redhat-release ]]; then
  # Red Hat or Fedora
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    if [[ "$ID" == "rhel" ]]; then
      install_cert_redhat
      echo "Certificate installed successfully on Red Hat."
    elif [[ "$ID" == "fedora" ]]; then
      install_cert_fedora
      echo "Certificate installed successfully on Fedora."
    else
      echo "Unsupported Red Hat-based distribution: $ID"
      exit 1
    fi
  fi
else
  echo "Unsupported operating system."
  exit 1
fi

# Clean up the uncompressed files
rm -rf "ZscalerRootCerts"
rm "$ZIP_FILE"

echo "Cleanup completed."
