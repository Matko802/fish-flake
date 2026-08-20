{ pkgs, ... }:
let
  fontName = "DepartureMono Nerd Font";
in
{
  _module.args = { inherit fontName; };

  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
        nerd-fonts.departure-mono
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
          monospace = [ fontName ];
          sansSerif = [ fontName ];
          serif     = [ fontName ];
      };
      localConf = ''
        <fontconfig>
          <alias>
            <family>sans-serif</family>
            <prefer><family>${fontName}</family></prefer>
          </alias>
          <alias>
            <family>serif</family>
            <prefer><family>${fontName}</family></prefer>
          </alias>
          <alias>
            <family>monospace</family>
            <prefer><family>${fontName}</family></prefer>
          </alias>
        </fontconfig>
      '';
    };
  };
}
