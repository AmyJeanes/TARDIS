@{
    WikiBaseUrl = 'https://github.com/AmyJeanes/TARDIS/wiki'
    Categories = @(
        @{ Title = 'Interior Reference';          File = 'Interior-Reference';          Roots = @('tardis_metadata') }
        @{ Title = 'Exterior Reference';          File = 'Exterior-Reference';          Roots = @('tardis_exterior_metadata') }
        @{ Title = 'Parts Reference';             File = 'Parts-Reference';             Roots = @('gmod_tardis_part') }
        @{ Title = 'Controls Reference';          File = 'Controls-Reference';          Roots = @('tardis_control') }
        @{ Title = 'Control Sequences Reference'; File = 'Control-Sequences-Reference'; Roots = @('tardis_sequence') }
        @{ Title = 'Settings Reference';          File = 'Settings-Reference';          Roots = @('tardis_setting') }
        @{ Title = 'Tips Reference';              File = 'Tips-Reference';              Roots = @('tardis_tip') }
        @{ Title = 'Icon Packs Reference';        File = 'Icon-Packs-Reference';        Roots = @('tardis_icon_pack') }
        @{ Title = 'GUI Themes Reference';        File = 'GUI-Themes-Reference';        Roots = @('tardis_gui_theme') }
        @{ Title = 'Screens Reference';           File = 'Screens-Reference';           Roots = @('tardis_screen_options') }
        @{ Title = 'Functions Reference';         File = 'Functions-Reference';         Kind = 'functions'; Class = 'TARDIS' }
        @{ Title = 'Hooks Reference';             File = 'Hooks-Reference';             Kind = 'hooks'; CommonEntities = @('gmod_tardis', 'gmod_tardis_interior') }
        @{ Title = 'ConVars Reference';           File = 'ConVars-Reference';           Kind = 'convars' }
        @{
            Title = 'Settings Catalogue'; File = 'Settings-Catalogue'; Kind = 'catalogue'
            Register = 'TARDIS:AddSetting'; NameHeader = 'Setting'
            Labels = @{ Key = 'Settings.Sections.{section}.{subsection}.{name}'; Fallback = 'name' }
            Group = @(
                @{ By = 'section' }
                @{ By = 'subsection'; LabelKey = 'Settings.Sections.{section}.{subsection}' }
            )
            Where = @{ Field = 'option'; Equals = 'true' }
            Columns = @(
                @{ H = 'Type';        F = 'type' }
                @{ H = 'Default';     F = 'value'; Range = 'min,max'; Code = $true }
                @{ H = 'Scope';       F = 'class'; Map = @{ global = 'Server-wide'; local = 'Client'; networked = 'Per-player' } }
                @{ H = 'ConVar';      F = 'convar.name'; Link = 'ConVars-Reference'; SkipEmptyColumn = $true }
                @{ H = 'Description'; Desc = $true }
            )
        }
        @{
            Title = 'Keybinds'; File = 'Keybinds'; Kind = 'catalogue'
            Register = 'TARDIS:AddKeyBind'; Arg = 'id-table'; NameHeader = 'Bind'
            Labels = @{ Key = 'Binds.Sections.{section}.{name}'; Fallback = 'name' }
            Group = @( @{ By = 'section' } )
            Columns = @(
                @{ H = 'Default Key'; F = 'key'; KeyName = $true; Code = $true }
                @{ H = 'Runs on';     RunsOn = 'exterior,interior'; Realm = @{ serveronly = 'server'; clientonly = 'client' } }
                @{ H = 'Description'; Desc = $true }
            )
        }
    )
    OwnedPrefix = @('tardis_')
}
