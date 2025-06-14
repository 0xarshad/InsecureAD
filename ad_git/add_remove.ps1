
#parameter for specifying JSON file and Do/Undo
param( 
      [parameter(Mandatory=$true) ] $JsonFile,
      [switch]$Undo
     )

#Getting json schema and converting it to a PowerShell object
$json = (Get-Content $JsonFile | ConvertFrom-Json)

#Saving the domain name from the JSON object to a global variable
$Global:Domain = $json.domain

# Path to save password policy changes
$path = "C:\temp"

# Changing Password Policy to accept weak passwords
function WeakenPasswordPolicy()
 {
  # Ensure the temp directory exists, if not, create it
  if (-Not (Test-Path -Path $path)) 
   {
    New-Item -Path $path -ItemType Directory
    Write-Host "Directory created at $path"
   }
  else 
   {
    Write-Host "Directory already exists at $path"
   }
  # Export current security policy, modify it, and reapply
  secedit /export /cfg C:\temp\secpol.cfg
  (Get-Content C:\temp\secpol.cfg) -replace "PasswordComplexity = 1", "PasswordComplexity = 0" | Set-Content C:\temp\secpol.cfg
  (Get-Content C:\temp\secpol.cfg) -replace "MinimumPasswordLength = 7", "MinimumPasswordLength = 1" | Set-Content C:\temp\secpol.cfg
  secedit /configure /db C:\Windows\Security\Local.sdb /cfg C:\temp\secpol.cfg /areas SECURITYPOLICY
  Remove-Item C:\temp\secpol.cfg -Force
 } 


#Creating Group
function CreateADGroup()
    {
        param( [parameter(Mandatory=$true) ] $groupObject )
        
        # Pull out group name from the JSON object
        $name = $groupObject.name
    
        #Actually Creating AD Group
        New-ADGroup -Name $name -GroupScope Global
    }

#Creating user
function CreateADUser() 
   {
      param( [parameter(Mandatory=$true) ] $userObject )
      
      # Pull out name and password from the JSON object
      $name = $userObject.name
      $password = $userObject.password

      # Generate a name structure (firstname,lastname) and generate a username 
      $fullname = $name
      $firstname = $name.split(" ")[0]
      $lastname = $name.split(" ")[1]
      $username = ($name[0] + $name.split(" ")[1]).ToLower()
      $SamAccountName = $username
      $principalname = $username

      #Actually Creating AD User
      New-ADUser -Name $fullname -GivenName $firstname -Surname $lastname -SamAccountName $SamAccountName -UserPrincipalName $principalname@$Global:Domain -AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) -PassThru | Enable-ADAccount

       foreach ($group_name in $userObject.groups) 
          {
            try 
              {
                #Checking if the group exists
                Get-ADGroup -Identity  "$group_name"
                #Adding user to the appropriate group
                Add-ADGroupMember -Identity $group_name -Members $username
              }
            catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
              {
                #Error handling if the group does not exist
                Write-Warning "Group '$group_name' does not exist. Please create it before adding users." 
            
              }  
          }
    }
  
function StrengthenPasswordPolicy()
 {
  # Ensure the temp directory exists, if not, create it
  if (-Not (Test-Path -Path $path)) 
   {
    New-Item -Path $path -ItemType Directory
    Write-Host "Directory created at $path"
   }
  else 
   {
    Write-Host "Directory already exists at $path"
   }
  # Export current security policy, modify it, and reapply
  secedit /export /cfg C:\temp\secpol.cfg
  (Get-Content C:\temp\secpol.cfg) -replace "PasswordComplexity = 0", "PasswordComplexity = 1" | Set-Content C:\temp\secpol.cfg
  (Get-Content C:\temp\secpol.cfg) -replace "MinimumPasswordLength = 0", "MinimumPasswordLength = 7" | Set-Content C:\temp\secpol.cfg
  secedit /configure /db C:\Windows\Security\Local.sdb /cfg C:\temp\secpol.cfg /areas SECURITYPOLICY
  Remove-Item C:\temp\secpol.cfg -Force
 } 


#Removing AD Group
function RemoveADGroup()
  {
    param( [parameter(Mandatory = $true)] $groupObject )

    # Extract group name from JSON object
    $name = $groupObject.name

    # Remove the AD group
    Remove-ADGroup -Identity $name -Confirm:$false -ErrorAction Stop
  }


#Removing AD User
function RemoveADUser() 
 {  
    param( [parameter(Mandatory = $true)] $userObject )
    
    # Pull out name from the JSON object
    $name = $userObject.name

    # Generate the username (same logic as CreateADUser)
    $username = ($name[0] + $name.split(" ")[1]).ToLower()

    # Check if user exists
    try {
        Get-ADUser -Identity $username -ErrorAction Stop

        # Remove user from all groups first (optional but clean)
        $groups = Get-ADUser $username -Properties MemberOf | Select-Object -ExpandProperty MemberOf
        foreach ($group in $groups) {
            Remove-ADGroupMember -Identity $group -Members $username -Confirm:$false
        }

        # Remove the AD user
        Remove-ADUser -Identity $username -Confirm:$false
        Write-Host "User '$username' successfully removed."
    }
    catch {
        Write-Warning "User '$username' not found."
    }
  }


if ( -not $Undo) 
  { 
    # Calling the function to weaken password policy
     WeakenPasswordPolicy 

     # Running the function to create groups
      foreach ($group in $json.groups) 
    {
      CreateADGroup $group
    }

      # Running the function to create users
      foreach ($user in $json.users) 
    {
      CreateADUser $user
    }
  }
else
  {
    # Calling the function to strengthen password policy
     StrengthenPasswordPolicy

    # Running the function to remove groups
    foreach ($group in $json.groups) 
      {
        RemoveADGroup $group
      }

    # Running the function to remove users
    foreach ($user in $json.users) 
      {
        RemoveADUser $user
      }
  }

    
#ad_schema.json