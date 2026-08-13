# PC (fishy) configuration
{ config, pkgs, inputs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./nh/nh-config.nix
    ./udev/udev-config.nix
    ./fastfetch/fastfetch-config.nix
    ./fish/fish-config.nix
    ./Starship/starship-config.nix
    ./kitty/kitty-config.nix
    ./mpv/mpv-config.nix
    ./fetch/fetch-config.nix
    ./dolphin/dolphin-config.nix
    ./mango/mango-config.nix
    ./mango/awww/awww-config.nix
    ./mango/bemoji/bemoji-config.nix
    ./mango/cliphist/cliphist-config.nix
    ./mango/fuzzel/fuzzel-config.nix
    ./mango/hypridle/hypridle-config.nix
    ./mango/hyprlock/hyprlock-config.nix
    ./mango/hyprpicker/hyprpicker-config.nix
    ./mango/hyprpolkitagent/hyprpolkitagent-config.nix
    ./mango/libnotify/libnotify-config.nix
    ./mango/mako/mako-config.nix
    ./mango/playerctl/playerctl-config.nix
    ./mango/satty/satty-config.nix
    ./mango/waypaper/waypaper-config.nix
    ./mango/wl-clipboard/wl-clipboard-config.nix
    ./waybar/waybar-config.nix
    ./gtk/gtk-config.nix
    ./qtengine/qtengine-config.nix
    inputs.gsr-ui-nix.nixosModules.default
  ];

  networking.hostName = "fishy";

  boot.loader.limine.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "i2c-dev" "i2c-piix4" ];
  boot.kernelPackages = pkgs.linuxPackages_zen;

  services.ollama = {
    enable = true;
    package = pkgs.ollama-rocm;
    rocmOverrideGfx = "10.3.0";
  };
  services.wivrn = {
    enable = true;
    openFirewall = true;
    autoStart = true;
  };

  virtualisation.virtualbox.host.enable = true;

  programs.gpu-screen-recorder = {
    package = inputs.gsr-ui-nix.packages.${pkgs.stdenv.hostPlatform.system}.gpu-screen-recorder;
    enable = true;
    ui.enable = true;
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  programs.gamemode.enable = true;
  programs.gamescope.enable = true;

  programs.kdeconnect.enable = true;
  services.udisks2.enable = true;
  programs.dconf.enable = true;

  hardware.enableRedistributableFirmware = true;
  programs.nix-ld.enable = true;
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true; # Allows non-root user apps like WiVRn to broadcast mDNS services
    };
  };

  systemd.coredump = {
    enable = true;
    settings.Coredump = {
      Storage = "none";
      ProcessSizeMax = "0";
    };
  };

  services.flatpak.enable = true;
  # Fish
  programs.fish.enable = true;

  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Bratislava";

  # Select internationalisation properties.
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

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.
  services.xserver.enable = false;

  services.greetd.enable = true;
  services.displayManager.regreet.enable = true;
  programs.mango.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "sk";
    variant = "qwerty";
  };

  # Configure console keymap
  console.keyMap = "sk-qwerty";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.doas.enable = true;
  security.doas.extraRules = [
  {
    users = [ "matko" ];
    persist = true;
    keepEnv = true;
  }
];
  security.sudo.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."matko" = {
    isNormalUser = true;
    description = "Matko";
    shell = pkgs.fish;
    extraGroups = [ "networkmanager" "wheel" "i2c" "vboxusers" ];
    packages = with pkgs; [
      zapzap
      prismlauncher
      librewolf
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      kdePackages.kate
      git
      protonplus
      mpv
      vscodium
      opencode-desktop
      yt-dlp
      kitty
      fuse
      cavasik
      cava
      pear-desktop
      mpvScripts.visualizer
      equibop
      godot
      litellm
      kdePackages.filelight
      uv
      ffmpeg-full
      wayvr
      xrizer
      alcom
      unityhub
      mcpelauncher-ui-qt
      obsidian
      krita
      gimp
      inkscape
      blender
      audacity
      lmms
      fetch
      onlyoffice-desktopeditors
      itch

    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [ "ventoy-1.1.12" ];

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs; [
    (pkgs.discord.override {
    withEquicord = true;
    withOpenASAR = true;
  })
    bazaar
    btop
    fresh-editor
    pavucontrol
    networkmanagerapplet
    ventoy
    usbutils
    p7zip
    cargo
    rustc
    gcc
    appimage-run
    #gearlever
    steamcmd
    fastfetch
    starship
    wineWow64Packages.waylandFull
    winetricks
    protontricks
    proton-vpn
    lutris
    unzip
    kdePackages.kcalc
    kdePackages.partitionmanager
    umu-launcher
    faugus-launcher
    setxkbmap
    mangohud
    mangojuice
    android-tools
    adwaita-icon-theme
    sound-theme-freedesktop
  ];

fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      nerd-fonts.jetbrains-mono
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "JetBrainsMono NF" ];
        sansSerif = [ "JetBrainsMono NF" ];
        serif     = [ "JetBrainsMono NF" ];
      };
    };
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  hardware.i2c.enable = true;
  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
  };

  zramSwap.enable = true;
  systemd.oomd.enable = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # Custom DNS
  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNS = "9.9.9.9 149.112.112.112";
        DNSSEC = "true";
        DNSOverTLS = "true";
        Domains = "~.";
        IgnoreCarrierDNS = "yes";
      };
    };
  };

  system.stateVersion = "26.05";
}
