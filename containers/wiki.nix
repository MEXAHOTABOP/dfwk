{ system, lib, pkgs, ... }:
let
  wiki-php = pkgs.php81; # https://www.mediawiki.org/wiki/Compatibility
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
        CodeEditor = null;
        MultimediaViewer = null;
        SyntaxHighlight_GeSHi = null;
        #HTMLets = null; # deprecated
        #FancyBoxThumbs = null; # deprecated replaced with MultimediaViewer

        CharInsert = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:CharInsert
          url = "https://extdist.wmflabs.org/dist/extensions/CharInsert-REL1_39-259a0d0.tar.gz";
          sha256 = "0a7h3i3xi8jyr6dnrzfsjay87m08cz7njfkvvhlipf9p22h18n6n";
        };
        RegexFunctions = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:RegexFunctions
          url = "https://extdist.wmflabs.org/dist/extensions/RegexFunctions-REL1_39-6f818b1.tar.gz";
          sha256 = "025nnk2pg6zvjhay84frs4bb6csyf5ljn309jk5wp3c67qjdmd4f";
        };
        Variables = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:Variables
          url = "https://extdist.wmflabs.org/dist/extensions/Variables-REL1_39-1620bdf.tar.gz";
          sha256 = "0345f8gz0g3l6s8h37qm191jfh2jzgplwgxh6f51dg0y2ay251hh";
        };
        SimpleBatchUpload = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:SimpleBatchUpload
          url = "https://github.com/ProfessionalWiki/SimpleBatchUpload/archive/refs/tags/2.0.0.tar.gz";
          sha256 = "0qqbzypilwf8x35kg31s5brgsmk359jglwd0ia5lrqbpngzr7ns0";
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
          url = "https://extdist.wmflabs.org/dist/extensions/Nuke-REL1_39-01d32b1.tar.gz";
          sha256 = "0ff1psc880jzi8nq9szr3f6glz0w8xgi4vnvnlkrmm78pxiw304j";
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
  environment.systemPackages = with pkgs; [ 
    python3 # needed for SyntaxHighlight_GeSHi
  ];


  system.stateVersion = "22.05";
}