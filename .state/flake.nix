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
      url = "github:icedos/apps/42fec9b024c63a2ddb444ae13787dba107073f0b";
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
      url = "github:icedos/cosmic/b090ed269b49bc3f9cc2449cb3fd632bdb89a4ff";
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
      url = "github:icedos/desktop/947d4049c5108ecc2c70db6a08039793df654d16";
    };
    icedos-github_icedos_desktop-stylix-stylix = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:nix-community/stylix";
    };
    icedos-github_icedos_hardware = {
      url = "github:icedos/hardware/b72343db47f5859e1cbc2fe2dea552d6cd4975ea";
    };
    icedos-github_icedos_hardware-cachyos-kernel-nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
    };
    icedos-github_icedos_providers = {
      url = "github:icedos/providers/c1a5aa2f9cdfd58f0c58ea78a4905c6afa9c373e";
    };
    icedos-github_icedos_tweaks = {
      url = "github:icedos/tweaks/3bc12d831e0260e2d80d50e78d6d18301afe0370";
    };
    icedos-state = {
      flake = false;
      url = "path:/nix/store/2l5hwvv76crrz2nsgaba1mrgiq5g6299-icedos";
    };
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
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
        let
          inherit (lib) attrNames;
          dirs = attrNames (filterAttrs (n: v: v == "directory") (builtins.readDir path));
          hasDefaultNix = dir: pathExists "${path}/${dir}/default.nix";
        in
        map (dir: "/${path}/${dir}") (builtins.filter hasDefaultNix dirs);
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

          # Remove nixos manual package
          {
            documentation.nixos.enable = false;
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

          ({ networking.hostId = "f8e85e15"; })

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
