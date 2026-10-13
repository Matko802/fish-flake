{ pkgs, lib, ... }:
{
  environment.sessionVariables = {
    AMD_VULKAN_ICD = "RADV";
    MESA_SHADER_CACHE_MAX_SIZE = "10G";
    RADV_PERFTEST = "gpl";
  };

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
    };
  };

  hardware.amdgpu.overdrive.enable = true;

  services.lact.enable = true;

  programs.corectrl.enable = true;

  users.users."matko".extraGroups = [ "gamemode" "corectrl" ];

  environment.systemPackages = with pkgs; [
    lact
    corectrl
  ];
}
