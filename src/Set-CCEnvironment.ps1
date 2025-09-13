<#
.SYNOPSIS
Anthropic Environment Selector
Switch ANTHROPIC environment variables and launch claude
#>

# Force UTF-8 encoding
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null  # Set console codepage to UTF-8 (suppress output)

# Clear the terminal to ensure proper cursor positioning
Clear-Host

# Define path for storing last selected provider
$lastProviderPath = Join-Path $PSScriptRoot "..\last_provider.txt"

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
            DefaultOpusModel = if ($provider.default_opus_model) { $provider.default_opus_model } else { $provider.small_fast_model }
            DefaultSonnetModel = if ($provider.default_sonnet_model) { $provider.default_sonnet_model } else { $provider.model }
            DefaultHaikuModel = if ($provider.default_haiku_model) { $provider.default_haiku_model } else { $provider.small_fast_model }
            SubagentModel = if ($provider.subagent_model) { $provider.subagent_model } else { $provider.small_fast_model }
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

# Check if last provider file exists and try to set default selection
if (Test-Path $lastProviderPath) {
    try {
        $lastProvider = Get-Content $lastProviderPath -ErrorAction Stop
        # Find index of last provider in configs
        for ($i = 0; $i -lt $configs.Count; $i++) {
            if ($configs[$i].Name -eq $lastProvider) {
                $currentSelection = $i
                break
            }
        }
    }
    catch {
        # If there's an error reading the file, just use default selection (0)
    }
}

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
$env:ANTHROPIC_DEFAULT_OPUS_MODEL = $selectedConfig.DefaultOpusModel
$env:ANTHROPIC_DEFAULT_SONNET_MODEL = $selectedConfig.DefaultSonnetModel
$env:ANTHROPIC_DEFAULT_HAIKU_MODEL = $selectedConfig.DefaultHaikuModel
$env:CLAUDE_CODE_SUBAGENT_MODEL = $selectedConfig.SubagentModel

# Show confirmation
Write-Host "`nApplied $($selectedConfig.Name) environment config" -ForegroundColor Green
Write-Host "Base URL: $($selectedConfig.BaseUrl)"
Write-Host "Model:    $($selectedConfig.Model)"
Write-Host "Opus Model:    $($selectedConfig.DefaultOpusModel)"
Write-Host "Sonnet Model:  $($selectedConfig.DefaultSonnetModel)"
Write-Host "Haiku Model:   $($selectedConfig.DefaultHaikuModel)"
Write-Host "Subagent Model: $($selectedConfig.SubagentModel)`n"

# Save the selected provider to file for next use
try {
    $selectedConfig.Name | Out-File -FilePath $lastProviderPath -Encoding UTF8 -ErrorAction Stop
} catch {
    Write-Host "Warning: Could not save last provider selection: $_" -ForegroundColor Yellow
}

# Launch claude
Write-Host "Starting claude..." -ForegroundColor Cyan
claude
    