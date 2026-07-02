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
          url = "https://extdist.wmflabs.org/dist/extensions/CharInsert-REL1_43-7c3865c.tar.gz";
          sha256 = "05p38pxx4p17jbkcyw8mpvkgakl3947zpfh37xml5a493zpxhkxy";
        };
        RegexFunctions = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:RegexFunctions
          url = "https://extdist.wmflabs.org/dist/extensions/RegexFunctions-REL1_43-6d2eef5.tar.gz";
          sha256 = "0s7id7j1g0xyy3b0b89kcas95vi7kz1xjmnkw5hx5lfy725jia02";
        };
        Variables = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:Variables
          url = "https://extdist.wmflabs.org/dist/extensions/Variables-REL1_43-b9c1815.tar.gz";
          sha256 = "1179pr5lvd5c1bf1k2z169z530ihjy177zy84xxbyppia67jg9z5";
        };
        SimpleBatchUpload = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:SimpleBatchUpload
          url = "https://github.com/ProfessionalWiki/SimpleBatchUpload/archive/refs/tags/3.0.2.zip";
          sha256 = "1ih9lkkvxn4wq35vpw7xsn630wiy5ra4xvnwgpm415wmvz45dkcm";
        };
        DFRawFunctions = pkgs.fetchgit { # fetchFromGitHub give unexpected results that cause using of cached revision regardless sha256 and rev, im waste a lot of time to debug it
          url = "https://github.com/MEXAHOTABOP/DFRawFunctions.git";
          rev = "a62d7f23823f6d064baae32ecffbc86a63c3d3e3";
          sha256 = "sha256-zTPiN8ljNLD0jF3x/Z5PFnOrhXPS3u1FE3lRdrw4g80=";
        };
        DFDiagram = pkgs.fetchgit {
          url = "https://github.com/MEXAHOTABOP/DFDiagram.git";
          rev = "d3de1a7af4c69d71570327259d622a3e298fa4e4";
          sha256 = "sha256-Hr83mCJjeFG5Wu47V1b2utip0Yh9Ck+HERQ11TqQNwg=";
          fetchSubmodules = true;
        };
        Nuke = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:Nuke
          url = "https://extdist.wmflabs.org/dist/extensions/Nuke-REL1_43-a2927d2.tar.gz";
          sha256 = "05478mvds180czw7x0rlh51sxvli2wsp1a2jrgh7dagplj6by2fy";
        };
        CodeMirror = pkgs.fetchzip { # https://www.mediawiki.org/wiki/Extension:CodeMirror
          url = "https://extdist.wmflabs.org/dist/extensions/CodeMirror-REL1_43-0096f3b.tar.gz";
          sha256 = "0ii7rma4zy1yfjbyi7pgvqnafz2iglc26khzdxy03lvw8qv5i79y";
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