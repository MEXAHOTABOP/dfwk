{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-26.05";
    deploy-rs.url = "github:serokell/deploy-rs";
    legacy-php.url = "github:fossar/nix-phps";
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

    dfst = { # currently not public
      url = "git+ssh://gitea@h.w1l.ru/MEXAHOTABOP/dfst.git?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, legacy-php, deploy-rs, nixpkgs-unstable, dfst }:
  let
    system = "x86_64-linux";
    dfstPkg = dfst.packages.${system}.dfst;
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ 
        legacy-php.overlays.default
        (final: prev:{
          crowdsec = nixpkgs-unstable.legacyPackages.${system}.crowdsec;
          cs-openresty-bouncer = prev.callPackage ./pkgs/cs-openresty-bouncer { };
          dfst = dfstPkg;
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
      modules = [ 
        ({ ... }: { # new version already in unstable
          disabledModules = [
            "services/security/crowdsec.nix"
          ];
          imports = [ 
            "${nixpkgs-unstable}/nixos/modules/services/security/crowdsec/default.nix"
          ];
        })
        ./configuration.nix
      ];
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

