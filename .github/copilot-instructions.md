# TARDIS Copilot Instructions

This document provides instructions to Copilot for how to work with the TARDIS codebase.

## Language Files

When making changes to language strings:

1. **Never edit the Lua language files directly** in `lua/tardis/languages/*.lua` - these are auto-generated.
2. Always make changes to the JSON source files in `i18n/languages/*.json`.
3. When adding new strings, make sure to provide proper translations for all language files - never use placeholders.
4. After updating the source files, run the script to generate the Lua files:
   ```
   pwsh -File ./generate-languages.ps1
   ```

## Command Limitations

- The `lua` and `luac` commands are not available.
- Use `pwsh` for running PowerShell scripts.

## Contributing

When contributing:
1. Keep changes minimal and focused on the task at hand.
2. Maintain the code style of the project.
3. Document only particularly complex / non-obvious code.
4. Use Lua syntax only, no "Garry Lua" e.g. "//" comments or the "continue" keyword.
