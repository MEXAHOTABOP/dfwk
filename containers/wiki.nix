{ system, lib, pkgs, ... }:
let
  wiki-php = pkgs.php83; # https://www.mediawiki.org/wiki/Compatibility
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
          url = "https://extdist.wmflabs.org/dist/extensions/CharInsert-REL1_43-ee7b179.tar.gz";
          sha256 = "0immdkdrp23m9z3rqajhd0jwm6x3vx35qh75dfz8255ii0y7imy8";
        };
        RegexFunctions = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:RegexFunctions
          url = "https://extdist.wmflabs.org/dist/extensions/RegexFunctions-REL1_43-db5a65a.tar.gz";
          sha256 = "1f4sj1kwb4q4vc0ax60wil6f8nyii2d36k75mk4yh482ddjripkp";
        };
        Variables = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:Variables
          url = "https://extdist.wmflabs.org/dist/extensions/Variables-REL1_43-81115fa.tar.gz";
          sha256 = "1xjrhybg1kybz0lllawr80y6kj58pikm4hng3wn3dmn7mxjbqa9r";
        };
        SimpleBatchUpload = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:SimpleBatchUpload
          url = "https://github.com/ProfessionalWiki/SimpleBatchUpload/archive/refs/tags/2.0.0.tar.gz";
          sha256 = "0qqbzypilwf8x35kg31s5brgsmk359jglwd0ia5lrqbpngzr7ns0";
        };
        DFRawFunctions = pkgs.fetchgit { # fetchFromGitHub give unexpected results that cause using of cached revision regardless sha256 and rev, im waste a lot of time to debug it
          url = "https://github.com/MEXAHOTABOP/DFRawFunctions.git";
          rev = "456959f9e72c09faf2a9e2db37e91adac0ff179a";
          sha256 = "sha256-BjMNES07j25yLq/seqafmeDBL3WX27bGFRntjh4GL6w=";
        };
        DFDiagram = pkgs.fetchgit {
          url = "https://github.com/MEXAHOTABOP/DFDiagram.git";
          rev = "d3de1a7af4c69d71570327259d622a3e298fa4e4";
          sha256 = "sha256-Hr83mCJjeFG5Wu47V1b2utip0Yh9Ck+HERQ11TqQNwg=";
          fetchSubmodules = true;
        };
        Nuke = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:Nuke
          url = "https://extdist.wmflabs.org/dist/extensions/Nuke-REL1_43-712a75b.tar.gz";
          sha256 = "1g94gxcbvbnbq31mj2iizqgj6nwswc9ngbjqjlaj4164gisz8305";
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