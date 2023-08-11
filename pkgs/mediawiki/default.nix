{ lib, stdenv, fetchurl, writeText }:

stdenv.mkDerivation rec {
  pname = "mediawiki";
  version = "1.39.4"; # update no more then on 2 lts releases at time https://www.mediawiki.org/wiki/Manual:Upgrading https://www.mediawiki.org/wiki/Release_notes

  src = with lib; fetchurl {
    url = "https://releases.wikimedia.org/mediawiki/${versions.majorMinor version}/${pname}-${version}.tar.gz";
    sha256 = "1xg34d8jvv2qm047zxkbl0lvjn96a73bg48iy23qshq0i73bg5cx";
  };

  prePatch = ''
    sed -i 's|$vars = Installer::getExistingLocalSettings();|$vars = null;|' includes/installer/CliInstaller.php
  '';

  phpConfig = writeText "LocalSettings.php" ''
  <?php
    return require(getenv('MEDIAWIKI_CONFIG'));
  ?>
  '';

  htaccess = writeText ".htaccess" ''
  RewriteEngine On
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule ^(.+)$ /index.php?title=$1 [PT,L,QSA]
  RewriteRule ^$ index.php?title=Заглавная_страница [PT,L,QSA]
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/mediawiki
    cp -r * $out/share/mediawiki
    cp ${phpConfig} $out/share/mediawiki/LocalSettings.php
    cp ${htaccess} $out/share/mediawiki/.htaccess
    runHook postInstall
  '';

  meta = with lib; {
    description = "The collaborative editing software that runs Wikipedia";
    license = licenses.gpl2Plus;
    homepage = "https://www.mediawiki.org/";
    platforms = platforms.all;
    maintainers = [ maintainers.redvers ];
  };
}