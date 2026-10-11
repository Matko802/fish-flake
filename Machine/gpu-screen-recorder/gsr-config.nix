{ pkgs, config, lib, ... }:
let
  backend = pkgs.unstable.gpu-screen-recorder.override {
    inherit (config.security) wrapperDir;
  };
  ui = pkgs.unstable.gpu-screen-recorder-ui.override {
    gpu-screen-recorder = backend;
    inherit (config.security) wrapperDir;
  };
in
{
  programs.gpu-screen-recorder = {
    enable = true;
    package = pkgs.unstable.gpu-screen-recorder;
  };

  environment.systemPackages = [
    ui
    pkgs.unstable.gpu-screen-recorder-notification
  ];

  security.wrappers."gsr-global-hotkeys" = {
    owner = "root";
    group = "root";
    capabilities = "cap_setuid+ep";
    source = lib.getExe' ui "gsr-global-hotkeys";
  };
}
