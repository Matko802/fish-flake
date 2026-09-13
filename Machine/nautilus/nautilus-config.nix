{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    nautilus
    file-roller
    sushi
    ffmpegthumbnailer
    bubblewrap
    libmtp
    rar
  ];

  services.gvfs.enable = true;
}
