{ system, config, pkgs, lib, ... }:
{
  imports = [ ./modules/services/security/crowdsec.nix ];
  boot = {
    isContainer = true;
    loader.initScript.enable = true;
  };

  time.timeZone = "Europe/Moscow";

  networking = {
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
    firewall.allowedTCPPorts = [ 25 80 443 3122 3306 ];
  };

  users.users.deploy = {
    isNormalUser = true;
    extraGroups = [ "wheel" "sudo" ];
    uid = 1010;
    openssh.authorizedKeys.keys = [
      # deploy key
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDHD8SGPvEMa8ZD4zpWSst1uWRXIFeYsWeFJyakTh88WjM4kSupD6X1gIwTtL/lk/VWDG0seTZUCyl94x0QjzxzGlLBnDu6aY+vp8VdRv8EWV+h3KkP1XSJjwMuE6yLK6Oilef4rFFXfOxo0LT7cRHBvkvR1yjgzvS49xVeNsQOsSOEtRjWdH1Gusq0FWuWuVx2tOzd71MGt62FQJ3wSonn5WbxcwUTRu+TUUWPvmGrvsg3I8IAWtR4swn0T/6dxx7y0wcwdu/a38kdUCcggKcJdwrtD1eeY3UminWDCFSTJ0a3pu05OOGxvD12eHECZiv4ABk7bf3L7mkt9XQ1qZuQLvUlJFqslIorqIcRWamp0W5dRkrH8UYZlVKkr+aRvFcYFePtz5ClDqKHbA6iVDuQe7RgL+oPBKwq++zw1t0M2Wkjuf1JsbV5rbyW5QxHqwrSmOo2h6mkEJg4D1tdHndlGKCHSMLZGm8thIAZkQVM4r1kjeNB7YnY1yDM3dfDk6s="
    ];
  };

  security = {
    sudo = {
      enable = true;
      extraRules = [{
        groups = [ "wheel" ];
          commands = [{
            command = "ALL";
            options = [ "NOPASSWD" ];
          }];
      }];
    };

    acme = {
      acceptTerms = true;
      defaults.email = "igoreklim@gmail.com";
    };
  };


  services = {
    openssh = {
      enable = true;
      permitRootLogin = "no";
      ports = [ 3122 ];
    };

    mysql = {
      enable = true;
      package = pkgs.mariadb;
      dataDir = "/sites/mysql";
      settings.mysqld.bind-address = "192.168.250.1";
    };

    postfix = {
      enable = true;
      enableSubmission = true;
      hostname = "dfwk.ru";
      domain = "dfwk.ru";
      relayDomains = [ "dfwk.ru" ];
      networks = [ "192.168.250.2/32" "192.168.250.4/32" ];
    };

    nginx = {
      enable = true;
      logError = "stderr error";
      package = pkgs.openresty;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;
      commonHttpConfig = ''
        resolver local=on ipv6=off;
        include ${pkgs.cs-openresty-bouncer}/openresty/crowdsec_openresty.conf;
      '';
      virtualHosts."dfwk.ru" = {
        serverAliases = [ "www.dfwk.ru" ];
        enableACME = true;
        forceSSL = true;

        locations."= /favicon.ico" = {
          root = "/sites/dfwk.ru/favicon/";
          tryFiles = "/favicon.ico =404";
          extraConfig = "expires 60d;";
        };
        locations."/" = {
          proxyPass = "http://192.168.250.2:80";
        };
      };

      virtualHosts."chuck.dfwk.ru" = {
        enableACME = true;
        forceSSL = true;

        locations."= /favicon.ico" = {
          root = "/sites/dfwk.ru/favicon/";
          tryFiles = "/favicon.ico =404";
          extraConfig = "expires 60d;";
        };
        locations."/" = {
          proxyPass = "http://192.168.250.3:80";
        };
      };

      virtualHosts."forum.dfwk.ru" = {
          enableACME = true;
          forceSSL = true;
          default = true;

          locations."= /favicon.ico" = {
            root = "/sites/dfwk.ru/favicon/";
            tryFiles = "/favicon.ico =404";
            extraConfig = "expires 60d;";
          };
          locations."/" = {
            proxyPass = "http://192.168.250.4:80";
          };
      };
    };

    mysqlBackup = {
      enable = true;
      databases = [ "dfwk" "chuck" "forum" ];
      location = "/sites/mysql_backup";
    };

    crowdsec = {
      enable = true;
      name = "dfwk.ru";
      enrollKeyFile = "/sites/crowdsec_secret";
      package = pkgs.crowdsec.overrideAttrs (finalAttrs: previousAttrs: {
            ldflags = [
            "-s"
            "-w"
            "-X github.com/crowdsecurity/go-cs-lib/version.Version=v${previousAttrs.version}"
            "-X github.com/crowdsecurity/go-cs-lib/version.BuildDate=1970-01-01_00:00:00"
            "-X github.com/crowdsecurity/go-cs-lib/version.Tag=${previousAttrs.version}"
            "-X github.com/crowdsecurity/crowdsec/pkg/cwversion.Codename=alphaga"
            "-X github.com/crowdsecurity/crowdsec/pkg/csconfig.defaultConfigDir=/etc/crowdsec"
            "-X github.com/crowdsecurity/crowdsec/pkg/csconfig.defaultDataDir=/var/lib/crowdsec/data"
          ];
      });
    };
  };

  containers.wiki = {
    config = import ./containers/wiki.nix { inherit system lib pkgs config; };  # pkgs is overrided inside container function so php overlay arent passed to pkgs, so evalute module before passing in config
    autoStart = true;
    ephemeral = true;
    bindMounts = {
      "/images" = { hostPath = "/sites/dfwk.ru/images"; isReadOnly = false; };
      "/secrets" = { hostPath = "/sites/dfwk.ru/secrets"; };
    };


    privateNetwork = true;
    hostAddress = "192.168.250.1";
    localAddress = "192.168.250.2";
  };

  containers.chuck = {
    config = import ./containers/chuck.nix { inherit system pkgs config; }; 
    autoStart = true;
    ephemeral = true;
    bindMounts = {
      "/site" = { hostPath = "/sites/chuck.dfwk.ru"; isReadOnly = false; };  # too many dynamic content inside site folder to keep site in store, engine no longer supported since 2013
    };

    privateNetwork = true;
    hostAddress = "192.168.250.1";
    localAddress = "192.168.250.3";
  };

  containers.forum = {
    config = import ./containers/forum.nix { inherit system pkgs config; };
    autoStart = true;
    ephemeral = true;
    bindMounts = {
      "/site" = { hostPath = "/sites/forum.dfwk.ru"; isReadOnly = false; };  # failed to solve plugin installation process in reasanoble timeframe may be return to this later
    };

    privateNetwork = true;
    hostAddress = "192.168.250.1";
    localAddress = "192.168.250.4";
  };

  nix = {
    extraOptions = "experimental-features = nix-command flakes";
    gc.automatic = true;
    gc.options = "--delete-older-than 14d";
    trustedUsers = [
      "root"
      "deploy"
     ];
  };

  environment.systemPackages = with pkgs; [ 
    vim
    tmux
    restic
  ];

   system.stateVersion = "22.05";
}