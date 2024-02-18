

# Invoke-DbaQuery -SqlInstance nin8\sql2019 -Database gLate -
push-location $PSScriptRoot
impo (Join-Path $PSScriptRoot './MonkeyData/MonkeyData.psd1') -PassThru -Force -ea 'stop'
MonkeyData.GetDb|ft -AutoSize

$db = MonkeyData.GetDb
$db[0].QueryStoreOptions | % Properties|ft

$db | MonkeyData.SummarizeObjType Smo.Database | ft

Dotils.QuickGcm.ByPrefix -Pattern 'MonkeyData.*'
MonkeyData.GetDb | MonkeyData.SummarizeObj Smo.Database | ft
