{ config, pkgs, ... }: {
  environment.systemPackages = [ pkgs.grim pkgs.slurp pkgs.xrdb ];

  environment.etc."X11/Xresources".text = ''
    Xcursor.theme: Adwaita
    Xcursor.size: 24
  '';

  systemd.user.services.xrdb-cursor = {
    enable = true;
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    environment.DISPLAY = ":0";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.bash}/bin/bash -c 'while true; do if [ -S /tmp/.X11-unix/X0 ] && ! DISPLAY=:0 ${pkgs.xrdb}/bin/xrdb -query 2>/dev/null | grep -q Xcursor.theme; then DISPLAY=:0 ${pkgs.xrdb}/bin/xrdb -merge /etc/X11/Xresources; fi; sleep 1; done'";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${config.users.users.matko.home}/.config 0755 ${config.users.users.matko.name} users -"
    "L+ ${config.users.users.matko.home}/.config/mango - - - - ${./config}"
  ];
}
