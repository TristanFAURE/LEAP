# LEAP

Linux

```bash
 curl -s -k https://raw.githubusercontent.com/TristanFAURE/LEAP/main/install_certificate.sh | sudo LEAP_PASSWORD=<password> bash /dev/stdin
```

Windows

```console
Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { `$true }; `$env:LEAP_PASSWORD = '<password>'; (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/TristanFAURE/LEAP/main/install_certificate.ps1') | Invoke-Expression`"" -Verb RunAs
```
