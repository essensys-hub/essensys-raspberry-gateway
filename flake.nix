{
  description = "Essensys Gateway CM5 — NixOS flake (dual-NIC, NVMe, Essensys stack)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    disko.url = "github:nix-community/disko";

    # Local sibling repo in dev; override with --override-input for CI
    essensys-nginx = {
      url = "path:../essensys-nginx";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      essensys-nginx,
      ...
    }:
    let
      supportedSystems = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      essensysNginxSrc = essensys-nginx;
    in
    {
      nixosModules.essensys-gateway = import ./nix/modules;

      nixosConfigurations.gateway-cm5 = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit essensysNginxSrc; };
        modules = [
          disko.nixosModules.disko
          self.nixosModules.essensys-gateway
          ./nix/hosts/gateway-cm5/hardware.nix
          ./nix/hosts/gateway-cm5/emmc-disko.nix
          ./nix/hosts/gateway-cm5/default.nix
        ];
      };

      checks = forAllSystems (
        system:
        {
          flake = nixpkgs.legacyPackages.${system}.runCommand "essensys-gateway-flake-check" { } ''
            echo "flake evaluates for ${system}"
            touch $out
          '';
        }
      );
    };
}
