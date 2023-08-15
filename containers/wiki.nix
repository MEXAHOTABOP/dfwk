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
          url = "https://extdist.wmflabs.org/dist/extensions/CharInsert-REL1_35-ecd784d.tar.gz";
          sha256 = "1xjhvkd9rkz0n8gcl6rlfi47d9121h3m0zx2x0y3vzw63mgqisx4";
        };
        RegexFunctions = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:RegexFunctions
          url = "https://extdist.wmflabs.org/dist/extensions/RegexFunctions-REL1_35-9655e21.tar.gz";
          sha256 = "0ymxc5r8pl3bm7zkav3d1y1c1zvjh0san141i2ba6p8gc3w769s5";
        };
        Variables = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:Variables
          url = "https://extdist.wmflabs.org/dist/extensions/Variables-REL1_35-8356f40.tar.gz";
          sha256 = "1h0i96d992ik0488c0a5qx0hm4xr7sjh4hgfbxajjv5l4j2b6740";
        };
        SimpleBatchUpload = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:SimpleBatchUpload
          url = "https://github.com/ProfessionalWiki/SimpleBatchUpload/archive/refs/tags/1.8.2.tar.gz";
          sha256 = "04xpwkwmibcdzaz0hvq08hp7q19h0yxaamkqk00q6bs741g67jkn";
        };
        DFRawFunctions = pkgs.fetchgit { # fetchFromGitHub give unexpected results that cause using of cached revision regardless sha256 and rev, im waste a lot of time to debug it
          url = "https://github.com/MEXAHOTABOP/DFRawFunctions.git";
          rev = "66de81a954f19695a8d679980fa8d5822e78944d";
          sha256 = "sha256-dFZy5ekuzw9Pw7N0olkxxjBfYcV9RDmgqo0q7/KFG+o=";
        };
        DFDiagram = pkgs.fetchgit {
          url = "https://github.com/MEXAHOTABOP/DFDiagram.git";
          rev = "b7a3a3f42782ed6da5e1f0025abfc710a0fd82a7";
          sha256 = "sha256-zaRE5ObAf0ZmS3J/cIY9x+jvXyhGKf1rj+9uOEyu928=";
          fetchSubmodules = true;
        };
        Nuke = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:Nuke
          url = "https://extdist.wmflabs.org/dist/extensions/Nuke-REL1_35-4464513.tar.gz";
          sha256 = "02si4b8qnk6vl32bzhcg6vlnlk9sqgap2npj3v4qfh3j27vqvjyh";
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