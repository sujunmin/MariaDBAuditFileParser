$AuditDBServer = "." # AuditDB server name
$AuditDB = "AuditDB" # AuditDB name
$TraceFileData = "auditdata" # Table name that saves trace data
$AuditDBUserName = "username" # Can access AuditDB username,
$AuditDBPassword = "password"
$mysqlexe = "D:\Program Files\MariaDB 10.1\bin\mysql.exe" # Collect audit files from $FromDirs
$FromDirs = "D:\AuditFile\LAND-MARIADBCS1", "D:\AuditFile\LANDDBBK-M" #mysql.exe path
$SaveFileDir = "D:\AuditFile\SavedData"  # Audit files save to
$Users = "sujunmin","rita","gaia","joan" # Need to save into database
$MailFrom = "from@abc.com" # Mail from
$MailTo = "to@def.com" # Rcpt To
$MailServer = "smtp.server" # Mail server

$DXL = [System.Collections.ArrayList] @()

$FromDirs | Foreach-Object {
	Get-ChildItem $_ -Filter "AuditData.*" | Foreach-Object {
		try { 
			
			If( -Not (Test-Path ("$SaveFileDir\" + ('{0:yyyy-MM-dd}' -f (get-childitem $_.FullName).creationtime)))) {
				New-Item -Path "$SaveFileDir" -name "$('{0:yyyy-MM-dd}' -f (get-childitem $_.FullName).creationtime)" -type Directory
			}

			$auditfilecontent = [IO.File]::ReadAllText($_.FullName)



			$matches = ([regex] '(\d{4})(\d{2})(\d{2}) (\d{2}):(\d{2}):(\d{2}),').Matches($auditfilecontent)




			for($i=0; $i -lt $matches.Count; $i++)
 
			{
  
  				$line = ""

  
  				if($i -eq $matches.Count -1)
  
   				{
	
     					$line = $auditfilecontent.SubString($matches[$i].Index, $auditfilecontent.length - $matches[$i].Index)

  
   				}else 
  
    				{
	
     					$line = $auditfilecontent.SubString($matches[$i].Index, $matches[$i+1].Index - $matches[$i].Index)
  
    				}
  
  
   				$submatches = ([regex] ',').Matches($line)  
   				$timestamp    = $line.SubString(0, $submatches[0].Index)
  
   				$serverhost   = $line.SubString($submatches[0].Index+1, $submatches[1].Index - $submatches[0].Index-1)
  
   				$username     = $line.SubString($submatches[1].Index+1, $submatches[2].Index - $submatches[1].Index-1)
  
   				$hosts        = $line.SubString($submatches[2].Index+1, $submatches[3].Index - $submatches[2].Index-1)
  
   				$connectionid = $line.SubString($submatches[3].Index+1, $submatches[4].Index - $submatches[3].Index-1)
  
  				$queryid      = $line.SubString($submatches[4].Index+1, $submatches[5].Index - $submatches[4].Index-1)
  
   				$operation    = $line.SubString($submatches[5].Index+1, $submatches[6].Index - $submatches[5].Index-1)
  
   				$database     = $line.SubString($submatches[6].Index+1, $submatches[7].Index - $submatches[6].Index-1)
   				if ($submatches[$submatches.Count-1].Index - $submatches[7].Index- 3 -lt 0) 
   				{
     				      $object = ""
   				}else
    				{
     				      $object = $line.SubString($submatches[7].Index+2, $submatches[$submatches.Count-1].Index - $submatches[7].Index-3)
  
    				}
   				$retcode      = $line.SubString($submatches[$submatches.Count-1].Index+1,$line.length - $submatches[$submatches.Count-1].Index-1).Trim()
 
  

				if ($Users -contains $username)
				{
					$sql = "INSERT INTO " + $AuditDB + "." + $TraceFileData + " VALUES (STR_TO_DATE('" + $timestamp + "','%Y%m%d %H:%i:%S'), '" + $serverhost + "', '" + $username + "', '" + $hosts + "', '" + $connectionid + "', '" + $queryid + "', '" + $operation + "', '" + $database + "', '" + $object + "', '" + $retcode +"');"	
					& $mysqlexe -u $AuditDBUserName --password=$AuditDBPassword -h $AuditDBServer  -e "$($sql)" 
				}

				if ($MailEventClasses -contains $operation)
				{
					$DXL.Add(($timestamp, $serverhost, $username, $hosts, $connectionid, $queryid, $operation, $database, $object, $retcode))
				}
				
				
			}


			$outfile = "$SaveFileDir\" + ('{0:yyyy-MM-dd}' -f (get-childitem $_.FullName).creationtime) + "\" + (get-date -UFormat %s) + ".log"
			Move-Item $_.FullName $outfile			
		} catch {}
	}
}

if ($DXL.Count -ne 0)
{
	$output = "<table border=1 style=border-width: thin; border-spacing: 2px; border-style: solid; border-color: gray; border-collapse: collapse;>  
                 <tr><th>StartTime</th>
		     <th>LoginName</th>
	             <th>HostName</th>
		     <th>ServerName</th>
	             <th>DatabaseName</th>
	             <th>Operation</th>
                     <th>TextData</th>
                     <th>ReturnCode</th></tr>"

        $DXL | Foreach-Object {

		$output = $output + "<tr><td>" + $_[0] + "</td><td>" +  $_[2] + "</td><td>" + $_[3] + "</td><td>" + $_[1] + "</td><td>" + $_[7] + "</td><td>" + $_[6] + "</td><td>" + $_[8] + "</td><td>" + $_[9] + "</td></tr>"
	}

	$output = $output + "</table>"
	Send-MailMessage -To $MailTo -From $MailFrom -Subject "資料庫特權活動即時告警" -Body "$output" -BodyAsHtml -SmtpServer $MailServer -Encoding ([System.Text.Encoding]::UTF8)		
}
