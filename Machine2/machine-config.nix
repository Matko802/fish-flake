{ pkgs, inputs, lib, config, ... }:

{
  environment.variables = {
    RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
  };

  imports = [
    ./hardware-configuration.nix
    ../Machine/disk/disk-config.nix
    ../Machine/fonts/fonts-config.nix
    ../Machine/nh/nh-config.nix
    ../Machine/fish/fish-config.nix
    ../Machine/Starship/starship-config.nix
    ../Machine/kitty/kitty-config.nix
    ../Machine/mpv/mpv-config.nix
    ../Machine/helix/helix-config.nix
    ../Machine/nautilus/nautilus-config.nix
    ../Machine/desktop/niri/niri-config.nix
    ../Machine/sharkshell/sharkshell.nix
    ../Machine/desktop/theme/gtk/gtk-config.nix
    ../Machine/desktop/theme/qtengine/qtengine-config.nix
    ../Machine/virtualization/kvm/kvm-config.nix
    ../Machine/gpu-screen-recorder/gsr-config.nix
    ../Machine/gaming/amd-gaming-config.nix
    ../Machine/mchose/mchose-config.nix
    ../Machine/udev/udev-config.nix
  ];

  networking.hostName = "fishy";

  boot.loader.limine.enable = true;
  boot.loader.timeout = 2;
  boot.loader.limine.maxGenerations = 25;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "i2c-dev" "i2c-piix4" ];
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest-x86_64-v3;

  services.wivrn = {
    enable = true;
    openFirewall = true;
    autoStart = true;
    steam.importOXRRuntimes = true;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    extraCompatPackages = with pkgs; [ proton-cachyos proton-ge-bin ];
  };

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  programs.localsend = {
      enable = true;
      openFirewall = true;
    };

  services.udisks2.enable = true;
  services.fwupd.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
  };
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;
  programs.dconf.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.flatpak.enable = true;

  # Fish
  programs.fish.enable = true;

  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false;
  services.journald.settings.Journal = {
    SystemMaxUse = "1G";
    SystemMaxFileSize = "100M";
  };

  # Timezone
  time.timeZone = "Europe/Bratislava";
  i18n.defaultLocale = "sk_SK.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sk_SK.UTF-8";
    LC_IDENTIFICATION = "sk_SK.UTF-8";
    LC_MEASUREMENT = "sk_SK.UTF-8";
    LC_MONETARY = "sk_SK.UTF-8";
    LC_NAME = "sk_SK.UTF-8";
    LC_NUMERIC = "sk_SK.UTF-8";
    LC_PAPER = "sk_SK.UTF-8";
    LC_TELEPHONE = "sk_SK.UTF-8";
    LC_TIME = "sk_SK.UTF-8";
  };


  # Login screen
  services.displayManager.ly.enable = true;

  # Fuck X11 Stuff
  services.xserver.enable = false;
  services.xserver.xkb = {
    layout = "sk";
    variant = "qwerty";
  };

  # Configure console keymap
  console.keyMap = "sk-qwerty";

  # Printing: CUPS with HP (hplip) drivers
  services.printing = {
    enable = true;
    drivers = with pkgs; [ hplip hplipWithPlugin ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.hplipWithPlugin ];
  };

  # Root login
  security.doas = {
      enable = true;
      extraRules = [
        {
          users = [ "matko" ];
          persist = true;
          keepEnv = true;
        }
      ];
    };
  security.sudo.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # User account
  users.users."matko" = {
    isNormalUser = true;
    description = "Matko";
    shell = pkgs.fish;
    extraGroups = [ "networkmanager" "wheel" "i2c" ];
    packages = with pkgs; [
      audacity
      qbittorrent
      telegram-desktop
      ruwa
      prismlauncher
      helium
      kdePackages.kate
      mpv
      yt-dlp
      sharkvis
      shark-scrp
      jefetch
      fetch
      fastfetch
      pear-desktop
      godot
      baobab
      uv
      ffmpeg-full
      wayvr
      alcom
      unityhub
      mcpelauncher-ui-qt
      obsidian
      krita
      gimp
      inkscape
      blender
      blockbench
      lmms-flake
      pandora-launcher
      rootapp
      g3m
      metrolist-kmp-flake
      onlyoffice-desktopeditors
      itch
      element-desktop
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      seahorse
    ];
  };

  # Allow packages that are not free
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.problems.handlers."gtk+".broken = "ignore";
  nixpkgs.config.permittedInsecurePackages = [
    "ventoy-1.1.18"
  ];

  documentation.info.enable = false;

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs; [
    dotnet-sdk_8
    mangojuice
    mangohud
    fuse
    git
    nodejs
    python3
    clang-tools
    vesktop
    usbutils
    p7zip
    appimage-run
    bazaar
    rpi-imager
    steamcmd
    btop
    starship
    wine-wayland
    winetricks
    protontricks
    proton-vpn
    lutris
    unzip
    gnome-calculator
    gparted
    umu-launcher
    faugus-launcher
    setxkbmap
    android-tools
    papirus-icon-theme
    adwaita-icon-theme
    sound-theme-freedesktop
    ventoy
    kitty
    zed-editor
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  hardware.i2c.enable = true;
  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
  };
  programs.nix-ld.enable = true;
  systemd.oomd.enable = true;
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = true;
    };
  };
  programs.mosh = {
      enable = true;
    };
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
  };
  # Custom DNS
  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNS = "9.9.9.9 149.112.112.112 1.1.1.2 1.0.0.2";
        DNSSEC = "true";
        DNSOverTLS = "true";
        Domains = "~.";
        IgnoreCarrierDNS = "yes";
      };
    };
  };

  system.stateVersion = "26.05";
}
