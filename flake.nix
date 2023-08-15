{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.05";
    deploy-rs.url = "github:serokell/deploy-rs";
    legacy-php.url = "github:fossar/nix-phps";
  };
  outputs = { self, nixpkgs, legacy-php, deploy-rs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      overlays = [ legacy-php.overlays.default ];
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

