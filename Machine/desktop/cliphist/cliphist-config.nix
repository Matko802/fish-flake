{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [ cliphist ];
}
