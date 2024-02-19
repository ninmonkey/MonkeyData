<#
see more:
.LINK
    https://docs.dbatools.io/Invoke-DbaQuery
#>
# if($ScriptConf){ $ScriptConf.FirstLoad = $false }
$script:ScriptConf ??= @{
    FirstLoad = $true
}
# Invoke-DbaQuery -SqlInstance nin8\sql2019 -Database gLate -
push-location $PSScriptRoot
impo (Join-Path $PSScriptRoot './MonkeyData/MonkeyData.psd1') -PassThru -Force -ea 'stop'

MonkeyData.Try-AcceptLocalhostCert -AlwaysAccept
MonkeyData.GetDb|ft -AutoSize
$db = MonkeyData.GetDb
# $db[0].QueryStoreOptions | % Properties|ft
if($ScriptConf.FirstLoad) {
    $SCriptConf.FirstLoad = $false
    $db | MonkeyData.SummarizeObjType Smo.Database | ft

    dbatools\Connect-DbaInstance -SqlInstance 'nin8\sql2019'
}

Dotils.QuickGcm.ByPrefix -Pattern 'MonkeyData.*'

Invoke-dbaquery -SqlInstance nin8\sql2019 -Database BikeStores -Query @'
select q.* from sys.system_objects as q
'@|ft
