# Prompt for domain name
$domainName = Read-Host "Enter the fully qualified domain name (e.g., insecure.local)"

# Prompt for NetBIOS name
$netbiosName = Read-Host "Enter the NetBIOS domain name (e.g., INSECURE)"

# Prompt for Safe Mode Admin password (as SecureString)
$password = Read-Host "Enter Safe Mode Administrator Password" -AsSecureString

# Install the AD Domain Services role with management tools
Write-Host "`n[+] Installing Active Directory Domain Services..." -ForegroundColor Cyan
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools

# Import the ADDSDeployment module
Import-Module ADDSDeployment

# Install a new forest
Write-Host "[+] Installing new forest: $domainName..." -ForegroundColor Cyan
Install-ADDSForest `
    -DomainName $domainName `
    -DomainNetbiosName $netbiosName `
    -SafeModeAdministratorPassword $password `
    -InstallDNS:$true `
    -Force:$true

Write-Host "[-] Domain setup initiated. Your server will restart during the process." -ForegroundColor Green
