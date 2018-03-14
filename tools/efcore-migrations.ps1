[CmdletBinding()]
Param(
   # Path where the resulting scripts will be written
   [Parameter(Mandatory=$False)]
   [string] $scriptOutput = ""
)

# Add contexts that should be excluded
$excludedDbContexts = ""

# Get name for context by removing the namespace
Function Get-DbContextName {
    Param([string] $ns)    
    $lio = $ns.LastIndexOf("."); 
    $context = $ns.SubString($lio + 1);
    if($context)
    {
        #Write-Host -ForegroundColor Green "Found $context"
        echo $context
    }
}

Function Include-DbContext {
    Param([string] $context)
    $include = $True
    if($excludedDbContexts.Length -gt 0)
    {
        $include = -not $excludedDbContexts.Contains($context)
        if(-not $include)
        {            
            Write-Host -ForegroundColor Yellow "Skip migrating DbContext $context"
        }
    }
    return $include
}

# Iterate alla available contexts by executing 'dotnet ef dbcontext list'
Function Get-DbContexts {
    Write-Host -ForegroundColor Green "Probing for database contexts..."
    Invoke-Expression "dotnet ef dbcontext list" | ForEach-Object { Get-DbContextName $_. } | Where-Object { Include-DbContext $_. }
}

Function Generate-Migration-Script {
    Param([string] $context)
    $expression = "dotnet ef migrations script --no-build -c $context -o ..\..\deploy\sql\$context.sql"
    Write-Host -ForegroundColor Green "Running command '$expression'"
    Invoke-Expression $expression
}

Function Migration-Script-All {
    Get-DbContexts | ForEach-Object { Generate-Migration-Script $_. }
}

Function Migrate-All {clear
    Get-DbContexts | ForEach-Object { Migrate $_. }
}

Function Migrate {
    Param([string] $context)
    $expression = "dotnet ef database update --no-build -c $context -v"
    Write-Host -ForegroundColor Green "Running command '$expression'"
    Invoke-Expression $expression
}

# Generate migration script for each context
Migration-Script-All
