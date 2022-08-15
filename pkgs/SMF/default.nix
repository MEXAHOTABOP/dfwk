{ lib, stdenv, fetchurl, writeText }:

stdenv.mkDerivation rec {
  pname = "simplemachines-forum";
  version = "2.1.2";

  src = with lib; fetchurl {
    url = "https://github.com/SimpleMachines/SMF/archive/refs/tags/v${version}.tar.gz";
    sha256 = "1rrdqlbbnb35nc3rdmn2d3dqiad1rjbzv1sj084bzzdzjxszfv7k";
  };

  phpConfig = writeText "Settings.php" ''
  <?php
    return require(getenv('SMF_CONFIG'));
  ?>
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r * $out/
    rm -rf $out/{other,custom_avatar,cache,attachment}
    cp ${phpConfig} $out/Settings.php
    cp ${phpConfig} $out/Settings_bak.php
    runHook postInstall
  '';
}