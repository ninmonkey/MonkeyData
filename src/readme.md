- [ ] SqlInstance completion
- [ ] disable default formatter attributes for `Microsoft.SqlServer.Management.Smo.Table`
  - [ ] is that DbaTools or pipe?

### Completion locations

- [Connect-DbaInstance.ps1](https://github.com/dataplat/dbatools/blob/419963993aadae04914b8686641b251f2a558be3/public/Connect-DbaInstance.ps1#L1044-L1059) from: [discord thread](https://discord.com/channels/180528040881815552/800214699463409704/1209041652442996796)
> It is in the `dbatools.library`.  
> It is built into `[Dataplat.Dbatools.TabExpansion.TabExpansionHost]`
> It is built up around how PSFramework was built too I think by Fred. 
> You can see entry points in `Connect-DbaInstance`.
> https://github.com/dataplat/dbatools/blob/419963993aadae04914b8686641b251f2a558be3/public/Connect-DbaInstance.ps1#L1044-L1059

## SqlInstance name to Complete DatabaseName

```ps1
Dbatools\Get-DbaDatabase -SqlInstance nin8\sql2019 | % Name
```

## speed issue

I thought some queries were just slow, but no.
It's a super-expensive property formatter that's slowing things down.


```ps1
MonkeyData.InvokeNamed -NamedQuery DbaTools.GetTables| ft Database, Name, SqlInstance
MonkeyData.InvokeNamed -NamedQuery DbaTools.GetTables| ft 

# Microsoft.SqlServer.Management.Smo.Table

# offending type name is [Microsoft.SqlServer.Management.Smo.Table]

> Dotils.Measure.CommandDuration -Expression { MonkeyData.InvokeNamed -NamedQuery DbaTools.GetTables| ft Database, Name, SqlInstance }
# Duration   : 00:00:00.1700078
# DurationMs : 170.0078

> Dotils.Measure.CommandDuration -Expression { MonkeyData.InvokeNamed -NamedQuery DbaTools.GetTables| ft  } 
# Duration   : 00:00:06.3551481
# DurationMs : 6355.1481
```

## Parameter templates

```ps1
# [type] SqlInstance, ex: 'nin8\sql2019'
[Parameter()]
    [Alias('SqlInstance', 'Inst')]
    [Dataplat.Dbatools.Parameter.DbaInstanceParameter[]]
    $DbInstance = @( Get-DefaultValueFor 'SqlInstanceName' ),


# [type] DBInstance From commands
[Parameter()]
    [Microsoft.SqlServer.Management.Smo.Database[]]
    $DbInstanceObject

# [type]
[Parameter()]
    [Dataplat.Dbatools.Parameter.DbaInstanceParameter[]]
    $DbParameter

# [type] # ex: nin8
[Parameter()]
    [string]$ComputerName = (Get-DefaultValueFor 'ComputerName')

```

