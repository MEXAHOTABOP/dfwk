{ lib, stdenv, fetchurl, writeText }:
stdenv.mkDerivation rec {
  pname = "simplemachines-forum-upgrade";
  smf = import ../SMF;
  version = smf.version;
  src = smf.src;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r other/upgrade* $out/
    runHook postInstall
  '';
}