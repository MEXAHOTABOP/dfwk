{ stdenv, fetchurl, lib}:

stdenv.mkDerivation rec {
  pname = "cs-openresty-bouncer";
  version = "1.0.2";

  src = fetchurl {
    url = "https://github.com/crowdsecurity/cs-openresty-bouncer/releases/download/v${version}/crowdsec-openresty-bouncer.tgz";
    sha256 = "sha256-UgSX3jWVl7EVTdQJuMacR3MEPLD31ikiAe6oPS1CTnE="; 
  };

  prePatch = ''
    substituteInPlace openresty/crowdsec_openresty.conf --replace-fail $\{SSL_CERTS_PATH} "/etc/ssl/certs/ca-certificates.crt" \
    --replace-fail "/etc/crowdsec/bouncers/crowdsec-openresty-bouncer.conf" "/sites/crowdsec-openresty-bouncer.conf"
    substituteInPlace lua/lib/crowdsec.lua --replace-fail "runtime.conf[\"CAPTCHA_TEMPLATE_PATH\"]" "\"$out/templates/captcha.html\"" \
    --replace-fail "runtime.conf[\"BAN_TEMPLATE_PATH\"]" "\"$out/templates/ban.html\""
  '';
  installPhase = ''
    runHook preInstall
    rm -f install.sh uninstall.sh
    mkdir -p $out
    cp -r * $out
    runHook postInstall
  '';

  meta = with lib; {
    description = "CrowdSec OpenResty Bouncer";
    homepage = "https://github.com/crowdsecurity/cs-openresty-bouncer";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    platforms = platforms.linux;
  };
}