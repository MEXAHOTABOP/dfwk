{ stdenv, fetchurl, lib}:

stdenv.mkDerivation rec {
  pname = "cs-openresty-bouncer";
  version = "1.1.3";

  src = fetchurl {
    url = "https://github.com/crowdsecurity/cs-openresty-bouncer/releases/download/v${version}/crowdsec-openresty-bouncer.tgz";
    sha256 = "0hkp91jjhq41ddxbyqnp2dnpqxpws5h8d77c2q7ga8x3xk4r8n38"; 
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