# Stephanie Seyler
# 2021-03-14
# v0.5.0
# RES
function New-AventailTable {
    <#
    .SYNOPSIS
        Appends the new data to the top of the Datatable and exports it to $path
    .DESCRIPTION
        Gets data from $SSL and puts it at the top of the data table then fills from the rest of the master table.
        Exports completed table overwriting the orignial master table
    .PARAMETER Table
        Empty table that will be filled with data from $SSL
    .PARAMETER SSL
        Powershell DataTable with data from Sonicwall appliance
    .PARAMETER Path
        Path to where the Master Datatable csv is stored
    .INPUTS
        All parameters are required: table, ssl, Path
    .OUTPUTS
        Export Csv file that can be imported for use later
    .EXAMPLE
        New-AventailTable -table $table -SSL $SSL01 -path $path
    .Notes
        Author: Stephanie Seyler  
        Version: 1.2.0
        Date Created: 2020-03-19
        Date Modified: 2020-03-31
    #>
    param (
        [parameter(mandatory=$true,valueFromPipeline=$true)] $table,
        [parameter(mandatory=$true,valueFromPipeline=$true)] $SSL, 
        [parameter(mandatory=$true,valueFromPipeline=$true)] $Path
    )
    foreach($i in "Time","Resource","ActiveUsers","CPU","Memory","Disk","Swap","Internal","External","TCP","HTTP"){
        [void]$table.Columns.Add($i)
    }
    $Table.rows.Add($SSL.systemTime, $SSL.applianceName, $SSL.activeUserCount, $SSL.cpuUsagePercent,`
        $SSL.memoryUsagePercent, $SSL.diskUsagePercent, $SSL.internalInterfaceMbps, $SSL.externalInterfaceMbps,`
        $SSL.tcpConnectionCount, $SSL.webConnectionCount)
    $temp = Import-Csv -path $path
    $Tableout = $Table + $temp
    $Tableout | Export-Csv $Path
}
function New-PsWriteAventailTable {
    <#
    .SYNOPSIS
        Data table convereted into html table with formatting  
    .DESCRIPTION
        Converts a dataTable into an html table with formatting and Javascript enabled. 
    .PARAMETER Table
        DataTable that contains all the relevant appliance information
    .PARAMETER Title
        String var for the title of the table, displayed centered above the table
    .INPUTS
        table & title both Required. table is a datatable object. Title is a string
    .OUTPUTS
        HTML table based off the data from table and title
    .EXAMPLE
        New-PsWriteAventailTable -table $table -title $title
    .Notes
        Author: Stephanie Seyler  
        Version: 1.2.0
        Date Created: 2020-03-19
        Date Modified: 2020-03-31
    #>
    param (
        [parameter(mandatory=$true,valueFromPipeline=$true)] $table,
        [parameter(mandatory=$true,valueFromPipeline=$true)] $title
    )
    $TableTemp = $table | Select-Object Time,Resource,ActiveUsers,CPU,Memory,Disk,Swap,Internal,External,TCP,HTTP
    $output = New-HTML -Online -AutoRefresh 300 {
        New-HTMLTable -DataTable $TableTemp { 
            New-HTMLTableHeader -Title $title -FontSize 24 -Color DarkOrange 
            New-HTMLTableHeader -Names 'Time','Resource','CPU','Memory','Disk','Swap','Internal','External','ActiveUsers',`
                'TCP','HTTP' -Title 'Historical Appliance Statistics'`
                -Alignment center -Color White -BackGroundColor 'DarkOrange'
        }
    }
    return($output)
}


# Create Environmental Variables that will be used throughout
$homepath = (split-path -path $PSScriptRoot) 
Set-Location -Path $homepath -PassThru
$errorCount = 0

try {
    $config = Get-Content '.\scripts\config.json' | Out-String | ConvertFrom-Json
}
catch {write-host "Failed to import global Config file. Please locate config file in scripts folder"}

