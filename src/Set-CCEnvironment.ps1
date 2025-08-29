<#
.SYNOPSIS
Anthropic Environment Selector
Switch ANTHROPIC environment variables and launch claude
#>

# Force UTF-8 encoding
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null  # Set console codepage to UTF-8 (suppress output)

# Load provider configurations from JSON file
$configPath = Join-Path $PSScriptRoot "..\providers.json"
if (-not (Test-Path $configPath)) {
    Write-Host "Error: providers.json not found at $configPath" -ForegroundColor Red
    exit 1
}

try {
    $jsonContent = Get-Content $configPath -Raw | ConvertFrom-Json
    $configs = @()
    
    foreach ($providerName in $jsonContent.providers.PSObject.Properties.Name) {
        $provider = $jsonContent.providers.$providerName
        $configs += @{
            Name = $providerName
            BaseUrl = $provider.base_url
            AuthToken = $provider.auth_token
            Model = $provider.model
            SmallFastModel = $provider.small_fast_model
        }
    }
}
catch {
    Write-Host "Error loading provider configuration: $_" -ForegroundColor Red
    exit 1
}

# Display header and record starting position
Write-Host "`nEnvironment Config Selector - Use up/down arrows to select, press Enter to confirm" -ForegroundColor Cyan
Write-Host "--------------------------------------------------------------------------------`n"
$selectionStartY = $Host.UI.RawUI.CursorPosition.Y  # Save starting position
$currentSelection = 0  # Initial selection index
$configCount = $configs.Count  # Number of configurations

# Calculate maximum name length (fixed version)
$maxNameLength = 0
foreach ($config in $configs) {
    $nameLength = $config.Name.Length
    if ($nameLength -gt $maxNameLength) {
        $maxNameLength = $nameLength
    }
}
$maxLength = $maxNameLength + 4  # Add space for arrow and padding

# Selection loop with proper clearing of previous content
do {
    # Move cursor back to the starting position
    $Host.UI.RawUI.CursorPosition = @{X=0; Y=$selectionStartY}
    
    # Clear previous entries by overwriting with spaces
    for ($i = 0; $i -lt $configCount; $i++) {
        Write-Host (" " * $maxLength)  # Overwrite with spaces
        # Move cursor back to start of line
        $Host.UI.RawUI.CursorPosition = @{X=0; Y=$selectionStartY + $i}
    }
    
    # Move cursor back to starting position to draw new content
    $Host.UI.RawUI.CursorPosition = @{X=0; Y=$selectionStartY}
    
    # Draw all config options with highlight for selected
    for ($i = 0; $i -lt $configCount; $i++) {
        if ($i -eq $currentSelection) {
            Write-Host "-> $($configs[$i].Name)" -ForegroundColor Green  # Selected option
        } else {
            Write-Host "   $($configs[$i].Name)"  # Non-selected option
        }
    }
    
    # Read user input
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # Handle arrow key navigation
    switch ($key.VirtualKeyCode) {
        38 {  # Up arrow
            $currentSelection = if ($currentSelection -eq 0) { $configCount - 1 } else { $currentSelection - 1 }
        }
        40 {  # Down arrow
            $currentSelection = if ($currentSelection -eq $configCount - 1) { 0 } else { $currentSelection + 1 }
        }
    }
} while ($key.VirtualKeyCode -ne 13)  # Exit on Enter key

# Apply selected environment variables
$selectedConfig = $configs[$currentSelection]
$env:ANTHROPIC_BASE_URL = $selectedConfig.BaseUrl
$env:ANTHROPIC_AUTH_TOKEN = $selectedConfig.AuthToken
$env:ANTHROPIC_MODEL = $selectedConfig.Model
$env:ANTHROPIC_SMALL_FAST_MODEL = $selectedConfig.SmallFastModel

# Show confirmation
Write-Host "`nApplied $($selectedConfig.Name) environment config" -ForegroundColor Green
Write-Host "Base URL: $($selectedConfig.BaseUrl)"
Write-Host "Model:    $($selectedConfig.Model)`n"

# Launch claude
Write-Host "Starting claude..." -ForegroundColor Cyan
claude
    