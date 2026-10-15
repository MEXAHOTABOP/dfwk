{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.services.dfst;
in
{
  options.services.dfst = {
    enable = mkEnableOption "dfst rails site";

    package = mkOption {
      type = types.package;
      description = "dfst site package (exposes passthru.gems)";
    };

    uploadsDir = mkOption {
      type = types.path;
      default = "/var/lib/dfst/uploads";
      description = "uploads directory (served at /images)";
    };

    secretKeyBaseFile = mkOption {
      type = types.path;
      default = "/secrets/SecretKey";
      description = "file with SECRET_KEY_BASE";
    };

    database = {
      socket = mkOption { type = types.path;  default = "/run/postgresql"; };
    };
  };

  config = mkIf cfg.enable (let
    db = cfg.database;
    socketPct = lib.replaceStrings [ "/" ] [ "%2F" ] (toString db.socket);
    # DATABASE_URL built here, not via systemd Environment=, which expands %-specifiers
    puma = pkgs.writeShellScriptBin "dfst-puma" ''
      export SECRET_KEY_BASE="$(cat ${cfg.secretKeyBaseFile})"
      export DATABASE_URL="postgres://dfst@${socketPct}/dfst"
      exec ${cfg.package.gems}/bin/puma -e production -b tcp://0.0.0.0:3000
    '';
  in {
    # uid 1011 must equal the host user's uid for PostgreSQL peer auth
    users.groups.dfst = { };
    users.users.dfst = {
      uid = 1011;
      group = "dfst";
      isSystemUser = true;
    };

    systemd.services.dfst-puma = {
      description = "dfst rails (puma)";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      environment = {
        RAILS_ENV      = "production";
        BUNDLE_GEMFILE = "${cfg.package}/Gemfile";
        UPLOADS_DIR    = cfg.uploadsDir;
        TMPDIR         = "/tmp";
      };
      # mini_magick needs `convert`/`mogrify`; merges with systemd's default PATH
      path = [ pkgs.imagemagick ];
      serviceConfig = {
        Type = "simple";
        User = "dfst";
        Group = "dfst";
        WorkingDirectory = cfg.package;
        StateDirectory = "dfst";
        Restart = "always";
        RestartSec = "2s";
      };
      script = "${puma}/bin/dfst-puma";
    };

    systemd.tmpfiles.rules = [
      "d '${cfg.uploadsDir}' 0755 dfst dfst - -"
    ];
  });
}
