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
      url = "path:/nix/store/xas7ydcx4q5k8psycznr6198c41rxb75-icedos-config";
    };
    icedos-config-_light-sync-ambiled = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "path:/home/ice/Projects/ambiled";
    };
    icedos-core = {
      follows = "icedos-config/icedos";
    };
    icedos-github_icedborn_claude-icedos = {
      url = "github:icedborn/claude-icedos/03643b9b8fe34fbe7b66a112393137a73def6d99";
    };
    icedos-github_icedborn_claude-icedos-peon-ping-peon-ping = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:PeonPing/peon-ping";
    };
    icedos-github_icedos_apps = {
      url = "github:icedos/apps/7f1238cf5f669182a8c3bbd4f79431e5a2453e6e";
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
      url = "github:icedos/cosmic/36b50a0b8b9e357e92756aad9347515ea020613d";
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
      url = "github:icedos/desktop/5076f66219a4791254103154b69c0348603feb05";
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
      url = "github:icedos/hardware/e3a407391d2bc89290fa8a43393db37a8d71252d";
    };
    icedos-github_icedos_hardware-cachyos-kernel-nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
    };
    icedos-github_icedos_providers = {
      url = "github:icedos/providers/c1a5aa2f9cdfd58f0c58ea78a4905c6afa9c373e";
    };
    icedos-github_icedos_tweaks = {
      url = "github:icedos/tweaks/13a2a6c4a6bac229b5a980398c70c54783ff2845";
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
          permittedInsecurePackages = [ ];
        };
      };

      inherit (pkgs) lib;
      inherit (builtins) pathExists;
      inherit (import "${inputs.icedos-core}/lib/load-user-config.nix" "${inputs.icedos-config}") icedos;

      icedosLib = import "${inputs.icedos-core}/lib" {
        inherit lib pkgs inputs;
        config = icedos;
        self = toString inputs.icedos-core;
      };

      inherit (icedosLib) getModules modulesFromConfig;
    in
    {
      nixosConfigurations."icedos" = nixpkgs.lib.nixosSystem rec {
        specialArgs = {
          inherit icedosLib inputs;
        };

        modules = [
          # Read configuration location
          (
            { icedosLib, ... }:
            let
              inherit (icedosLib) mkStrOption;
            in
            {
              options.icedos.configurationLocation = mkStrOption {
                default = "/home/ice/Projects/icedos/config/.state";
              };
            }
          )

          # Remove nixos manual package
          {
            documentation.nixos.enable = false;
          }

          {
            imports = getModules "${inputs.icedos-core}/modules";
          }

          # Extra modules and stateVersion
          {
            imports =
              if (pathExists "${inputs.icedos-config}/extra-modules") then
                (getModules "${inputs.icedos-config}/extra-modules")
              else
                [ ];
            config.system.stateVersion = "25.11";
          }

          home-manager.nixosModules.home-manager

          { icedos.system.isFirstBuild = true; }

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
                device = "/dev/mapper/luks-8f9e6414-43d5-4056-a538-88f9d10a6d77";
                fsType = "xfs";
              };

              boot.initrd.luks.devices."luks-8f9e6414-43d5-4056-a538-88f9d10a6d77".device =
                "/dev/disk/by-uuid/8f9e6414-43d5-4056-a538-88f9d10a6d77";

              fileSystems."/boot" = {
                device = "/dev/disk/by-uuid/D592-A386";
                fsType = "vfat";
                options = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };

              fileSystems."/mnt/docker-ssd" = {
                device = "/dev/disk/by-uuid/a795d62e-67e9-4c15-9282-f48bc70a0cbc";
                fsType = "xfs";
              };

              fileSystems."/mnt/games-hdd" = {
                device = "/dev/disk/by-uuid/c56f7d1d-7def-4971-9e54-4e01561e71c2";
                fsType = "xfs";
              };

              fileSystems."/mnt/games-ssd" = {
                device = "/dev/disk/by-uuid/3a5b4f50-c315-442e-902f-13df1153a2d9";
                fsType = "xfs";
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
