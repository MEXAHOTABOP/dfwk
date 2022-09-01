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
        UploadWizard = pkgs.fetchzip {
          url = "https://extdist.wmflabs.org/dist/extensions/UploadWizard-REL1_35-5d498dc.tar.gz";
          sha256 = "0sd3222q1z12z3qs4im11bqmx8gwn7z3zd5sqm1ml708w48n8yy4";
        };
        DFRawFunctions = pkgs.fetchgit { # fetchFromGitHub give unexpected results that cause using of cached revision regardless sha256 and rev, im waste a lot of time to debug it
          url = "https://github.com/MEXAHOTABOP/DFRawFunctions.git";
          rev = "aa22c71a2210645f53717559ffd949b8f876d876";
          sha256 = "sha256-75vJMY3USS3Dlt5M/A73KxqArkHmQURKn73c2YyPQ1s=";
        };
        DFDiagram = pkgs.fetchgit {
          url = "https://github.com/MEXAHOTABOP/DFDiagram.git";
          rev = "b7a3a3f42782ed6da5e1f0025abfc710a0fd82a7";
          sha256 = "sha256-zaRE5ObAf0ZmS3J/cIY9x+jvXyhGKf1rj+9uOEyu928=";
          fetchSubmodules = true;
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