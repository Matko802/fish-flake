# PC (fishy) configuration
{ pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk/disk-config.nix
    ./fonts/fonts-config.nix
    ./nh/nh-config.nix
    ./udev/udev-config.nix
    ./fastfetch/fastfetch-config.nix
    ./fish/fish-config.nix
    ./Starship/starship-config.nix
    ./kitty/kitty-config.nix
    ./mpv/mpv-config.nix
    ./helix/helix-config.nix
    ./zed/zed-config.nix
    ./fetch/fetch-config.nix
    ./thunar/thunar-config.nix
    ./desktop/niri/niri-config.nix
    ./desktop/cliphist/cliphist-config.nix
    ./desktop/hyprpicker/hyprpicker-config.nix
    ./desktop/libnotify/libnotify-config.nix
    ./desktop/quickshell/quickshell-config.nix
    ./gtk/gtk-config.nix
    ./qtengine/qtengine-config.nix
    ./virtualization/kvm/kvm-config.nix
    ./virtualization/virtualbox/virtualbox-config.nix
    ./flatpak/flatpak-config.nix
  ];

  nixpkgs.overlays = [
    inputs.nix-cachyos-kernel.overlays.pinned
  ];

  nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
  nix.settings.trusted-public-keys = [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];

  networking.hostName = "fishy";

  boot.loader.limine.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "i2c-dev" "i2c-piix4" ];
  boot.kernelPackages = pkgs.cachyosKernels."linuxPackages-cachyos-latest";

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

  programs.gpu-screen-recorder = {
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
  services.upower.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;
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

  services.flatpak.enable = true;

  # Fish
  programs.fish.enable = true;

  networking.networkmanager.enable = true;

  # Timezone
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

  services.displayManager.regreet.enable = true;

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
    jack.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."matko" = {
    isNormalUser = true;
    description = "Matko";
    shell = pkgs.fish;
    extraGroups = [ "networkmanager" "wheel" "i2c" ];
    packages = with pkgs; [
      opencode-desktop
      zapzap
      prismlauncher
      helium
      kdePackages.kate
      git
      protonplus
      mpv
      yt-dlp
      fuse
      cava
      cavasik
      sharkvis
      shark-scrp
      sharkfetch
      pear-desktop
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
      zed-editor
      element-desktop
      inputs.zen-browser.packages.x86_64-linux.default
    ];
  };

  # Allow packages that are not free
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [ "ventoy-1.1.17" ];

  # List packages installed in system profile. To search, run:
  environment.systemPackages = with pkgs; [
    (discord.override {
      withEquicord = true;
      withOpenASAR = true;
    })
    fresh-editor
    usbutils
    p7zip
    cargo
    rustc
    gcc
    appimage-run
    rpi-imager
    steamcmd
    fastfetch
    btop
    starship
    wine-wayland
    winetricks
    protontricks
    proton-vpn
    lutris
    unzip
    kdePackages.kcalc
    gparted
    umu-launcher
    faugus-launcher
    setxkbmap
    mangohud
    mangojuice
    android-tools
    papirus-icon-theme
    adwaita-icon-theme
    sound-theme-freedesktop
    ventoy
    kitty
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  hardware.i2c.enable = true;
  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
  };

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
