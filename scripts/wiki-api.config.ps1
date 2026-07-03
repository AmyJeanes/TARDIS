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
        @{ Title = 'Hooks Reference';             File = 'Hooks-Reference';             Kind = 'hooks'; CommonEntities = @('gmod_tardis', 'gmod_tardis_interior') }
    )
    OwnedPrefix = @('tardis_')
}
