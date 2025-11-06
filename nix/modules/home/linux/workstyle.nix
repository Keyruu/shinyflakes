{ perSystem, ... }:
{
  home.packages = [
    perSystem.self.niri-workstyle
  ];

  home.file.".config/sworkstyle/config.toml".text = # toml
    ''
      [matching]
      # Browsers
      'zen' = '󰰷'

      # Terminals
      'org.wezfurlong.wezterm' = ''

      'discord' = ''
      'Discord' = ''
      'Webcord' = ''
      'webcord' = ''
      'vesktop' = ' '
      'VSCode' = '󰨞'
      'code-url-handler' = '󰨞'
      'code-oss' = '󰨞'
      'codium' = '󰨞'
      'codium-url-handler' = '󰨞'
      'VSCodium' = '󰨞'
      'Code' = '󰨞'
      'dev.zed.Zed' = '󰬡'
      'signal' = '󰭹'

      'spotify_player' = ''
      'spotify' = ''
      '1Password' = ''
      'Element' = '󰭹'
    '';

  home.file.".config/niri/workstyle.toml".text = # toml
    ''
      default = "*"
      focused_format = "<span foreground='#4079d6'><big>{}</big></span>"

      [matches]
      # Browsers
      'zen' = '󰰷'
      'zen-beta' = '󰰷'

      # Terminals
      'org.wezfurlong.wezterm' = ''
      'Alacritty' = ''

      'vesktop' = '󰙯'
      'Slack' = ''
      'Code' = '󰨞'
      'dev.zed.Zed' = '󰬡'
      'signal' = '󰭹'

      'spotify_player' = ''
      'spotify' = ''
      '1Password' = ''
      'Element' = '󰭹'
    '';
}
