# LEAP

Linux

```console
 curl -s -k https://raw.githubusercontent.com/TristanFAURE/LEAP/main/install_certificate.sh | sudo bash /dev/stdin
```

Windows

```console
Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { `$true }; (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/TristanFAURE/LEAP/main/install_certificate.ps1') | Invoke-Expression`"" -Verb RunAs
```
