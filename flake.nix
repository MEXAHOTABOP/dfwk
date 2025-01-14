{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
    deploy-rs.url = "github:serokell/deploy-rs";
    legacy-php.url = "github:fossar/nix-phps";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
  };
  outputs = { self, nixpkgs, legacy-php, deploy-rs, nixpkgs-unstable}:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ 
        legacy-php.overlays.default
        (final: prev:{
          crowdsec = nixpkgs-unstable.legacyPackages.${system}.crowdsec;
          cs-openresty-bouncer = prev.callPackage ./pkgs/cs-openresty-bouncer { };
          openresty = prev.openresty.overrideAttrs (finalAttrs: previousAttrs: {
            postInstall = previousAttrs.postInstall + ''
              cp -r ${final.luaPackages.lua-resty-http}/share/lua/5.2/* $out/lualib/
              cp -r ${final.luaPackages.lua-resty-openssl}/share/lua/5.2/* $out/lualib/
              cp -r ${final.cs-openresty-bouncer}/lua/lib/* $out/lualib/
            '';
          });
        })
      ];
    };
  in {
    dfwkSystem = nixpkgs.lib.nixosSystem {
      inherit system;
      inherit pkgs;
      modules = [ ./configuration.nix ];
    };

    devShells.${system}.default = with nixpkgs.legacyPackages.${system}; mkShell {
          buildInputs = [
            deploy-rs.outputs.packages.${system}.deploy-rs
          ];
    };


    deploy.nodes.dfwk = {
      hostname = "dfwk.w1l.ru";
      profiles.system = {
        sshUser = "deploy";
        user = "root";
        path = deploy-rs.lib.x86_64-linux.activate.nixos self.dfwkSystem;
      };
    };

    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
  };
}

