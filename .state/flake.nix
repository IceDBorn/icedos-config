{
  inputs = {
    home-manager = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:nix-community/home-manager";
    };
    icedos-config = {
      url = "path:/home/ice/.code/icedos/config";
    };
    icedos-config-ambiled = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "path:/home/ice/.code/ambiled";
    };
    icedos-core = {
      follows = "icedos-config/icedos";
    };
    icedos-github_icedos_apps = {
      url = "github:icedos/apps/b86a95411c53ee7dfe94b6b676a8f31da9995e05";
    };
    icedos-github_icedos_apps-celluloid-celluloid-shader = {
      flake = false;
      url = "path:///nix/store/5zcj323fgw0vxx0nhgvp45yxrwikm0c6-FSR.glsl";
    };
    icedos-github_icedos_apps-prefixer-prefixer = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:wojtmic/prefixer";
    };
    icedos-github_icedos_apps-proton-launch-scopebuddy = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:HikariKnight/ScopeBuddy";
    };
    icedos-github_icedos_cosmic = {
      url = "github:icedos/cosmic/3110d2f9f5f5d5ac4188c23d840ec6626366c546";
    };
    icedos-github_icedos_cosmic-default-cosmic-manager = {
      inputs = {
        home-manager = {
          follows = "home-manager";
        };
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:HeitorAugustoLN/cosmic-manager";
    };
    icedos-github_icedos_desktop = {
      url = "github:icedos/desktop/7310cf4cf076408f5cdb099ef757689d2955bf00";
    };
    icedos-github_icedos_hardware = {
      url = "github:icedos/hardware/f4c2eb72ee6745ea6cf1120abe3c26f60075de2a";
    };
    icedos-github_icedos_hardware-cachyos-kernel-nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
    };
    icedos-github_icedos_providers = {
      url = "github:icedos/providers/c1a5aa2f9cdfd58f0c58ea78a4905c6afa9c373e";
    };
    icedos-github_icedos_tweaks = {
      url = "github:icedos/tweaks/b73911a16e86fb8c075ea413fced1b4e78ded179";
    };
    icedos-state = {
      flake = false;
      url = "path:/nix/store/2l5hwvv76crrz2nsgaba1mrgiq5g6299-icedos";
    };
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixpkgs-unstable";
    };
    nur = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:nix-community/nur";
    };
  };

  outputs =
    {
      home-manager,
      nixpkgs,
      self,
      ...
    }@inputs:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;

          permittedInsecurePackages = [

          ];
        };
      };

      inherit (pkgs) lib;
      inherit (lib) fileContents filterAttrs;

      inherit (builtins) pathExists;
      inherit ((fromTOML (fileContents "${inputs.icedos-config}/config.toml"))) icedos;

      icedosLib = import "${inputs.icedos-core}/lib" {
        inherit lib pkgs inputs;
        config = icedos;
        self = toString inputs.icedos-core;
      };

      inherit (icedosLib) modulesFromConfig;

      getModules =
        path:
        map (dir: "/${path}/${dir}") (
          let
            inherit (lib) attrNames;
          in
          attrNames (filterAttrs (n: v: v == "directory") (builtins.readDir path))
        );
    in
    {
      nixosConfigurations."icedos" = nixpkgs.lib.nixosSystem rec {
        specialArgs = {
          inherit icedosLib inputs;
        };

        modules = [
          # Read configuration location
          (
            { lib, ... }:
            let
              inherit (lib) mkOption types;
            in
            {
              options.icedos.configurationLocation = mkOption {
                type = types.str;
                default = "/home/ice/.code/icedos/config/.state";
              };
            }
          )

          # Symlink configuration state on "/run/current-system/source"
          {
            # Source: https://github.com/NixOS/nixpkgs/blob/5e4fbfb6b3de1aa2872b76d49fafc942626e2add/nixos/modules/system/activation/top-level.nix#L191
            system.systemBuilderCommands = "ln -s ${self} $out/source";
          }

          {
            imports = [
              "${inputs.icedos-core}/modules/nh.nix"
              "${inputs.icedos-core}/modules/nix.nix"
              "${inputs.icedos-core}/modules/rebuild.nix"
              "${inputs.icedos-core}/modules/state.nix"
              "${inputs.icedos-core}/modules/toolset.nix"
              "${inputs.icedos-core}/modules/users.nix"
            ];
          }

          # Internal modules and config
          {
            imports = [
              "${inputs.icedos-core}/modules/options.nix"
            ]
            ++ (
              if (pathExists "${inputs.icedos-config}/extra-modules") then
                (getModules "${inputs.icedos-config}/extra-modules")
              else
                [ ]
            );
            config.system.stateVersion = "25.11";
          }

          home-manager.nixosModules.home-manager

          { icedos.system.isFirstBuild = false; }

          (
            # Do not modify this file!  It was generated by ‘nixos-generate-config’
            # and may be overwritten by future invocations.  Please make changes
            # to /etc/nixos/configuration.nix instead.
            {
              config,
              lib,
              pkgs,
              modulesPath,
              ...
            }:

            {
              imports = [
                (modulesPath + "/installer/scan/not-detected.nix")
              ];

              boot.initrd.availableKernelModules = [
                "nvme"
                "xhci_pci"
                "ahci"
                "usbhid"
                "usb_storage"
                "sd_mod"
              ];
              boot.initrd.kernelModules = [ ];
              boot.kernelModules = [ "kvm-amd" ];
              boot.extraModulePackages = [ ];

              fileSystems."/" = {
                device = "/dev/mapper/luks-f71c56ea-2db0-47d2-b57c-21b8f7ea1b22";
                fsType = "btrfs";
                options = [ "subvol=@" ];
              };

              boot.initrd.luks.devices."luks-f71c56ea-2db0-47d2-b57c-21b8f7ea1b22".device =
                "/dev/disk/by-uuid/f71c56ea-2db0-47d2-b57c-21b8f7ea1b22";

              fileSystems."/home" = {
                device = "/dev/mapper/luks-f71c56ea-2db0-47d2-b57c-21b8f7ea1b22";
                fsType = "btrfs";
                options = [ "subvol=@home" ];
              };

              fileSystems."/boot" = {
                device = "/dev/disk/by-uuid/61F2-07D4";
                fsType = "vfat";
                options = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };

              swapDevices = [ ];

              nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
              hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
            }
          )

        ]
        ++ modulesFromConfig.options
        ++ (modulesFromConfig.nixosModules { inherit inputs; });
      };
    };
}
