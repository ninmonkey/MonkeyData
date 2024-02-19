goto $PSScriptRoot
Impo DbaTools -PassThru
<#
see also:
- https://blog.netnerds.net/2023/03/new-defaults-for-sql-server-connections-encryption-trust-certificate/
- https://docs.dbatools.io/Export-DbaScript
#>

# $Inst ??= Test-DbaConnection -SqlInstance 'NIN8\SQL2019'
# $inst | select *Name*, *inst*, IP*, *Port*, *version* -ea 'ignore'|ft



function Db.UseLocalTrustCert {
    param()
    <#
    # Set defaults just for this session
        Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true
        Set-DbatoolsConfig -FullName sql.connection.encrypt -Value $false

        # Set these defaults for all future sessions on this machine
        Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true -Register
        Set-DbatoolsConfig -FullName sql.connection.encrypt -Value $false -Register

    #>
    'Enabling session config: Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true'
        | write-host -fore 'magenta'

    Set-DbatoolsConfig -FullName sql.connection.trustcert -Value $true

}
function Db.TryAutoSetCert {
    # try setting existing
    param(
        [switch]$LocalHostOnly
    )
    # Get-DbaComputerCertificate | Out-GridView -PassThru
    # [Security.Cryptography.X509Certificates.X509Certificate2]|fime
    $selected = Get-DbaComputerCertificate -ComputerName $Inst.ComputerName
        | ? DnsNameList -Contains 'localhost'
        | ? Name -Match 'IIS Express Development Certificate'

    Set-DbaNetworkCertificate -SqlInstance $inst.SqlInstance -Thumbprint $selected.Thumbprint
}
function Db.GetCerts {
    # show dba certs
    param(
        [switch]$LocalHostOnly
    )
    if($LocalHostOnly) {
        return @( Get-DbaComputerCertificate -ComputerName $Inst.ComputerName
        | ? DnsNameList -Contains 'localhost' )
    }

    Get-DbaComputerCertificate -ComputerName $Inst.ComputerName
}
function Db.WhoAmi {
    # localhost sandbox
    param()
    $state = $script:Inst
    if($false) {
        if(-not $State) { 'try defaults..' | write-host -fore blue}
        $state ??= Test-DbaConnection -SqlInstance 'NIN8\SQL2019'
        $state | select *Name*, *inst*, IP*, *Port*, *version* -ea 'ignore'
            |ft -auto | out-string | write-host
    }

    return $state
}
# Get-DbaAgentJob -SqlInstance $Inst.SqlInstance -Verbose |  Export-DbaScript -Verbose
function Db.TryGetTable {
    param()
    $splatTable = @{
        SqlInstance   = $inst.SqlInstance
        Database      = 'BikeStores'
        # SqlCredential = $Cred
        Table         = 'sales.stores'
        # Schema        = 'schema', 'dbo'
        # InputObject   = ..
    }

    Get-DbaDbTable @splatTable
}

Dotils.QuickGcm.ByPrefix -Pattern 'db.*'
hr
Db.UseLocalTrustCert
Db.TryGetTable

$Env:ConnString ??= Get-Secret -Name 'GitLogger.SqlAzureConnectionString' -AsPlainText
