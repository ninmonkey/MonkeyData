# Get-DbaDatabase nin8\sql2019|ft

# $Script:md_Completions = @{
#     DbaTable = MonkeyData.GEtDb | % Name | sort-Object -unique
# }

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



function MonkeyData.InvokeNamedQuery  {
    <#
    .SYNOPSIS
        invoke named queries
    .example
        MonkeyData.InvokeNamedQuery | select -First 1
            | MonkeyData.SummarizeType Smo.Database
    #>
    # [OutputType('Microsoft.SqlServer.Management.Smo.Database')]
    [CmdletBinding()]
    [Alias(
        'MonkeyData.InvokeNamed',
        'md.InvokeNamedQuery'
    )]
    param(
        [Parameter(Mandatory, Position=0)]
        [ValidateSet(
            'system_objects',
            'DbaTools.GetTables'
        )]
        [string]$NamedQuery,
        [hashtable]$Params = @{},

        [Alias('SqlInstance', 'Inst')]
        [Parameter()]
        [Dataplat.Dbatools.Parameter.DbaInstanceParameter[]]
        $DbInstance = @('nin8\sql2019'),
        # [DbaInstanceParameter[]]$DbInstance = @('nin8\sql2019'),

        [Parameter()]
        [Microsoft.SqlServer.Management.Smo.Database[]]
        $Database

    )
    switch($NamedQuery) {
        'DbaTools.GetTables' {
            DBaTools\Get-DbaDbTable -SqlInstance $DbInstance
        }
        'system_objects' {
$queryStr = @'
select * from sys.system_objects
'@
            $invokeDbaQuerySplat = @{
                SqlInstance = $DbInstance
                Database    = $Database ?? 'BikeStores'
                Query       = $queryStr
            }

            Invoke-DbaQuery @invokeDbaQuerySplat

        }
        default { throw "UnhandledNameQuery: $NamedQuery"}
    }
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
        $InputObject,

        [switch]$WithoutCalculatedProps

    )
    process {
        $Obj = $InputObject

        switch($Kind) {
            'Smo.Database' {
                [Microsoft.SqlServer.Management.Smo.Database]$Db = $InputObject
                # $Db | Select-object -Property Query

                $newObj = $Obj | Select-Object -ea 'ignore' -prop @(
                    'Owner',
                    'Name',
                    'SqlInstance',
                    'ServerVersion',

                    'SpaceAvailable'
                    'CompatibilityLevel'
                    'Status',
                    'SizeMB',
                    'Version'
                    'UserName'
                    'LogFiles',

                    'PrimaryFilePath'
                    'Compatibility',
                    'QueryStoreOptions',
                    'Collation',
                    'Encrypted',
                    'Last*Backup',
                    '*Name*',
                    '*Options*',
                    'Tables',
                    'StoredProcedures','UserDefined*',
                    'Assemblies','ExternalLanguages','ExternalLibraries',
                    'DatabaseScopedConfigurations'
                    'UserDefinedFunctions'
                    'ExtendedStoredProcedures'
                    'Views', 'Users'
                    'Schemas',
                    'Partition*'
                    'ServiceBroker'
                    'ComputerName', # redundant with [SqlInstance]
                    'InstanceName', # redundant with [SqlInstance]
                    'Collation'
                    'ReadOnly'
                    'DefaultLanguage'
                    'Size' # redundant With [SizeMB]
                )
                $newProps = [ordered]@{
                    md_Func       = $Db | Select-Object -prop '*Functions*' -ea 'ignore'
                    md_Procedures = $Db | Select-Object -prop '*StoredProcedures*' -ea 'ignore'
                    md_Props      = $Db.Properties
                    md_Tables     = $Db | Select-Object -prop '*Tables*' -ea 'ignore'
                    md_Views      = $Db | Select-Object -prop '*Views*' -ea 'ignore'
                    md_Is         = $DB | select-object -property 'Is*' -ea 'ignore'
                    md_Names      = $DB | select-object -property '*Name*' -ea 'ignore'
                    md_Versions   = $DB | select-object -property '*Version*' -ea 'ignore'
                    md_Date       = $DB | select-object -property '*Date*' -ea 'ignore'

                    Props         = $Db.Properties
                }
                $addMemberSplat = @{
                    ErrorAction         = 'ignore'
                    Force               = $true
                    NotePropertyMembers = $newProps
                    PassThru            = $true
                    TypeName            = 'MonkeyData.Smo.Database.Summary'
                }

                if($WithoutCalculatedProps) {
                    $newObj
                    break
                }

                $NewObj | Add-Member @addMemberSplat
                break

            }
            default { throw "UnhandledTypeName: $Kind"}
        }
    }

}

# update-typedata -DefaultDisplayPropertySet