# Create Logging
try {
    $dataLog = new-object System.IO.StreamWriter (($homepath + $config.Admin.logfilelocation)),`
    $true,(new-object System.Text.UTF8Encoding($true))
    if($null -eq (get-content -Path ($homepath + $config.Admin.logfilelocation))){
        $dataLog.WriteLine('"Date/Time","Action","Entry Type"')}
    $dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""BEGIN"",""Begin Logging""")
}
catch {$errorcount++}
try {
    # anonymous credentials are used to allow the script to email errors to admins.
    $anonCreds = New-Object System.Management.Automation.PSCredential("anonymous",`
        (ConvertTo-SecureString -String "anonymous" -AsPlainText -Force))
}
catch {$dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Error Log"",""failed to create anon creds""");`
    $errorcount++}

# Create Credentials list and test if credential objects already exist in defined location
# if non-existent create the files and check again.
try{    
    $credentialList = @()
    for($i=0;$i -lt $config.APITargets.length; $i++ ){
        $x = $config.APITargets[$i].credentialname
        $credentialList +=$x
    }
    foreach($item in $credentialList){
        $result = test-path -path ($item)
        if ($result -eq $true) {
            $dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Success Log"",""$item credential exists""")
        }
        else {
            GET-CREDENTIAL –Credential (Get-Credential) | EXPORT-CLIXML $item
            $result2 = test-path -path ($item)
            if ($result2 -eq $true) {
                $dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Success Log"",""$item credential created""")
            }
            else {
                exit(0)
            } 
        }
    }
}
Catch{}

try {
    $Hash =@{}
    foreach($var in $credentialList){
        $hash[$var] = (IMPORT-CLIXML $var).GetNetworkCredential().Password
    }   
}
catch {$dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Error Log"",""Failed to import creds"""); $errorcount++}

# Call SonicWall API using GET method. command uses the curl language to reach the api 
# curl must be installed on the server in order for these to be able to connect to the API 
# worth looking into another API call method, especially if moving away from SonicOS
try {
    for ($i = 0; $i -lt $config.APITargets.length; $i++) {
        $creds = $hash[$config.APITargets.credentialname[$i]] 
        $output = $config.APITargets.outputFile[$i]
        $URI = $entry.APITargets.targetURI[$i]
        #cmd.exe "/c curl -k -u "$creds" -X GET -o "$output" "$URI""
    }
    $dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Success Log"",""Succesful GET call of API for all Appliances""")
}
catch {$dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Error Log"",""Failed to reach API"""); $errorcount++}

# get content from Curl API call files and convert into a JSON object 
try {
    $SSLArray = @()
    for ($i = 0; $i -lt $config.APITargets.length; $i++) {
        $x =  get-content ($config.APITargets[$i].outputFile) | ConvertFrom-Json
        $SSLArray +=$x
    }
    $dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Success Log"",""Imported JSON Files""")
}
catch {$dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Error Log"",""Failed to Import JSON Files""");
     $errorcount++}

