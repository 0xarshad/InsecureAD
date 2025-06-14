param( [parameter(Mandatory=$true) ] $OutputJsonFile )

$first_names = [System.Collections.ArrayList](Get-Content first_names.txt)
$last_names = [System.Collections.ArrayList](Get-Content last_names.txt)
$passwords = [System.Collections.ArrayList](Get-Content passwords.txt)
$group_names = [System.Collections.ArrayList](Get-Content group_names.txt)

$groups = @()
$users = @()

# Generate 10 random groups from the group names list
$num_groups = 10

for ($i = 0; $i -lt $num_groups; $i++) 

{
    $group_name = (Get-Random -InputObject $group_names)
    $group = @{ "name" = "$group_name"}
    $groups += $group
    $group_names.Remove($group_name)
}

# Generate 10 random users from the first and last names lists
$num_users = 100

for ($i = 0; $i -lt $num_users; $i++) 

 {
    $first_name = (Get-Random -InputObject $first_names)
    $last_name = (Get-Random -InputObject $last_names)
    $password = (Get-Random -InputObject $passwords).Trim()

    $new_user = @{  `
        "name" = "$first_name $last_name"
        "password" = "$password"
        "groups" =  (Get-Random -InputObject $groups).name       
                 }
    $users += $new_user
    $first_names.Remove($first_name)
    $last_names.Remove($last_name)
    $passwords.Remove($password)
    
 }

ConvertTo-Json -InputObject @{ 
    "domain" = "advuln.local"
    "groups" = $groups
    "users" = $users
} | Out-File $OutputJsonFile