#Requires -RunAsAdministrator

# /!\ Temporarily set script permissions: `Set-ExecutionPolicy Bypass -Scope Process -Force;`

# Disable server certificate validation
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true };

# Check if the LEAP_PASSWORD variable is defined
if (-not $env:LEAP_PASSWORD) {
    Write-Host "Error: LEAP_PASSWORD env variable is required."
    exit 1
}

# URLs of the certificates to download
$CERT_URLS = @(
    "http://crl.pki.thalesgroup.com/ThalesRootCAV3.crt"
    "http://crl.pki.thalesgroup.com/ThalesDevicesCAV4.crt"
    "http://crl.pki.thalesgroup.com/ThalesDevicesLevel2CAV4.crt"
    "http://crl.pki.thalesgroup.com/ThalesDevicesLevel1CAV4.crt"
    "http://crl.pki.thalesgroup.com/ThalesDevicesLevel3CAV4.crt"
)

# Function to decrypt ZScaler certificate
function Decrypt-AES256CBC-Base64 {
    param (
        [string]$EncryptedBase64,   # Base64 data
        [string]$Password,          # Key password
        [int]$Iterations = 100000   # Number of iterations PBKDF2
    )
    
    $CipherData = [Convert]::FromBase64String($EncryptedBase64)
    if ([System.Text.Encoding]::ASCII.GetString($CipherData[0..7]) -ne "Salted__") {
        throw "Erreur : Invalid OpenSSL salt."
    }
    $Salt = $CipherData[8..15]
    $CipherText = $CipherData[16..($CipherData.Length - 1)]

    $PBKDF2 = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($Password, $Salt, $Iterations, [System.Security.Cryptography.HashAlgorithmName]::SHA256)
    $Key = $PBKDF2.GetBytes(32) # 256 bits
    $IV = $PBKDF2.GetBytes(16)  # 128 bits (CBC)

    $AES = [System.Security.Cryptography.Aes]::Create()
    $AES.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $AES.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $Decryptor = $AES.CreateDecryptor($Key, $IV)
    $DecryptedBytes = $Decryptor.TransformFinalBlock($CipherText, 0, $CipherText.Length)

    return [System.Text.Encoding]::UTF8.GetString($DecryptedBytes)
}

function Download-Cert {
    param (
        [string]$url
    )
	
    $filename = "$PSScriptRoot$(Split-Path $url -Leaf)"
    (New-Object Net.WebClient).DownloadFile($url, $filename)

    if (-not (Test-Path $filename)) {
        Write-Error "Failed to download $filename."
        exit 1
    }

    return $filename
}

function Install-Cert {
    param (
        [string]$filename
    )
	
    if (-not (Test-Path $filename)) {
        Write-Error "File does not exist $filename."
        exit 1
    }
    
	if ($filename -match "Root") {
		Write-Host "Importing Root $filename ..."
		Import-Certificate -FilePath $filename -CertStoreLocation Cert:\LocalMachine\Root
	}
	Write-Host "Importing CA $filename ..."
	Import-Certificate -FilePath $filename -CertStoreLocation Cert:\LocalMachine\CA
    Remove-Item $filename
}

function Download-AndInstallCert {
    param (
        [string]$url
    )
	
    $filename = Download-Cert -url $url
    Install-Cert -filename $filename
}

# Download and install each certificate
foreach ($url in $CERT_URLS) {
    Download-AndInstallCert -url $url
}

# Decrypt and install ZScaler root certificate
$EncryptedCert = "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"
$ZscalerRootFileName = "ZscalerRootCert.crt"
Decrypt-AES256CBC-Base64 -EncryptedBase64 $EncryptedCert -Password $env:LEAP_PASSWORD > $ZscalerRootFileName
Install-Cert -filename $ZscalerRootFileName

Write-Host "Certificates installed successfully."
