{ system, config, pkgs, ... }:
let
  user = "forum";
  group = config.services.httpd.group;
  siteDir = "/site";
in {
  networking.firewall.allowedTCPPorts = [ 80 ];
  services = {
    phpfpm.pools.forum = {
      inherit user group;
      phpPackage = pkgs.php74.withExtensions ({ enabled, all }: enabled ++ [ all.apcu ]);
      settings =  {
        "listen.owner" = config.services.httpd.user;
        "listen.group" = config.services.httpd.group;
        "pm" = "dynamic";
        "pm.max_children" = 32;
        "pm.start_servers" = 2;
        "pm.min_spare_servers" = 2;
        "pm.max_spare_servers" = 4;
        "pm.max_requests" = 500;
      };
    };

    httpd = {
      enable = true;
      extraModules = [ "proxy_fcgi" "remoteip" ];
      adminAddr = "igoreklim@gmail.com";
      virtualHosts."forum.dfwk.ru" = {
        serverAliases = ["forum.dfwk.w1l.ru"];
        documentRoot = siteDir;
        extraConfig = ''
          RemoteIPHeader X-Forwarded-For
          <Directory "${siteDir}">
              <FilesMatch "\.php$">
                <If "-f %{REQUEST_FILENAME}">
                  SetHandler "proxy:unix:/run/phpfpm/forum.sock|fcgi://localhost/"
                </If>
              </FilesMatch>
              Require all granted
              DirectoryIndex index.php
              AllowOverride All
              Options -Indexes
            </Directory>
        ''; # for some reason config.services.phpfpm.pools.chuck is not exist in evalution process, so replace it with direct pre evaluted path, othervise all work correctly
      };
    };
  };

  users.users.${user} = {
      group = group;
      isSystemUser = true;
  };

  systemd.tmpfiles.rules = [
      "d '${siteDir}' 0750 ${user} ${group} - -"
  ];

  system.stateVersion = "22.05";
}