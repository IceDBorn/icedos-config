{
  inputs = {
    home-manager = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:nix-community/home-manager/095fef2f265c3c0da4fe315efba8f8a04495ab34";
    };
    icedos-config = {
      url = "path:/nix/store/nv758b2d19kfcpzqd6vycrd3fdwm9ryn-icedos-config";
    };
    icedos-core = {
      follows = "icedos-config/icedos";
    };
    icedos-github_icedos_ai-tools = {
      url = "github:icedos/ai-tools/94fc9da46e1bc5d08b3c32ae6a0be3d9799c4cff";
    };
    icedos-github_icedos_apps = {
      url = "github:icedos/apps/cf1e087a72fb64696132c03d1865176a6a112a80";
    };
    icedos-github_icedos_apps-celluloid = {
      inputs = { };
      url = "path:/nix/store/bakwi8d6hcgmmjnmrrr4nzvwjhwsbcix-icedos-github_icedos_apps-celluloid-subflake";
    };
    icedos-github_icedos_desktop = {
      url = "github:icedos/desktop/c96c1d7379833847a443ca633008111da022e990";
    };
    icedos-github_icedos_desktop-stylix = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "path:/nix/store/6r0qnzbbs6rdk0dqcyzx98cpkfz18nfs-icedos-github_icedos_desktop-stylix-subflake";
    };
    icedos-github_icedos_gaming = {
      url = "github:icedos/gaming/3f1b5ed78536f1465b92bb4e50332e39646dd8b0";
    };
    icedos-github_icedos_gaming-prefixer = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "path:/nix/store/zszsym00k2qwd5jal9kl4x607g2wrck0-icedos-github_icedos_gaming-prefixer-subflake";
    };
    icedos-github_icedos_gaming-proton-launch = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "path:/nix/store/b42rsxan9wnxbvk89hxc97c1rczny6hc-icedos-github_icedos_gaming-proton-launch-subflake";
    };
    icedos-github_icedos_hardware = {
      url = "github:icedos/hardware/6f16a2fd6c58c6de0b87a9738698f340ea0af11c";
    };
    icedos-github_icedos_hardware-cachyos-kernel = {
      inputs = { };
      url = "path:/nix/store/dk3jyk8alw5i7qcpdg0985q0h7s5qlnh-icedos-github_icedos_hardware-cachyos-kernel-subflake";
    };
    icedos-github_icedos_kde = {
      url = "github:icedos/kde/27837d1f0dd7c8a55cc9137e45cbd157e96ba7c0";
    };
    icedos-github_icedos_kde-default = {
      inputs = {
        home-manager = {
          follows = "home-manager";
        };
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "path:/nix/store/6y1w7vvy6kfy1mgadqyqjqp53f8xbrsb-icedos-github_icedos_kde-default-subflake";
    };
    icedos-github_icedos_providers = {
      url = "github:icedos/providers/efbf9c9e0ab2b7eb56ddd0dcacfc31273229a55f";
    };
    icedos-github_icedos_providers-jovian = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "path:/nix/store/kmacmpj0xk72j4f9dqljzfamvdsqvwpk-icedos-github_icedos_providers-jovian-subflake";
    };
    icedos-github_icedos_providers-nur = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "path:/nix/store/c4kbdm8j9zl9vl23mgclszb7cki87n36-icedos-github_icedos_providers-nur-subflake";
    };
    icedos-github_icedos_tweaks = {
      url = "github:icedos/tweaks/f986891bcf3fa9863e368a7a99f03117f093a158";
    };
    icedos-state = {
      flake = false;
      url = "path:/nix/store/ywfvylv4b5z7gpnds112xf7y31na0ar1-icedos";
    };
    nixpkgs = {
      url = "github:nixos/nixpkgs/0bb2eedc20e4739f29e8045034f2828ad7054f8f";
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
      userConfig = import "${inputs.icedos-core}/lib/config/load-user-config.nix" "${inputs.icedos-config
      }";
      inherit (userConfig) icedos;

      icedosLib = import "${inputs.icedos-core}/lib" {
        inherit lib pkgs inputs;
        config = icedos;
        enableLogging = false;
        self = toString inputs.icedos-core;
      };

      inherit (icedosLib) getModules modulesFromConfig;

      # Re-derived, not interpolated: this stage reads the filtered snapshot.
      extraOptionsDeclare = icedosLib.extraOptions.declare (userConfig.extraOptions or { });
    in
    {
      # The same value `specialArgs.icedosLib` gets, so repl-context and MCP
      # `nix_eval` read the lib the module system actually used.
      icedosLib = modulesFromConfig.closureLib;

      nixosConfigurations.icedos = nixpkgs.lib.nixosSystem rec {
        specialArgs = {
          # Reused (not re-merged), so module files and the module system share
          # one lib. Genflake-side uses below keep the base `icedosLib`.
          icedosLib = modulesFromConfig.closureLib;
          inherit inputs;
        };

        modules = [
          # Read configuration location
          (
            { icedosLib, ... }:
            let
              inherit (icedosLib) mkStrOption;
            in
            {
              # config.toml values already abort at genflake ("option does not
              # exist"); readOnly guards module-set values at build stage.
              options.icedos.configurationLocation = mkStrOption {
                readOnly = true;
                default = "/home/ice/Projects/icedos/config/.state";
              };
            }
          )

          # Remove nixos manual package
          {
            documentation.nixos.enable = false;
          }

          # repo url -> names, computed from the RAW config (no circularity).
          # Backs `icedosLib.hasModule`.
          {
            icedos.system.loadedModules = modulesFromConfig.loadedModules;
          }

          {
            imports = getModules "${inputs.icedos-core}/modules";
          }

          # Extra modules and stateVersion; missing dirs are skipped.
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

          # Every top-level table except [icedos.*] is applied verbatim as NixOS
          # config; `extraOptions` is a schema, not values, so it is excluded.
          (lib.setDefaultModuleLocation "config.toml / configs/*.toml (raw NixOS passthrough)" {
            config = builtins.removeAttrs userConfig [
              "icedos"
              "extraOptions"
            ];
          })

          extraOptionsDeclare

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
