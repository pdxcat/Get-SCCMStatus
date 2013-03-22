param(
    [string]$ComputerName
)
$arch = get-wmiobject win32_operatingsystem -computer $ComputerName  | select -ExpandProperty OSArchitecture
$HKLMPath = ""
$cutLine = 0
$cutLine = 2
if($arch -eq "64-bit"){
    $HKLMPath = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\SMS\Mobile Client\Software Distribution\Execution History\System"
    $cutLine = 9
}else{
    $HKLMPath = "HKLM:\Software\Microsoft\SMS\Mobile Client\Software Distribution\Execution History\System"
    $cutLine = 8
}

function get-{
    $list = Invoke-Command -ComputerName $ComputerName  -scriptblock {
        param($regpath)
        $PackageID = Get-ChildItem $regpath | select -ExpandProperty name | foreach{$_.split('\')[9]}
        
        foreach($PKID in $PackageID ){
        
        $GUID = Get-ChildItem $regpath\$PKID | select -ExpandProperty name | foreach{$_.split('\')[10]}
        
            foreach($GID in $GUID){
                $APPInfo = Get-ItemProperty $regpath\$PKID\$GID 
                $APPInfo | Add-Member -type NoteProperty -Name PKID -Value $PKID
                $appInfo
            }
        }
    } -ArgumentList $HKLMPath | select PKID,_ProgramID,_State,_RunStartTime,SuccessOrFailureCode,SuccessOrFailureReason
    return $list
}


function format-output{
     param(
        [object]$list
     )
      $PKIDFormat = @{Expression={$_.PKID};Label="PackageID";width=12}
      $ProgramFormat = @{Expression={$_._ProgramID};Label="Program";width=45}
      $StateFormat = @{Expression={$_._State};Label="State";width=10}
      $StartFormat = @{Expression={$_._RunStartTime};Label="Start Time";width=20}
      $ExitFormat = @{Expression={$_.SuccessOrFailureCode};Label="Exit Code";width=9}
      $ReasonFormat = @{Expression={$_._SuccessOrFailureReason};Label="Reason"}
      $list | Format-Table $PKIDFormat,$ProgramFormat,$StateFormat,$StartFormat,$ExitFormat,$ReasonFormat
}

$list = get-64bit
format-output $list