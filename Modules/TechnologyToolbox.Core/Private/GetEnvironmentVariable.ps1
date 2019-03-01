function GetEnvironmentVariable() {
    Param(
        [string] $Variable,
        [EnvironmentVariableTarget] $Target = "Process")

    return [Environment]::GetEnvironmentVariable(
        $Variable,
        $Target)
}