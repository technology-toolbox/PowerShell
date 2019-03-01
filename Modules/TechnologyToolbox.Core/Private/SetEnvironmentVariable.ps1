function SetEnvironmentVariable() {
    Param(
        [string] $Variable,
        [string] $Value,
        [EnvironmentVariableTarget] $Target = "Process")

    [Environment]::SetEnvironmentVariable($Variable, $Value, $Target)
}