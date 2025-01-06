#Requires -RunAsAdministrator

# /!\ Temporarily set script permissions: Set-ExecutionPolicy RemoteSigned (then reset Set-ExecutionPolicy Restricted afterwards)

# URLs of the certificates to download
$CERT_URLS = @(
    "https://doc-network.mcs.thalesdigital.io/assets/files/ZscalerRootCerts-Tunnel2.0-391a32d30045db061f3cc22011049c8e.zip"
    "http://crl.pki.thalesgroup.com/ThalesRootCAV3.crt"
    "http://crl.pki.thalesgroup.com/ThalesDevicesCAV4.crt"
    "http://crl.pki.thalesgroup.com/ThalesDevicesLevel2CAV4.crt"
    "http://crl.pki.thalesgroup.com/ThalesDevicesLevel1CAV4.crt"
    "http://crl.pki.thalesgroup.com/ThalesDevicesLevel3CAV4.crt"
)

# Function to download and install a certificate
function Download-AndInstallCert {
    param (
        [string]$url
    )
	
    $filename = Split-Path $url -Leaf
    Invoke-WebRequest -Uri $url -OutFile $filename

    if (-not (Test-Path $filename)) {
        Write-Error "Failed to download $filename."
        exit 1
    }

    if ($filename -like "*.zip") {
        Expand-Archive -Path $filename -DestinationPath "./"
        Remove-Item $filename
        foreach ($cert in Get-ChildItem -Path ZscalerRootCerts -Filter *.crt) {
			Write-Host "Importing ZScaler $($cert.Name) ..."
			Import-Certificate -FilePath $cert.Name -CertStoreLocation Cert:\LocalMachine\Root
        }
        Remove-Item -Recurse -Force ZscalerRootCerts
    } else {
		if ($filename -match "Root") {
			Write-Host "Importing Root $filename ..."
			Import-Certificate -FilePath $filename -CertStoreLocation Cert:\LocalMachine\Root
		}
		Write-Host "Importing CA $filename ..."
	    Import-Certificate -FilePath $filename -CertStoreLocation Cert:\LocalMachine\CA
        Remove-Item $filename
    }
}

# Download and install each certificate
foreach ($url in $CERT_URLS) {
    Download-AndInstallCert -url $url
}

Write-Host "Certificates installed successfully."
