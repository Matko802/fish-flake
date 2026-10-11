{ inputs, ... }:

{
  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/programs/gpu-screen-recorder.nix"
  ];

  disabledModules = [ "programs/gpu-screen-recorder.nix" ];

  programs.gpu-screen-recorder = {
    enable = true;
    package = inputs.nixpkgs-unstable.legacyPackages.x86_64-linux.gpu-screen-recorder;
    ui.enable = true;
    ui.package = inputs.nixpkgs-unstable.legacyPackages.x86_64-linux.gpu-screen-recorder-ui;
    ui.notifPackage = inputs.nixpkgs-unstable.legacyPackages.x86_64-linux.gpu-screen-recorder-notification;
  };
}
