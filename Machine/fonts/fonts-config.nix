{ config, lib, pkgs, ... }:
{
  options.custom.fontName = lib.mkOption {
    type = lib.types.str;
    default = "DepartureMono Nerd Font";
    description = "System font — change via `custom.fontName` in your host config, no hardcode needed";
  };

  config = {
    _module.args.fontName = config.custom.fontName;

    fonts = {
      fontDir.enable = true;
      packages = with pkgs; [
          nerd-fonts.departure-mono
          noto-fonts-color-emoji
      ];
      fontconfig = {
        enable = true;
        antialias = true;
        hinting = {
          enable = true;
          style = "slight";
        };
        subpixel = {
          rgba = "rgb";
          lcdfilter = "default";
        };
        defaultFonts = {
            monospace = [ config.custom.fontName ];
            sansSerif = [ config.custom.fontName ];
            serif     = [ config.custom.fontName ];
            emoji     = [ "Noto Color Emoji" ];
        };
        localConf = ''
          <fontconfig>
            <alias>
              <family>sans-serif</family>
              <prefer><family>${config.custom.fontName}</family></prefer>
            </alias>
            <alias>
              <family>serif</family>
              <prefer><family>${config.custom.fontName}</family></prefer>
            </alias>
            <alias>
              <family>monospace</family>
              <prefer><family>${config.custom.fontName}</family></prefer>
            </alias>
          </fontconfig>
        '';
      };
    };
  };
}
