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

# Install curl, wget, and unzip if not installed
install_if_not_installed "curl"
install_if_not_installed "wget"
install_if_not_installed "unzip"

# URL of the ZIP file to download
ZIP_URL="https://doc-network.mcs.thalesdigital.io/assets/files/ZscalerRootCerts-Tunnel2.0-391a32d30045db061f3cc22011049c8e.zip"
ZIP_FILE="ZscalerRootCerts-Tunnel2.0.zip"
CERT_PATH="ZscalerRootCerts/ZscalerRootCertificate-2048-SHA256.crt"

# Download the ZIP file
if command -v curl &> /dev/null; then
  curl --insecure -o "$ZIP_FILE" "$ZIP_URL"
elif command -v wget &> /dev/null; then
  wget --no-check-certificate -O "$ZIP_FILE" "$ZIP_URL"
fi

if [[ ! -f "$ZIP_FILE" ]]; then
  echo "Failed to download the ZIP file."
  exit 1
fi

# Unzip the file
unzip "$ZIP_FILE" -d .

if [[ ! -f "$CERT_PATH" ]]; then
  echo "Failed to find the certificate in the extracted files."
  exit 1
fi

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
