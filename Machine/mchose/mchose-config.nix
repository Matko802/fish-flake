{ inputs, ... }:

{
  imports = [ inputs.mchose-hub.nixosModules.default ];

  programs.mchose-hub.enable = true;
}
