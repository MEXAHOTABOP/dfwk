{ system, lib, pkgs, ... }:
let
  wiki-php = pkgs.php74; # https://www.mediawiki.org/wiki/Compatibility
in {
  imports = [ ../modules/services/web-apps/dfwk-mediawiki.nix ];
  networking.firewall.allowedTCPPorts = [ 80 ];
  services = {
    dfwk-mediawiki = {
      enable = true;
      package = pkgs.callPackage ../pkgs/mediawiki { };
      php = wiki-php;

      wgServer = "https://dfwk.ru";
      wgMainCacheType = "CACHE_ACCEL";
      wgSessionCacheType = "CACHE_DB";
      wgPasswordSender = "noreply@dfwk.ru";
      uploadsDir = "/images";
      smtp = {
        enable = true;
        host = "192.168.250.1";
        port = 25;
        idHost = "dfwk.ru";
        auth = false;
      };
      extensions = {
        ParserFunctions = null;
        Interwiki = null;
        Cite = null;
        ConfirmEdit = null;
        WikiEditor = null;
        MultimediaViewer = null;
        #HTMLets = null; # deprecated
        #FancyBoxThumbs = null; # deprecated replaced with MultimediaViewer

        CharInsert = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:CharInsert
          url = "https://extdist.wmflabs.org/dist/extensions/CharInsert-REL1_35-89fa92f.tar.gz";
          sha256 = "sha256-KCCxyfpPyedoHpbO+0MwF84TnOkQSCvdVTWx8xnukfU=";
        };
        RegexFunctions = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:RegexFunctions
          url = "https://extdist.wmflabs.org/dist/extensions/RegexFunctions-REL1_35-fec4886.tar.gz";
          sha256 = "sha256-VsyC3BwJqMVtXI41d9U7HU14k8P8mt11P2eU14m1ZC4=";
        };
        Variables = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:Variables
          url = "https://extdist.wmflabs.org/dist/extensions/Variables-REL1_35-23bb2de.tar.gz";
          sha256 = "sha256-/sAuDLi2KfzCslLaD3W517e1Py7tR6BT6EQpd9y/A8w=";
        };
        SimpleBatchUpload = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:SimpleBatchUpload
          url = "https://github.com/ProfessionalWiki/SimpleBatchUpload/archive/refs/tags/1.8.2.tar.gz";
          sha256 = "04xpwkwmibcdzaz0hvq08hp7q19h0yxaamkqk00q6bs741g67jkn";
        };
        DFRawFunctions = pkgs.fetchgit { # fetchFromGitHub give unexpected results that cause using of cached revision regardless sha256 and rev, im waste a lot of time to debug it
          url = "https://github.com/MEXAHOTABOP/DFRawFunctions.git";
          rev = "cba6af058c0a4440202e2ca0b48fed0015d014bc";
          sha256 = "sha256-tnvTQLmhvQWqAKW/Q3lj5j0r90xDwZUB/S+M5BhuCNU=";
        };
        DFDiagram = pkgs.fetchgit {
          url = "https://github.com/MEXAHOTABOP/DFDiagram.git";
          rev = "b7a3a3f42782ed6da5e1f0025abfc710a0fd82a7";
          sha256 = "sha256-zaRE5ObAf0ZmS3J/cIY9x+jvXyhGKf1rj+9uOEyu928=";
          fetchSubmodules = true;
        };
        Nuke = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:Nuke
          url = "https://extdist.wmflabs.org/dist/extensions/Nuke-REL1_35-4cde476.tar.gz";
          sha256 = "01rx95if9q4yz2ana3fx1npwayrxb3n05579qqj44lvvwhy5304c";
        };
      };

      database = {
        host = "192.168.250.1";
        name = "dfwk";
        user = "dfwk";
        passwordFile = "/secrets/MysqlPass";
      };

      virtualHost = {
        hostName = "dfwk.ru";
        adminAddr = "igoreklim@gmail.com";
      };


      extraConfig = (builtins.readFile ../extra/dfwk/extra_config);

    };
    phpfpm.phpPackage = wiki-php.withExtensions ({ enabled, all }: enabled ++ [ all.apcu ]);
  };

  system.stateVersion = "22.05";
}