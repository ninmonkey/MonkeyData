# if($ScriptConf){ $ScriptConf.FirstLoad = $false }
$script:ScriptConf ??= @{
    FirstLoad = $true
}
# Invoke-DbaQuery -SqlInstance nin8\sql2019 -Database gLate -
push-location $PSScriptRoot
impo (Join-Path $PSScriptRoot './MonkeyData/MonkeyData.psd1') -PassThru -Force -ea 'stop'
MonkeyData.GetDb|ft -AutoSize
$db = MonkeyData.GetDb
# $db[0].QueryStoreOptions | % Properties|ft
if($ScriptConf.FirstLoad) {
    $SCriptConf.FirstLoad = $false
    $db | MonkeyData.SummarizeObjType Smo.Database | ft
}

Dotils.QuickGcm.ByPrefix -Pattern 'MonkeyData.*'
