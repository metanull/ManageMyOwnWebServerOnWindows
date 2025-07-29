@{
    # PSScriptAnalyzer configuration for MetaNull.LaravelUtils module
    
    # Rules to exclude project-wide
    ExcludeRules = @(
        # 'PSAvoidUsingWMICmdlet',        # We use WMI for compatibility with existing tests and broad system support
        # 'PSAvoidUsingWriteHost',        # Write-Host is used in development utilities and test mocks
        # 'PSUseBOMForUnicodeEncodedFile' # BOM encoding not critical for test files
    )
    
    # Severity levels to include
    Severity = @('Error', 'Warning')
    
    # Include default rules except those excluded above
    IncludeDefaultRules = $true
    
    # Custom rules (none currently)
    CustomRulePath = @()
}
