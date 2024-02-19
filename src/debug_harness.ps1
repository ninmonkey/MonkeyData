<#
see more:
.LINK
    https://docs.dbatools.io/Invoke-DbaQuery
#>
# if($ScriptConf){ $ScriptConf.FirstLoad = $false }
$script:ScriptConf ??= @{
    FirstLoad = $true
}
function QuickGcm.ByPrefix {
    param( [string]$Pattern )
    return $ExecutionContext.InvokeCommand.GetCommands( $Pattern, 'all', $true )
         | Format-Table -AutoSize Name, CommandType, Visibility # , Parameters # ParameterSets
}
Import-Module DbaTools -PassThru
push-location $PSScriptRoot

Import-Module (Join-Path $PSScriptRoot './MonkeyData/MonkeyData.psd1') -PassThru -Force -ea 'stop'

MonkeyData.Try-AcceptLocalhostCert -AlwaysAccept
# dbatools\Connect-DbaInstance -SqlInstance 'nin8\sql2019'

$db = MonkeyData.GetDb
$db | Format-Table -AutoSize

# $db[0].QueryStoreOptions | % Properties|ft
if($ScriptConf.FirstLoad) {
    $ScriptConf.FirstLoad = $false
    $db | MonkeyData.Summarize-ObjType Smo.Database | Format-Table
}

QuickGcm.ByPrefix -Pattern 'MonkeyData.*'

# Invoke-DbaQuery -SqlInstance nin8\sql2019  -Query 'select top @TopN q.* from sys.system_objects as q' -SqlParameter @(
#     New-DbaSqlParameter -DbType Int32 -ParameterName 'TopN' -Value 3
# )
