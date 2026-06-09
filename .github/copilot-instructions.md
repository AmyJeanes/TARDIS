# TARDIS Copilot Instructions

This document provides instructions to Copilot for how to work with the TARDIS codebase.

## Language Files

When making changes to language strings:

1. **Never edit the Lua language files directly** in `lua/tardis/languages/*.lua` - these are auto-generated.
2. Always make changes to the JSON source files in `i18n/languages/*.json`.
3. Only edit the English source file `i18n/languages/en.json` directly.
4. After updating the source file, run the script to generate the Lua files:
   ```
   pwsh -File scripts/generate-languages.ps1
   ```

## Command Limitations

- The `lua` and `luac` commands are not available.
- Use `pwsh` for running PowerShell scripts.

## Contributing

When contributing:
1. Keep changes minimal and focused on the task at hand.
2. Maintain the code style of the project.
3. Document only particularly complex / non-obvious code: a few lines at most, the *why* not the *what*, biased toward cutting. Keep comments self-contained (no pointers to external docs or fragile cross-file references) and don't explain code by what it replaced.
4. Use Lua syntax only, no "Garry Lua" e.g. "//" comments or the "continue" keyword.
5. Keep comments ASCII: write arrows as the two-character `->`, never the Unicode arrow glyph. For a dash use a single spaced hyphen ` - `, never a double `--` (reads as a second comment marker) or an em-dash.
