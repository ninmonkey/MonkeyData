# Get-DbaDatabase nin8\sql2019|ft


function MonkeyData.GetDatabase {
    <#
    .SYNOPSIS
        summary of DbInstance
    .example
        MonkeyData.GetDb | select -First 1
            | MonkeyData.SummarizeType Smo.Database
    #>
    [OutputType('Microsoft.SqlServer.Management.Smo.Database')]
    [CmdletBinding()]
    [Alias(
        'MonkeyData.ListDatabase',
        'MonkeyData.GetDb',
        'md.GetDb',
        'md.ListDb'
    )]
    param(
        [Alias('SqlInstance', 'Inst')]
        [DbaInstanceParameter[]]$DbInstance = @('nin8\sql2019')
    )

    Get-DbaDatabase $DbInstance
}

function MonkeyData.SummarizeObjectType  {
    <#
    .SYNOPSIS
        summary of objects, shorten property list. could be a view
    .example
        MonkeyData.GetDb | select -First 1
            | MonkeyData.SummarizeType Smo.Database
    #>
    [OutputType('Microsoft.SqlServer.Management.Smo.Database')]
    [CmdletBinding()]
    [Alias(
        'MonkeyData.SummarizeType',
        'MonkeyData.SummarizeObjType',
        'MonkeyData.SummarizeObj',
        'md.SummarizeObjectType',
        'md.SummarizeObjType',
        'md.SummarizeObj'
    )]
    param(
        [Parameter(Mandatory, Position=0)]
        [ValidateSet(
            'Smo.Database'
        )]
        [string]$Kind,

        [Parameter(Mandatory, ValueFromPipeline)]
        $InputObject

    )
    process {
        $Obj = $InputObject

        switch($Kind) {
            'Smo.Database' {
                [Microsoft.SqlServer.Management.Smo.Database]$Db = $InputObject
                # $Db | Select-object -Property Query

                $Obj | Select-Object -prop @(
                    'ComputerName',
                    'InstanceName',
                    'SqlInstance',
                    'Name',
                    'Status',
                    'SizeMB',
                    'Compatibility',
                    'QueryStoreOptions',
                    'Collation',
                    'Encrypted',
                    'Last*Backup'
                )
            }
            default { throw "UnhandledTypeName: $Kind"}
        }
    }

}

# update-typedata -DefaultDisplayPropertySet
