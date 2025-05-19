# TARDIS Copilot Instructions

Welcome to the TARDIS repository! This document contains important information for working with this codebase.

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

- The `lua` and `luac` commands are not available in this environment.
- Use `pwsh` for running PowerShell scripts.

## Testing

- Test your changes in-game to ensure they work as expected.
- Make sure to test edge cases, like when a TARDIS has no idle sounds configured.

## Source Engine Units

- 1 unit ≈ 0.75 inches or ~1.9 cm
- 1 meter ≈ 53 units
- Sound level values correspond roughly to distance in Source engine units:
  - 75 is approximately 5 meters
  - Lower values extend the range, higher values reduce it

## Contributing

When contributing:
1. Keep changes minimal and focused on the task at hand.
2. Test thoroughly before submitting.
3. Maintain the code style of the project.
4. Document your changes appropriately.

## Common Patterns

- Settings that affect client-side behavior should be added to the appropriate sections in `lua/tardis/settings/`.
- Use `TARDIS:GetSetting("setting_name")` to access setting values.
- The TARDIS metadata contains important information about the TARDIS model and sounds.
- When handling sounds that can have multiple sources (like idle sounds), play all of them simultaneously rather than choosing one randomly.