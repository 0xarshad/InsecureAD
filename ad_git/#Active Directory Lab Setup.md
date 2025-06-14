#Active Directory Lab Setup

##Requirements
--------------

1. Windows Server (2019-2022) - This will be the Domain Contro1ller
2. Windows 11 (Client) - This will be the second in command
3. Windows 10 (Client) - This will be a PC
4. Windows 7 (Client) - This also will be a PC
5. Kali Linux (Attacker) - This will be our attackign machine

Step 1:- OS Installation
-------------------------
* VMware recommended
* Install all os inside VM 
* Catogorize them under a directory (ease of use)
* Make sure every os is running fine and using NAT
* Install VMware tools to boost perfomance

Step 2:- Setting up VMs
-------------------------
* Change Host Names
* Setup Static IP for each VM
* Setup DNS server on DC

Command - sconfig

Step 3:- Setting up Active Directory
-------------------------
* Find AD Domain Service - Get-WindowsFeature | ? {$_.Name -Like "AD"}
* Install AD Service - Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
* Import Module - import-Module ADDSDeployment
* Installing New Forest - Install-ADDSForest
          + Add a new Domain Name
          + Create Safe Admin Password

Step 4:- joining Domain
------------------------
* Find Interface - Get-NetIPAddress
* Find DNS info - Get-DnsClientServerAddress
* Set DNS to DC - Set-DnsClientServerAddress -InterfaceIndex 9 -ServerAddresses 192.168.133.155
* Joining a Domain - Add-Computer -DomainName "advuln.local" -Credential ADVULN\Administrator -Force -Restart

Step 5:- Enable Remote Session and Remote Copying
---------------------------
* Enable Remote Session on DC - Enable-PSRemoting
* List Trusted Hosts on Clint - Get-Item WSMan:\localhost\Client\TrustedHosts
* Add DC as Trusted Host -  Set-Item WSMan:\localhost\Client\TrustedHosts -Value 192.168.133.155
* Connect to Remote Session - New-PSSession -ComputerName 192.168.133.155 -Credential (Get-Credential)
* Enter to the session - Enter-PSSession 1
* Save Session to a Variable -  $dc = New-PSSession -ComputerName 192.168.133.155 -Credential (Get-Credential)
* Copy Item from client to Server - Copy-Item .\ad_schema.json -ToSession $dc C:\Users\Administrator\AD

Step 6:- Creating Users and Groups
---------------------------------