# Create DataTables to store Values
# Import previous table data to retain historical data
try {
    $TableHash = @{}
    $LineHash = @{}
    for ($i = 0; $i -lt $SSLArray.length; $i++) {
        $table = New-Object System.Data.Datatable
        New-AventailTable -table $table -SSL $SSLArray[$i] -Path $config.APITargets[$i].TableLocation
        $table = Import-Csv -path $config.APITargets[$i].TableLocation
        $TableHash[$config.APITargets[$i].ChartName] = New-PsWriteAventailTable -table $table `
             -title $config.APITargets[$i].ChartName | Out-String
        $dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Success Log"",""Created hashtable for $($config.APITargets[$i].ChartName)""")     
        $LineHash[$config.APITargets[$i].LineName] = $table.ActiveUsers | Select-Object -first 48
        $dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Success Log"",""Created DataTable for $($config.APITargets[$i].ChartName)""")
    }

    $bighash = @{}
    for ($i = 0; $i -lt $TableHash.Count; $i++) {
        $bighash["all"] += $TableHash[$config.APITargets[$i].ChartName]
        $dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Success Log"",""Assigned $($config.APITargets[$i].ChartName) to HashTable""")
    }

    # work on groupings
    <#
    $AmericasTotal = @()
    $EMEATotal = @()
    # Build total line for Americas users
    for($i=0;$i -lt 48;$i++){
        $hold = ($Chartdata01[$i]-as [int]) + ($Chartdata02[$i] -as [int])
        $AmericasTotal += $hold
    }
    #>
}
catch {$dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Error Log"",""Failed to Created DataTables""");
    $errorcount++}

# Create HTML Line Chart using Dashimo
try {
    $CHART = New-HTML -online {
        new-HTMLChart -Title $config.ChartAttributes.chartTitle -TitleAlignment $config.ChartAttributes.titleAlignment {
            # Define Chart axis and lines based on built data
            New-ChartAxisX -Name '0:00','-0:30', '-1:00', '-1:30', '-2:00', '-2:30', '-3:00', '-3:30', '-4:00', '-4:30',`
             '-5:00', '-5:30', '-6:00', '-6:30', '-7:00', '-7:30', '-8:00', '-8:30', '-9:00', '-9:30','-10:00','-10:30',`
             '-11:00', '-11:30', '-12:00', '-12:30', '-13:00', '-13:30', '-14:00', '-14:30', '-15:00', '-15:30', '-16:00',`
              '-16:30', '-17:00', '-17:30', '-18:00', '-18:30', '-19:00', '-19:30', '-20:00','-20:30', '-21:00', '-21:30',`
               '-22:00', '-22:30', '-23:00', '-23:30', '-24:00'
            for ($i = 0; $i -lt $LineHash.count; $i++) {
                New-ChartLine -Name $config.APITargets[$i].LineName -Value $LineHash[$config.APITargets[$i].LineName]
            }
        }
    }
    $chart = $chart |Out-String
    $dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Success Log"",""Created HTML Line Chart""")
}
catch {$dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Error Log"",""Failed to Created HTML Chart""");
     $errorcount++}

# Create Data for Header (H1-H3) of the HTML table
try {
    $totalUsers = 0
    for ($i = 0; $i -lt $SSLArray.Count; $i++) {
        $totalUsers += $SSLArray[$i].activeUserCount
    }
    $dateStamp = "[{0:yyyy/MM/dd} {0:HH:mm:ss K}]" -f (Get-Date) 
    $dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Success Log"",""Created HTML Header Values""")
}
catch {$dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Error Log"",""Failed to Created HTML Header Values""");
     $errorcount++}

# Build Final HTML Table and output the Value to $output
try {
    $body = ConvertTo-Html -PostContent $chart, $bighash["all"] -PreContent `
    "<h1>$($config.ReportAttributes.ReportHeader)</h1><h2>Total Current Users : $totalUsers</h2>`
    <h3>Current Time: $datestamp</h3>"`
    -Title $config.reportAttributes.ReportTitle
    $body | Out-File -FilePath $config.ReportAttributes.ReportOutput
    $dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Success Log"",""Built & Exported HTML Document""")
}
catch {$dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Error Log"",`
    ""Failed to Build & Exported HTML Document"""); $errorcount++}

# Notifies if current licensing is above defined threshold
try {
    if($totalUsers -gt $config.Admin.LicenseAlertNumber){ 
        Send-MailMessage -From $config.Admin.ErrorFromEmail -To $config.Admin.ErrorToEmail `
            -Subject 'VPN licensing is at alert threshold' -Credential $anonCreds `
            -SmtpServer $config.Admin.SMTPServer `
            -Body "Total current users $totalUsers at alert threshold"
        $dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Success Log"",""Sent Email for Surge License Americas""")
    }
}
catch {$dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Error Log"",""Failed to email about surge licensing""");
    $errorcount++}

# Sends an Email Alert that the script encountered an error (uses anonymous credentials)
try {
    if($errorcount -gt 0) {
        Send-MailMessage -From $config.Admin.ErrorFromEmai -To $config.Admin.ErrorToEmail `
            -Subject 'SonicWall Report Enountered an error' -Credential $anonCreds `
            -SmtpServer $config.Admin.SMTPServer -Body "Please review logs on VPN Report"
        $dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Success Log"",""Sent Email for error log DEV""")
    }
}
catch {$dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""Error Log"",""failed to send email for error log""")}

# Closing Data Logging file
$dataLog.writeLine("$(get-date -uformat '%Y%m%d %H%M%S'),""END"",""End Logging""")
$dataLog.Close()