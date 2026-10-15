{ system, pkgs, ... }:
{
  imports = [ ../modules/services/web-apps/dfst.nix ];
  networking.firewall.allowedTCPPorts = [ 3000 ];

  services.dfst = {
    enable = true;
    package = pkgs.dfst;
    uploadsDir = "/site/images";
  };

  system.stateVersion = "26.05";
}
