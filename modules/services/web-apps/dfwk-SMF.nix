## NOT IN USE, didnt find out how install Packages from cli, without creating own standalone plugin installer that will patch source files and sql on launch

{ config, pkgs, lib, ... }:
let
  inherit (lib) mkDefault mkEnableOption mkForce mkIf mkMerge mkOption;
  cfg = config.services.smf;
  fpm = config.services.phpfpm.pools.smf;
  writtable_path = "/tmp_dir/"; # workaround for update script
  user = "smf";
  group = config.services.httpd.group;

  pkg = pkgs.stdenv.mkDerivation rec {
    pname = "smf-full";
    src = cfg.package;
    version = src.version;

    installPhase = ''
      mkdir -p $out
      cp -r * $out/
      cp -r ${cfg.localization}/* $out/
      ln -s ${cfg.directory.attachments} $out/${attachments}
    '';
  };


  smfConfigText = ''<?php
/**
 * The settings file contains all of the basic settings that need to be present when a database/cache is not available.
 *
 * Simple Machines Forum (SMF)
 *
 * @package SMF
 * @author Simple Machines https://www.simplemachines.org
 * @copyright 2022 Simple Machines and individual contributors
 * @license https://www.simplemachines.org/about/smf/license.php BSD
 *
 * @version 2.1.0
 */

########## Maintenance ##########
/**
 * The maintenance "mode"
 * Set to 1 to enable Maintenance Mode, 2 to make the forum untouchable. (you"ll have to make it 0 again manually!)
 * 0 is default and disables maintenance mode.
 *
 * @var int 0, 1, 2
 * @global int $maintenance
 */
$maintenance = 0;
/**
 * Title for the Maintenance Mode message.
 *
 * @var string
 * @global int $mtitle
 */
$mtitle = "Maintenance Mode";
/**
 * Description of why the forum is in maintenance mode.
 *
 * @var string
 * @global string $mmessage
 */
$mmessage = "Okay faithful users...we\"re attempting to restore an older backup of the database...news will be posted once we\"re back!";

########## Forum Info ##########
/**
 * The name of your forum.
 *
 * @var string
 */
$mbname = "${cfg.settings.mbname}";
/**
 * The default language file set for the forum.
 *
 * @var string
 */
$language = "${cfg.settings.language}";
/**
 * URL to your forum"s folder. (without the trailing /!)
 *
 * @var string
 */
$boardurl = "${cfg.settings.boardurl}";
/**
 * Email address to send emails from. (like noreply@yourdomain.com.)
 *
 * @var string
 */
$webmaster_email = "${cfg.settings.webmaster_email}";
/**
 * Name of the cookie to set for authentication.
 *
 * @var string
 */
$cookiename = "${cfg.settings.cookiename}";

########## Database Info ##########
/**
 * The database type
 * Default options: mysql, postgresql
 *
 * @var string
 */
$db_type = "${cfg.database.db_type}";
/**
 * The database port
 * 0 to use default port for the database type
 *
 * @var int
 */
$db_port = ${cfg.database.db_port};
/**
 * The server to connect to (or a Unix socket)
 *
 * @var string
 */
$db_server = "${cfg.database.db_server}";
/**
 * The database name
 *
 * @var string
 */
$db_name = "${cfg.database.db_name}";
/**
 * Database username
 *
 * @var string
 */
$db_user = "${cfg.database.db_user}";
/**
 * Database password
 *
 * @var string
 */
$db_passwd = file_get_contents(\"${cfg.database.db_passwordFile}\");;
/**
 * Database user for when connecting with SSI
 *
 * @var string
 */
$ssi_db_user = "";
/**
 * Database password for when connecting with SSI
 *
 * @var string
 */
$ssi_db_passwd = "";
/**
 * A prefix to put in front of your table names.
 * This helps to prevent conflicts
 *
 * @var string
 */
$db_prefix = "${cfg.database.db_prefix}";
/**
 * Use a persistent database connection
 *
 * @var bool
 */
$db_persist = false;
/**
 * Send emails on database connection error
 *
 * @var bool
 */
$db_error_send = true;
/**
 * Override the default behavior of the database layer for mb4 handling
 * null keep the default behavior untouched
 *
 * @var null|bool
 */
$db_mb4 = null;

########## Cache Info ##########
/**
 * Select a cache system. You want to leave this up to the cache area of the admin panel for
 * proper detection of memcached, output_cache or SMF file_system
 * (you can add more with a mod).
 *
 * @var string
 */
$cache_accelerator = "${cfg.settings.cache_accelerator}";
/**
 * The level at which you would like to cache. Between 0 (off) through 3 (cache a lot).
 *
 * @var int
 */
$cache_enable = ${cfg.settings.cache_enable};
/**
 * This is only used for memcache / memcached. Should be a string of "server:port,server:port"
 *
 * @var array
 */
$cache_memcached = "${cfg.settings.cache_memcached}";

/**
 * This is only for the "smf" file cache system. It is the path to the cache directory.
 * It is also recommended that you place this in /tmp/ if you are going to use this.
 *
 * @var string
 */
$cachedir = "${cfg.directory.cachedir}";

########## Image Proxy ##########
# This is done entirely in Settings.php to avoid loading the DB while serving the images
/**
 * Whether the proxy is enabled or not
 *
 * @var bool
 * disabled since require ethernet connection
 */
$image_proxy_enabled = false;
/**
 * Secret key to be used by the proxy
 *
 * @var string
 */
$image_proxy_secret = "smfisawesome";
/**
 * Maximum file size (in KB) for individual files
 *
 * @var int
 */
$image_proxy_maxsize = 5192;

########## Directories/Files ##########
# Note: These directories do not have to be changed unless you move things.
/**
 * The absolute path to the forum"s folder. (not just "."!)
 *
 * @var string
 */
$boarddir = "${boarddir}";
/**
 * Path to the Sources directory.
 *
 * @var string
 */
$sourcedir = "${cfg.directory.sourcedir}";
/**
 * Path to the Packages directory.
 *
 * @var string
 */
$packagesdir = "${cfg.directory.packagesdir}";
/**
 * Path to the tasks directory.
 *
 * @var string
 */
$tasksdir = "${cfg.directory.tasksdir}";

# Make sure the paths are correct... at least try to fix them.
if (!is_dir(realpath($boarddir)) && file_exists(dirname(__FILE__) . "/agreement.txt"))
	$boarddir = dirname(__FILE__);
if (!is_dir(realpath($sourcedir)) && is_dir($boarddir . "/Sources"))
	$sourcedir = $boarddir . "/Sources";
if (!is_dir(realpath($tasksdir)) && is_dir($sourcedir . "/tasks"))
	$tasksdir = $sourcedir . "/tasks";
if (!is_dir(realpath($packagesdir)) && is_dir($boarddir . "/Packages"))
	$packagesdir = $boarddir . "/Packages";
if (!is_dir(realpath($cachedir)) && is_dir($boarddir . "/cache"))
	$cachedir = $boarddir . "/cache";

######### Legacy Settings #########
# UTF-8 is now the only character set supported in 2.1.
$db_character_set = "utf8";

########## Error-Catching ##########
# Note: You shouldn"t touch these settings.
if (file_exists((isset($cachedir) ? $cachedir : dirname(__FILE__)) . "/db_last_error.php"))
	include((isset($cachedir) ? $cachedir : dirname(__FILE__)) . "/db_last_error.php");

if (!isset($db_last_error))
{
	// File does not exist so lets try to create it
	file_put_contents((isset($cachedir) ? $cachedir : dirname(__FILE__)) . "/db_last_error.php", "<" . "?" . "php\n" . "$db_last_error = 0;" . "\n" . "?" . ">");
	$db_last_error = 0;
}

if (file_exists(dirname(__FILE__) . "/install.php"))
{
	$secure = false;
	if (isset($_SERVER["HTTPS"]) && $_SERVER["HTTPS"] == "on")
		$secure = true;
	elseif (!empty($_SERVER["HTTP_X_FORWARDED_PROTO"]) && $_SERVER["HTTP_X_FORWARDED_PROTO"] == "https" || !empty($_SERVER["HTTP_X_FORWARDED_SSL"]) && $_SERVER["HTTP_X_FORWARDED_SSL"] == "on")
		$secure = true;

	if (basename($_SERVER["PHP_SELF"]) != "install.php")
	{
		header("location: http" . ($secure ? "s" : "") . "://" . (empty($_SERVER["HTTP_HOST"]) ? $_SERVER["SERVER_NAME"] . (empty($_SERVER["SERVER_PORT"]) || $_SERVER["SERVER_PORT"] == "80" ? "" : ":" . $_SERVER["SERVER_PORT"]) : $_SERVER["HTTP_HOST"]) . (strtr(dirname($_SERVER["PHP_SELF"]), "\\", "/") == "/" ? "" : strtr(dirname($_SERVER["PHP_SELF"]), "\\", "/")) . "/install.php");
		exit;
	}
}

?>
'';
  boarddir = cfg.directory.boarddir;
  smfConfig = pkgs.writeText "Settings.php" smfConfigText;
  boarddir = writtable_path;
  writtableConfig = pkgs.writeText "Settings.php" smfConfigText;

in {

  options.service.dfwk-smf = {
      enable = mkEnableOption "SMF forum";

      package = mkOption {
        type = types.package;
        default = import ../../../pkgs/SMF;
        description = "Which SMF package to use.";
      };

      localization = mkOption {
        type = types.package;
        default = import ../../../pkgs/SMF-l10n-ru;
        description = "Which SMF localization package use.";
      };

      upgrade = mkOption {
        type = types.package;
        default = import ../../../pkgs/SMF-upgrade;
        description = "SMF upgrade code";
      };

      php = mkOption {
        type = types.package;
        default = pkgs.php;
        defaultText = literalExpression "pkgs.php";
        description = "Which php package to use.";
      };

      settings = {
        mbname = mkOption {
          type = types.str;
          default = "Форум Dwarf Fortress";
          example = "My Community";
          description = "The name of your forum.";
        };

        language = mkOption {
          type = types.str;
          default = "russian";
          example = "english";
          description = "The default language file set for the forum.";
        };

        boardurl = mkOption {
          type = types.str;
          default = "http://127.0.0.1/smf";
          description = "URL to your forums folder. (without the trailing /!)";
        };

        webmaster_email = mkOption {
          type = types.str;
          default = "noreply@myserver.com";
          description = "Email address to send emails from. (like noreply@yourdomain.com.)";
        };

        cookiename = mkOption {
          type = types.str;
          default = "SMFCookie11";
          description = "Name of the cookie to set for authentication.";
        };

        cache_accelerator = mkOption {
          type = types.str;
          default = "";
          description = "Select a cache system. You want to leave this up to the cache area of the admin panel for proper detection of memcached, output_cache or SMF file_system";
        };

        cache_memcached = mkOption {
          type = types.str;
          default = "";
          description = "This is only used for memcache / memcached. Should be a string of server:port,server:port";
        };

        cache_enable = mkOption {
          type = types.int;
          default = 0;
          description = "The level at which you would like to cache. Between 0 (off) through 3 (cache a lot).";
        };
      };

      database = {
        db_type = mkOption {
          type =  types.enum [ "mysql" "postgresql" ];
          default = "mysql";
          description = "The database type";
        };

        db_port = mkOption {
          type = types.int;
          default = 0;
          description = "The database port 0 to use default port for the database type;";
        };

        db_server = mkOption {
          type = types.str;
          default = "localhost";
          description = "The server to connect to (or a Unix socket)";
        };

        db_name = mkOption {
          type = types.str;
          default = "smf";
          description = "The database name";
        };

        db_user = mkOption {
          type = types.str;
          default = "smf";
          description = "Database username";
        };

        db_passwordFile = mkOption {
          type = types.path;
          default = "/dbpass";
          description = "File with database password";
        };

        db_prefix = mkOption {
          type = types.str;
          default = "smf_";
          description = "A prefix to put in front of your table names.";
        };
      };

      directory = {
        boarddir = mkOption {
          type = types.path;
          default = "${pkg}";
          description = "The absolute path to the forums folder. (not just .!)";
        };

        sourcedir = mkOption {
          type = types.path;
          default = "${pkg}/Sources" ;
          description = "Path to the Sources directory.";
        };

        packagesdir = mkOption {
          type = types.path;
          default = "${pkg}/Packages" ;
          description = "Path to the Packages directory.";
        };

        tasksdir = mkOption {
          type = types.path;
          default = "${cfg.sourcedir}/tasks" ;
          description = "Path to the tasks directory.";
        };

        cachedir = mkOption {
          type = types.path;
          default = "/cache" ;
          description = "This is only for the smf file cache system. It is the path to the cache directory.";
        };

        attachments = mkOption {
          type = types.path;
          default = "/attachments" ;
          description = "Path to the attachments directory.";
        };

      };

      packages = mkOption {
        default = {};
        type = types.attrsOf (types.nullOr types.path);
        description = ''
          Attribute set of paths whose content is copied to the <filename>Packages</filename>
          subdirectory of the SMF installation.
        '';
        example = literalExpression ''
          {
            Matomo = pkgs.fetchurl {
              url = "https://github.com/DaSchTour/matomo-mediawiki-extension/archive/v4.0.1.tar.gz";
              sha256 = "0g5rd3zp0avwlmqagc59cg9bbkn3r7wx7p6yr80s644mj6dlvs1b";
            };
          }
        '';
      };


      virtualHost = mkOption {
        type = types.submodule ({
          options = {
             hostName = mkOption {
                type = types.str;
                default = "examp.le";
                description = "Canonical hostname for the server.";
              };

             adminAddr = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "admin@example.org";
              description = "E-mail address of the server administrator.";
             };
          };
        });
        example = literalExpression ''
          {
            hostName = "mediawiki.example.org";
            adminAddr = "webmaster@example.org";
          }
        '';
        description = ''
        stub to make evalution pure without have all staff from apache
          Apache configuration can be done by adapting <option>services.httpd.virtualHosts</option>.
          See <xref linkend="opt-services.httpd.virtualHosts"/> for further information.
        '';
      };

      poolConfig = mkOption {
        type = with types; attrsOf (oneOf [ str int bool ]);
        default = {
          "pm" = "dynamic";
          "pm.max_children" = 32;
          "pm.start_servers" = 2;
          "pm.min_spare_servers" = 2;
          "pm.max_spare_servers" = 4;
          "pm.max_requests" = 500;
        };
        description = ''
          Options for the smf PHP pool. See the documentation on <literal>php-fpm.conf</literal>
          for details on configuration directives.
        '';
      };
  };

  config = mkIf cfg.enable {
    services.phpfpm.pools.smf = {
      inherit user group;
      phpEnv.SMF_CONFIG = "${smfConfig}";
      settings = {
        "listen.owner" = config.services.httpd.user;
        "listen.group" = config.services.httpd.group;
      } // cfg.poolConfig;
    };

    services.httpd = {
      enable = true;
      extraModules = [ "proxy_fcgi"  "remoteip" ];
      virtualHosts.${cfg.virtualHost.hostName} = mkMerge [ cfg.virtualHost {
        documentRoot = mkForce "${pkg}/";
        extraConfig = ''
          RemoteIPHeader X-Forwarded-For
          <Directory "${pkg}/">
            <FilesMatch "\.php$">
              <If "-f %{REQUEST_FILENAME}">
                SetHandler "proxy:unix:${fpm.socket}|fcgi://localhost/"
              </If>
            </FilesMatch>

            Require all granted
            DirectoryIndex index.php
            AllowOverride All
            Options -Indexes
          </Directory>
        '';
      } ];
    };

    systemd.tmpfiles.rules = [
      "d '${cfg.directory.cachedir}' 0750 ${user} ${group} - -"
      "d '${writtable_path}' 0750 ${user} ${group} - -"
      "d '${cfg.directory.attachments}' 0750 ${user} ${group} - -"
    ];

    systemd.services.smf-init = {
      wantedBy = [ "multi-user.target" ];
      before = [ "phpfpm-smf.service" ];

      script = ''
        cp -r ${pkg}/* ${wirttable_path}/
        cp '${writtableConfig}' ${wirttable_path}/Settings.php
        cp '${writtableConfig}' ${wirttable_path}/Settings_bak.php
        ${cfg.php}/bin/php ${cfg.upgrade}/upgrade.php --no-maintenance --debug --backup --path ${wirttable_path}
        rm -rf ${wirttable_path}
      ''; # since we already have files matching version from github, we need only db upgrade, but we need to create rw directory to satisfy checks in updater script without unrelayble patches

      serviceConfig = {
        Type = "oneshot";
        User = user;
        Group = group;
        PrivateTmp = true;
      };
    };
    users.users.${user} = {
      group = group;
      isSystemUser = true;
    };
  };
}