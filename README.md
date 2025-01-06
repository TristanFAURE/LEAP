# LEAP

Linux

```console
 curl -s -k https://raw.githubusercontent.com/TristanFAURE/LEAP/main/install_certificate.sh | sudo bash /dev/stdin
```

Windows

```console
Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/TristanFAURE/LEAP/main/install_certificate.ps1' -UseBasicParsing | Invoke-Expression`"" -Verb RunAs
```
