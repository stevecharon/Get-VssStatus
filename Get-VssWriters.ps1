function Get-VSSWriters ([switch]$verbose) {
     <#
    .Synopsis
       Performs VSSAdmin list writers
    .DESCRIPTION
       Gets the VSS Writers and outputs it as a object.
    .EXAMPLE
       Get-VSSWriters
    .NOTES
       Uses regex to get the information and then splits it into objects.
       Extend the Culture region if use anything beyond german or english or make sure to run in these Cultures
       otherwise your result will be empty
    #>
    Begin {
    #stolen from https://devblogs.microsoft.com/scripting/use-powershell-to-write-verbose-output/
    if ($verbose){
	$oldverbose = $VerbosePreference
	$VerbosePreference = "continue"
	}
    #region Culture
	$cult=(get-culture).Name
	switch ($cult){
	"de-DE" { 
		$writertext="Verfassername:" 
		$writerid="Verfasserkennung:"
		$writerinstance="Verfasserinstanzkennung:"
		$writerstate="Status:"
		$writerlasterr="Letzter Fehler:"
		$noerrortext="Kein Fehler"
	    }
	Default { 
		$writertext="Writer name:" 
		$writerid="Writer Id:"
		$writerinstance="Writer Instance Id:"
		$writerstate="State:"
		$writerlasterr="Last error:"
		$noerrortext="no error"
	    }
	}
	#endregion Culture
	[string]$vssWriters = (&vssadmin list writers) | Out-String
	#Regex to findthe first line and then its proceeding 4 lines
	$regex = [regex]::matches($vssWriters, "($writertext.*\n.*\n.*\n.*\n.*)")
	$vssObject = @()
	$VSSOutput = @()
	$VSS = @()

    }

    Process {
	#loop thought the regex matches and split them into their properties.
	foreach($value in $regex.value){
	Write-verbose $value
	$vssObject = New-Object PSCustomObject -Property([ordered]@{
	    WriterName = ([regex]::Match($value,"$writertext (.*)")).groups[1].value
	    WriterId = ([regex]::Match($value,"$writerid (.*)")).groups[1].value
	    WriterInstanceId = ([regex]::Match($value,"$writerinstance (.*)")).groups[1].value
	    State = [int](([regex]::Match($value,"$writerstate \[(.*)\]")).groups[1].value)
	    StateInfo = ([regex]::Match($value,"$writerstate \[(\d*)\] (.*)")).groups[2].value
	    LastError = ([regex]::Match($value,"$writerlasterr (.*)")).groups[1].value
	})
	$VSSOutput += $vssObject
}
    }

    End {
	$VerbosePreference = $oldverbose
	$VSSOutput
    }
}
$result=get-vsswriters
[int]$errcount= ($result.lasterror -notmatch "$noerrortext"|measure).count
if ($errcount -ne 0){$Text="Fehler in einem VSS Writer gefunden"}else{$Text="Alle VSS Writer sind ok"}
$Count =$result.Count 

#region XML Output for PRTG
Write-Host "<prtg>" 
Write-Host "<result>"
	       "<channel>All VSS Writers</channel>"
	       "<value>$Count</value>"
	   "</result>"
	       "<text>$Text</text>"

foreach ($writer in $result){
    $writername=$writer.writername
    $writerstate=$writer.state
    if ($writerstate -ne 1){$info=$writer.StateInfo 
	$lasterr=$writer.LastError
	$Text="$($Writername): Status: $info - Last Error: $lasterr"
	}
	       Write-Host "<result>"
	       "<channel>$writername</channel>"
	       "<value>$writerstate</value>"
	       "</result>"
	      
	       }

Write-Host "</prtg>" 
#endregion