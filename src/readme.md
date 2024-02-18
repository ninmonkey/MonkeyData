- [ ] SqlInstance completion
- [ ] disable default formatter attributes for `Microsoft.SqlServer.Management.Smo.Table`
  - [ ] is that DbaTools or pipe?


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