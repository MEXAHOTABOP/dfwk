{ lib, stdenv, fetchurl, writeText }:

stdenv.mkDerivation rec {
  pname = "simplemachines-forum-l10n-russian";
  version = "2.1.2";

  src = with lib; fetchurl {
    url = "https://download.simplemachines.org/index.php/smf_${builtins.replaceStrings [ "." "-" ] version}_language-russian.tar.gz";
    sha256 = "0gchkrlcd2zrhfbnh1ba61x81gmdayvnw1axxzzbkpi7r40gdfdh";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r * $out/
    runHook postInstall
  '';
}