{
  config,
  pkgs,
  fontName,
  ...
}:
let
  zedDir = pkgs.runCommand "zed-config" {} ''
    mkdir -p $out
    cp ${./settings.json} $out/settings.json
  '';
in {
  systemd.tmpfiles.rules = [
    "d ${config.users.users.matko.home}/.config 0755 ${config.users.users.matko.name} users -"
    "L+ ${config.users.users.matko.home}/.config/zed - - - - ${zedDir}"
  ];

  environment.systemPackages = with pkgs; [
    nil
    nixfmt
    nixd
    marksman
  ];
}
