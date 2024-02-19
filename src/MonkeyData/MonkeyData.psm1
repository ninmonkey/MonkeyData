$script:AppState = @{
    Defaults = @{
        SqlInstanceName = '{0}\{1}' -f @(
            $Env:ComputerName
            $Env:MonkeyDataDefaultSqlInstance ?? 'sql2019'
        )
        ComputerName = $Env:ComputerName
        DatabaseName = 'master' # 'BikeStores'
        InstanceName = $Env:MonkeyDataDefaultSqlInstance ?? 'sql2019'
        SchemaName = 'dbo' # 'sales'
        TableName = 'Customers' # 'AdventureWorks'
    }
}
function Get-DefaultValueFor {
    # internal defaults, wrapper
    param(
        [Parameter(Mandatory, Position = 0)]
        [ArgumentCompletions(
            'SqlInstanceName', 'InstanceName', 'DatabaseName',
            'SchemaName', 'TableName', 'ComputerName'
        )]
        [string]$KeyName
    )
    $state = $script:AppState.Defaults

    if( -not $state.Contains($KeyName) ) {
        throw "Get-DefaultValueFor: InvalidKeyNameException: Key does not exist: $KeyName"
    }
    return $script:AppState.Defaults[ $KeyName ]
}
# Get-DbaDatabase nin8\sql2019|ft
# $Script:md_Completions = @{
#     DbaTable = MonkeyData.GEtDb | % Name | sort-Object -unique
# }

$script:AppState.Defaults | ConvertTo-Json -Depth 5
    | Join-String -op 'AppState.Defaults[json] = ' | write-verbose

function MonkeyData.Get-Database {
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
        'MonkeyData.GetDatabase',
        'MonkeyData.ListDatabase',
        'MonkeyData.GetDb',
        'md.GetDb'
        # 'md.ListDb'
    )]
    param(
        # SqlInstance, ex: 'nin8\sql2019'
        [Parameter()]
            [Alias('SqlInstance', 'Inst')]
            [Dataplat.Dbatools.Parameter.DbaInstanceParameter[]]
            $DbInstance = @( Get-DefaultValueFor 'SqlInstanceName' )
    )

    Get-DbaDatabase $DbInstance
}

function MonkeyData.Get-DbaToolsCache {
    <#
    .SYNOPSIS
        get internal cache used for building SqlInstance completions
    .NOTES
        uses internal class, assume this is fragile
    #>
    [CmdletBinding()]
    [OutputType('hashtable')]
    param()
    [Dataplat.Dbatools.TabExpansion.TabExpansionHost]::Cache | % Keys
        | Sort-Object -Unique
        | Join-string -sep ', ' -op 'Dbatools.TabExpansion key names: '
        | Write-Verbose

    [Dataplat.Dbatools.TabExpansion.TabExpansionHost]::Cache | % GetEnumerator
        | ?{ $_.Value.keys.count -gt 0 } | % Name
        | Sort-object -Unique
        | Join-String -sep ', ' -op 'Non Empty Key names: '
        | Write-Verbose

    return [Dataplat.Dbatools.TabExpansion.TabExpansionHost]::Cache
}

function MonkeyData.Try-AcceptLocalhostCert {
    <#
    .SYNOPSIS
        Use localhost cert for SqlServer 2019 rather than disabling encryption, see links
    .NOTES
        # Set defaults just for this session
        Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true
        Set-DbatoolsConfig -FullName sql.connection.encrypt -Value $false

        # Set these defaults for all future sessions on this machine
        Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true -Register
        Set-DbatoolsConfig -FullName sql.connection.encrypt -Value $false -Register

    .LINK
        https://blog.netnerds.net/2023/03/new-defaults-for-sql-server-connections-encryption-trust-certificate/
    .LINK
        https://docs.dbatools.io/Export-DbaScript
    .LINK
        MonkeyData.Try-AcceptLocalhostCert
    .LINK
        MonkeyData.Get-LocalCerts
    #>
    # try setting existing
    [CmdletBinding(ConfirmImpact='high', SupportsShouldProcess)]
    param(
        [Parameter()]
            [Alias('SqlInstance', 'Inst')]
            [Dataplat.Dbatools.Parameter.DbaInstanceParameter[]]
            $DbInstance = @( Get-DefaultValueFor 'SqlInstanceName' ),

        [switch]$AlwaysAccept,

        # ex: nin8
        [Parameter()]
            [string]$ComputerName = (Get-DefaultValueFor 'ComputerName')
    )
    'Enabling session config: Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true'
        | write-host -fore 'magenta'
    'Enabling session config: Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true'
        | write-warning

    if($AlwaysAccept) { Write-Verbose 'Try-AcceptLocalhostCert: -AlwaysAccept: True'}

    if ($AlwaysAccept -or $PSCmdlet.ShouldProcess("Set-DbatoolsConfig for sql.connection.trustcert", "Set value to true")) {
        Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true
    }

    $selected = MonkeyData.Get-LocalCerts -ComputerName $ComputerName
        | ? Name -Match 'IIS Express Development Certificate'

    $selected | Join-String -op 'Try-AutoSetCert: ' -Property {
            $_  | Select -Property ComputerName, Store, Folder, Name, DnsNameList
                | ConvertTo-Json -Depth 2 -Compress
        } | Write-Verbose

    Set-DbaNetworkCertificate -SqlInstance $SqlInstance -Thumbprint $selected.Thumbprint
}
function MonkeyData.Get-LocalCerts {
    <#
    .SYNOPSIS
        show locahost cert, SqlServer 2019, use certs if existing rather than disabling encryption, see links
    .LINK
        https://blog.netnerds.net/2023/03/new-defaults-for-sql-server-connections-encryption-trust-certificate/
    .LINK
        https://docs.dbatools.io/Export-DbaScript
    .LINK
        MonkeyData.Try-AcceptLocalhostCert
    .LINK
        MonkeyData.Get-LocalCerts
    #>
    [OutputType( [Management.Automation.PSObject] )]
    param(
        [Parameter()]
        [string]$ComputerName = $Env:COMPUTERNAME
    )

    return Get-DbaComputerCertificate -ComputerName $ComputerName
        | ? DnsNameList -Contains 'localhost'
}

function MonkeyData.Invoke-NamedQuery  {
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
        'MonkeyData.InvokeNamedQuery',
        'MonkeyData.InvokeNamed',
        'md.InvokeNamedQuery'
    )]
    param(
        [Parameter(Mandatory, Position=0)]
            [ValidateSet(
                'system_objects',
                'DbaTools.GetTables' )]
            [string]$NamedQuery,


        [Parameter()]
            [hashtable]$Params = @{},

        # SqlInstance, ex: 'nin8\sql2019'
        [Parameter()]
            [Alias('SqlInstance', 'Inst')]
            [Dataplat.Dbatools.Parameter.DbaInstanceParameter[]]
            $DbInstance = @( Get-DefaultValueFor 'SqlInstanceName' ),


        [Parameter()]
            [Alias('DbName')]
            [string]
            $Database = (Get-DefaultValueFor 'DatabaseName') # or use none?
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

function MonkeyData.Summarize-ObjectType  {
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
        'MonkeyData.SummarizeObjectType',
        'MonkeyData.SummarizeType',
        'MonkeyData.SummarizeObjType',
        'MonkeyData.SummarizeObj',
        'md.Summarize-ObjectType',
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
