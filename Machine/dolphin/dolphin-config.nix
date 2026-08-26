{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    kdePackages.ark
    kdePackages.dolphin
    kdePackages.kio-extras
    kdePackages.kdegraphics-thumbnailers
    kdePackages.kimageformats
    kdePackages.ffmpegthumbs
    libmtp
    unrar
    rar
  ];

  services.gvfs.enable = true;

  environment.etc."xdg/menus/applications.menu".source = "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";
}