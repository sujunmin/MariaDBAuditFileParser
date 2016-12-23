# MariaDBAuditFileParser
MariaDB Audit File Parser on Windows

## Prerequisite
* MariaDB
* Powershell
* Permissions

## How to use
1. Build Database `$AuditDB`.
2. Build Table `$TraceFileData` in `$AuditDB` by using `AuditDB.sql`.
3. Set up arguments in `TraceFileParser.ps1`.
4. Run and Test.
5. Use `SaveTraceFile.ps1` to save data into files.
