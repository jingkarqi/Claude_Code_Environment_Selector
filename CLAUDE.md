# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a PowerShell-based tool that allows users to switch between different AI model providers for Claude Code. It manages environment variables and launches Claude Code with the selected provider configuration.

## Key Files

- `src/Set-CCEnvironment.ps1` - Main PowerShell script that handles provider selection and environment variable configuration
- `providers.json` - Configuration file containing API details for different AI providers
- `README.md` - Project documentation with installation and usage instructions

## Code Architecture

The tool works by:
1. Loading provider configurations from `providers.json`
2. Presenting an interactive menu for users to select a provider
3. Setting environment variables based on the selected provider:
   - `ANTHROPIC_BASE_URL`
   - `ANTHROPIC_AUTH_TOKEN`
   - `ANTHROPIC_MODEL`
   - `ANTHROPIC_SMALL_FAST_MODEL`
4. Launching Claude Code with the configured environment

## Common Development Tasks

### Modifying Provider Configurations
- Edit `providers.json` to add, remove, or modify provider configurations
- Each provider needs: `base_url`, `auth_token`, `model`, and `small_fast_model` fields

### Updating the PowerShell Script
- The main script is `src/Set-CCEnvironment.ps1`
- Handles UTF-8 encoding, JSON configuration loading, interactive selection UI, and environment variable setting

### Testing Changes
- Run the script directly with PowerShell: `.\src\Set-CCEnvironment.ps1`
- Ensure Claude Code is installed and accessible in the system PATH

## Environment Setup

To work with this codebase:
1. Ensure PowerShell 5.1+ is installed
2. Claude Code must be installed and accessible via the `claude` command
3. Provider API keys need to be added to `providers.json`

## Build/Run Commands

There are no specific build commands for this PowerShell-based tool. To run:
```powershell
.\src\Set-CCEnvironment.ps1
```

To set up the convenient `cc` alias, users should add this function to their PowerShell profile:
```powershell
function cc {
    & "PATH_TO_PROJECT\src\Set-CCEnvironment.ps1"
}
```