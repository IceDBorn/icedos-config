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
      url = "path:/nix/store/kssh1myfigjklcxqi5ary08xddyhh25q-icedos-config";
    };
    icedos-core = {
      follows = "icedos-config/icedos";
    };
    icedos-github_icedborn_claude-icedos = {
      url = "github:icedborn/claude-icedos/99014310750522eb69e9ab7fc9169decbc2222ba";
    };
    icedos-github_icedos_apps = {
      url = "github:icedos/apps/51645b8e5a02c41450d753fc23f2feb3e07a8582";
    };
    icedos-github_icedos_apps-celluloid-celluloid-shader = {
      flake = false;
      url = "path:///nix/store/5zcj323fgw0vxx0nhgvp45yxrwikm0c6-FSR.glsl";
    };
    icedos-github_icedos_apps-peon-ping-peon-ping = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:PeonPing/peon-ping";
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
    icedos-github_icedos_desktop = {
      url = "github:icedos/desktop/952740f23750d536edf77d29e87a546d1ed0607d";
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
      url = "github:icedos/hardware/9af16334830e466b37997a7647a93340d4398809";
    };
    icedos-github_icedos_hardware-cachyos-kernel-nix-cachyos-kernel = {
      url = "github:xddxdd/nix-cachyos-kernel/release";
    };
    icedos-github_icedos_kde = {
      url = "github:icedos/kde/1a8c05a3906132721ccfcc3ea3b183e1092bdae3";
    };
    icedos-github_icedos_kde-default-plasma-manager = {
      inputs = {
        home-manager = {
          follows = "home-manager";
        };
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:nix-community/plasma-manager";
    };
    icedos-github_icedos_mcp-server = {
      url = "github:icedos/mcp-server/7173a1922410298897a5ca84b9561be401ff9c16";
    };
    icedos-github_icedos_providers = {
      url = "github:icedos/providers/38af861c05150dc492dde0128be6941b8d648d75";
    };
    icedos-github_icedos_tweaks = {
      url = "github:icedos/tweaks/5eade42fe4fd3df43d3ce8ce7ea1594f2bb3f93d";
    };
    icedos-state = {
      flake = false;
      url = "path:/nix/store/im317kbma5zmkvxhf51hlywsp6m5s35i-icedos";
    };
    jovian = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:jovian-experiments/jovian-nixos";
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
      userConfig = import "${inputs.icedos-core}/lib/load-user-config.nix" "${inputs.icedos-config}";
      inherit (userConfig) icedos;

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

          # Extra modules and stateVersion. Each configured extra-module
          # directory (default `modules`) is scanned and imported; missing
          # ones are skipped.
          {
            imports = lib.flatten (
              map (
                d:
                let
                  p = "${inputs.icedos-config}/${d}";
                in
                if pathExists p then getModules p else [ ]
              ) [ "modules" ]
            );
            config.system.stateVersion = "25.11";
          }

          # Raw NixOS config passthrough: every top-level table in
          # config.toml / configs/*.toml *except* [icedos.*] is applied verbatim
          # as NixOS config. nixpkgs' module system types & validates each option —
          # IceDOS declares no schema. (home-manager is reachable the usual way,
          # under [home-manager.users.<name>.*].)
          (lib.setDefaultModuleLocation "config.toml / configs/*.toml (raw NixOS passthrough)" {
            config = builtins.removeAttrs userConfig [ "icedos" ];
          })

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
