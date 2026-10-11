{ pkgs, ... }:
{
  security.polkit.enable = true;

  users.users.matko.extraGroups = [ "gamemode" "input" ];

  powerManagement.cpuFreqGovernor = "performance";

  services.power-profiles-daemon.enable = false;

  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
  };

  zramSwap = {
    enable = true;
    memoryPercent = 50;
    priority = 100;
  };

  boot.kernelParams = [
    "amd_pstate=active"
    "amdgpu.ppfeaturemask=0xffffffff"
    "split_lock_detect=off"
  ];

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        inhibit_screensaver = 1;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
        amd_performance_level = "high";
      };
      cpu = {
        park_cores = "no";
        pin_cores = "no";
      };
    };
  };

  programs.gamescope.capSysNice = false;

  environment.sessionVariables = {
    AMD_VULKAN_ICD = "RADV";
    RADV_PERFTEST = "gpl";
    MESA_SHADER_CACHE_MAX_SIZE = "5G";
    DXVK_STATE_CACHE = "1";
  };

  environment.systemPackages = with pkgs; [
    vulkan-tools
    radeontop
  ];
}
