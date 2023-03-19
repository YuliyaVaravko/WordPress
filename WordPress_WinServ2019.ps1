<#
============================== IIS ================================
#>
"  - Installing ISS"
Install-WindowsFeature -name Web-Server,Web-Common-Http,Web-Static-Content,Web-Default-Doc,Web-Dir-Browsing,
Web-Http-Errors,Web-App-Dev,Web-CGI,Web-Health, Web-Http-Logging,Web-Log-Libraries,Web-Request-Monitor,
Web-Security,Web-Filtering,Web-Performance,Web-Stat-Compression,Web-Mgmt-Tools, `
Web-Mgmt-Service,WAS,WAS-Process-Model,WAS-NET-Environment, WAS-Config-APIs,Net-Framework-Core -IncludeManagementTools
"  - Installation ISS completed successfully"
<#
============================== PHP ================================
#>
"  - Installing PHP"
# Variables for PHP
$PHP_ZIP = "php-7.4.33-nts-Win32-vc15-x64.zip"
$PHP_PATH = "C:\PHP"

"  - Downloading PHP"
Invoke-WebRequest "http://windows.php.net/downloads/releases/$PHP_ZIP" -OutFile "$PHP_ZIP"
"  - Expanding"
Expand-Archive "$PHP_ZIP" "$PHP_PATH"

"  - Creating PHP.INI"
Copy-Item "$PHP_PATH\php.ini-production" "$PHP_PATH\php.ini"
(get-content -path C:\php\php.ini) -replace 'open_basedir =', 'open_basedir = C:\inetpub\wwwroot'|Set-Content -Path C:\php\php.ini
(get-content -path C:\php\php.ini) -replace 'cgi.force_redirect = 1', 'cgi.force_redirect = 0'|Set-Content -Path C:\php\php.ini
(get-content -path C:\php\php.ini) -replace 'short_open_tag = Off', 'short_open_tag = On'|Set-Content -Path C:\php\php.ini
"  - Installation PHP completed successfully"
<#
============================== VCRUNTIME140.dll ================================
#>
"  - Installing VCRUNTIME140.dll"
"  - Downloading"
Invoke-WebRequest "https://aka.ms/vs/17/release/vc_redist.x64.exe" -OutFile "vc_redist.x64.exe"
"  - Installing"
.\vc_redist.x64.exe /Q
"  - Installation VCRUNTIME140.dll completed successfully"
<#
============================== PHP Manager for IIS ================================
#>
"  - Installing PHP Manager for IIS"
"  - Downloading"
Invoke-WebRequest "https://github.com/phpmanager/phpmanager/releases/download/v2.11/PHPManagerForIIS_x64.msi" -OutFile "PHPManagerForIIS_x64.msi"
"  - Installing"
Start-Process "msiexec.exe" "/i PHPManagerForIIS_x64.msi /qn" -Wait

# Add the PHP Manager PowerShell Snap-In
Get-PSSnapin -registered
# Add the PHP Manager PowerShell Snap-In
Add-PsSnapin PHPManagerSnapin
# Register PHP with Internet Information Services (IIS)
New-PHPVersion "$PHP_PATH\php-cgi.exe"
"  - Installation and configuration PHP Manager for IIS completed successfully"
<#
============================== MySQL ================================
#>
"  - Installing MySQL"
# Install MySQL
# Variables for MySQL
$MYSQL_ZIP = "mysql-5.7.40-winx64"
$MYSQL_URL = "https://downloads.mysql.com/archives/get/p/23/file/$MYSQL_ZIP.zip"
$MYSQL_NAME = "MySQL"
$MYSQL_PROD = "$MYSQL_NAME Server 5.7"
$MYSQL_PATH = "$env:ProgramFiles\$MYSQL_NAME"
$MYSQL_BASE = "$MYSQL_PATH\$MYSQL_PROD"
$MYSQL_PDTA = "$env:ProgramData\$MYSQL_NAME\$MYSQL_PROD"
$MYSQL_DATA = "$MYSQL_PDTA\data"
$MYSQL_INIT = "$MYSQL_PDTA\mysql-init.sql"
$MYSQL_USER = "wp_user"
$MYSQL_DB_NAME = "wordpress"
$MYSQL_DB_HOST = "localhost"

# Download and install MySQL
"  - Downloading"
Invoke-WebRequest "$MYSQL_URL" -OutFile "$MYSQL_ZIP.zip"
"  - Expanding"
Expand-Archive "$MYSQL_ZIP.zip" "$MYSQL_PATH"

"  - Renaming destination directory"
Rename-Item "$MYSQL_PATH\$MYSQL_ZIP" "$MYSQL_BASE"

# Add the MySQL “bin” directory to the search Path variable
"  - Setting PATH variable"
$env:Path += ";$MYSQL_BASE\bin"
setx Path $env:Path /m

# Create a MySQL Option File
"  - Creating MY.INI"
Set-Content "$MYSQL_BASE\my.ini" "[mysqld]`r`nbasedir=""$MYSQL_BASE""`r`ndatadir=""$MYSQL_DATA""`r`nexplicit_defaults_for_timestamp=1"

# Create the MySQL database directory
"  - Creating database directory"
New-Item $MYSQL_DATA -ItemType "Directory"

# Initialise the MySQL database files
"  - Initialising database directory"
mysqld --initialize-insecure #--console

# Install MySQL as a Windows service
"  - Installing MySQL as Windows Service"
mysqld --install

# Start the MySQL service
"  - Starting MySQL Windows Service"
Start-Service MySQL

# Generate random passwords for 'root' and 'wordpress' accounts
Add-Type -AssemblyName System.Web
$MYSQL_ROOT_PWD = [System.Web.Security.Membership]::GeneratePassword(18,3)
$MYSQL_WORD_PWD = [System.Web.Security.Membership]::GeneratePassword(18,3)

# Create a MySQL initialisation script
"  - Generating initialisation script"
Set-Content $MYSQL_INIT "ALTER USER 'root'@'$MYSQL_DB_HOST' IDENTIFIED BY '$MYSQL_ROOT_PWD';"
Add-Content $MYSQL_INIT "CREATE DATABASE $MYSQL_DB_NAME;"
Add-Content $MYSQL_INIT "CREATE USER '$MYSQL_USER'@'$MYSQL_DB_HOST' IDENTIFIED BY '$MYSQL_WORD_PWD';"
Add-Content $MYSQL_INIT "GRANT ALL PRIVILEGES ON $MYSQL_DB_NAME.* TO '$MYSQL_USER'@'$MYSQL_DB_HOST';"

# Execute the MySQL initialisation script
"  - Executing initialisation script"
mysql --user=root --execute="source $MYSQL_INIT"
"  - Installation and configuration MYSQL completed successfully"

<#
============================== WordPress ================================
#>
"  - Installing WordPress"
# Variables for WordPress
$IIS_PATH = "$env:SystemDrive\inetpub"
$WORDPRESS_PATH = "$IIS_PATH\wordpress"
$WORDPRESS_URL = "https://wordpress.org/latest.zip"
$WORDPRESS_ZIP = "wordpress.zip"

# Install WordPress
"  - Downloading"
Invoke-WebRequest "$WORDPRESS_URL" -OutFile "$WORDPRESS_ZIP"
"  - Expanding"
Expand-Archive "$WORDPRESS_ZIP" "$IIS_PATH"

# Modify rights to the WordPress directory
"NuGet installation"
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
"Installing NTFSSecurity"
Install-Module -Name NTFSSecurity -Force
"Import NTFSSecurity"
Import-Module NTFSSecurity
"  - Appying NTFS Permissions (IIS_IUSRS)"
Add-NTFSAccess "$WORDPRESS_PATH" IIS_IUSRS Modify
"  - Appying NTFS Permissions (IUSR)"
Add-NTFSAccess "$WORDPRESS_PATH" IUSR Modify

# Create a new application pool for WordPress
"  - Creating Application Pool"
$WebAppPool = New-WebAppPool "WordPress"
$WebAppPool.managedPipelineMode = "Classic"
$WebAppPool.managedRuntimeVersion = ""
$WebAppPool | Set-Item

# Create a new website for WordPress
"  - Creating WebSite"
New-Website "WordPress" -ApplicationPool "WordPress" -PhysicalPath "$WORDPRESS_PATH" 

# Remove the “Default Web Site” and start the new “WordPress” website
"  - Activating WebSite"
Remove-Website "Default Web Site"
Start-Website "WordPress"

#Create WordPress Config File
"Configuring wp-config.php. \n-Setting Database Credentials"
Copy-Item -Path "$WORDPRESS_PATH\wp-config-sample.php" -Destination "$WORDPRESS_PATH\wp-config.php"
(Get-Content -Path $WORDPRESS_PATH\wp-config.php).Replace("define( 'DB_NAME', 'database_name_here' )","define( 'DB_NAME', '$MYSQL_DB_NAME' )")| Set-Content -Path $WORDPRESS_PATH\wp-config.php | Out-Null
(Get-Content -Path $WORDPRESS_PATH\wp-config.php).Replace("define( 'DB_USER', 'username_here' )","define( 'DB_USER', '$MYSQL_USER' )")| Set-Content -Path $WORDPRESS_PATH\wp-config.php | Out-Null
(Get-Content -Path $WORDPRESS_PATH\wp-config.php).Replace("define( 'DB_PASSWORD', 'password_here' )","define( 'DB_PASSWORD', '$MYSQL_WORD_PWD' )")| Set-Content -Path $WORDPRESS_PATH\wp-config.php | Out-Null

"       root = $MYSQL_ROOT_PWD"
"  wordpress = $MYSQL_WORD_PWD"
$IPADDRESS = (Get-NetIPAddress | ? {($_.AddressFamily -eq "IPv4") -and ($_.IPAddress -ne "127.0.0.1")}).IPAddress
"`r`nConnect your web browser to http://$IPADDRESS/ to complete this WordPress`r`ninstallation.`r`n"