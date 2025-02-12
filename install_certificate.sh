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

# Install openssl if not installed
install_if_not_installed "openssl"

# URLs of the certificates to download
CERT_URLS=(
  "http://crl.pki.thalesgroup.com/ThalesRootCAV3.crt"
  "http://crl.pki.thalesgroup.com/ThalesDevicesCAV4.crt"
  "http://crl.pki.thalesgroup.com/ThalesDevicesLevel2CAV4.crt"
  "http://crl.pki.thalesgroup.com/ThalesDevicesLevel1CAV4.crt"
  "http://crl.pki.thalesgroup.com/ThalesDevicesLevel3CAV4.crt"
)


# Function to get the directory for the certificates
get_cert_dir() {
  if [[ -f /etc/debian_version ]]; then
    # Use /usr/local/share/ca-certificates if it exists, otherwise /etc/ssl/certs
    if [[ -d /usr/local/share/ca-certificates ]]; then
      echo "/usr/local/share/ca-certificates"
    else
      echo "/etc/ssl/certs"
    fi
  elif [[ -f /etc/redhat-release ]]; then
    echo "/etc/pki/ca-trust/source/anchors"
  elif grep -qi "SUSE" /etc/os-release; then
    echo "/usr/share/pki/trust/anchors"
  else
    echo "Unsupported operating system."
    exit 1
  fi
}

# Function to download and install a certificate
download_and_install_cert() {
  local url="$1"
  local filename=$(basename "$url")
  local cert_dir
  cert_dir=$(get_cert_dir)

  if [[ "$DOWNLOAD_TOOL" == "curl" ]]; then
    curl --insecure -o "$filename" "$url"
  elif [[ "$DOWNLOAD_TOOL" == "wget" ]]; then
    wget --no-check-certificate -O "$filename" "$url"
  fi

  if [[ ! -f "$filename" ]]; then
    echo "Failed to download $filename."
    exit 1
  fi

  mv "$filename" "$cert_dir"
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

# Decrypt the data
DATA="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"
echo "$DATA" |  base64 --decode > dataenc
openssl enc -d -aes-256-cbc -iter 100000 -in dataenc -out zscaler.crt
mv zscaler.crt $(get_cert_dir)

# Update CA certificates for the installed certificates
update_certificates

echo "Certificates installed and CA certificates updated successfully."
