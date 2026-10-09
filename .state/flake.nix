{
  inputs = {
    home-manager = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:nix-community/home-manager/640725978b99076e18e069f6e7d2959124584f8f";
    };
    icedos-config = {
      url = "path:/nix/store/yp488smk6z2zpkkc6zsrw21hbjlbl2pm-icedos-config";
    };
    icedos-core = {
      follows = "icedos-config/icedos";
    };
    icedos-github_icedos_ai-tools = {
      url = "github:icedos/ai-tools/c3830568929cf3eaadbcaf0c44f72055d0fb1f28";
    };
    icedos-github_icedos_ai-tools-peon-ping = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "path:/nix/store/1ihkwk2ld2b8ip81bw7kjjqdfddaabnp-icedos-github_icedos_ai-tools-peon-ping-subflake";
    };
    icedos-github_icedos_apps = {
      url = "github:icedos/apps/3d8fc018a515dc8997cc5cbe608295ded498ae2d";
    };
    icedos-github_icedos_apps-celluloid = {
      inputs = { };
      url = "path:/nix/store/bakwi8d6hcgmmjnmrrr4nzvwjhwsbcix-icedos-github_icedos_apps-celluloid-subflake";
    };
    icedos-github_icedos_desktop = {
      url = "github:icedos/desktop/e455907ab3e74683adc31e0d0a31a3d8521431df";
    };
    icedos-github_icedos_desktop-stylix = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "path:/nix/store/ahf5f1xkybjfpaj4086ll3hpkab75s4h-icedos-github_icedos_desktop-stylix-subflake";
    };
    icedos-github_icedos_gaming = {
      url = "github:icedos/gaming/fe292022ff5e48e0fe8045e000ab1e5a65f83fc9";
    };
    icedos-github_icedos_gaming-prefixer = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "path:/nix/store/hz9x3wsnmqmlp0gpq5h3cxsdifar1krb-icedos-github_icedos_gaming-prefixer-subflake";
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
      url = "github:icedos/hardware/e77ea15dd1476b2a1ed06bc704f4b9bd0a102bd0";
    };
    icedos-github_icedos_hardware-cachyos-kernel = {
      inputs = { };
      url = "path:/nix/store/g4px6y5c80r4pxka18n58y90p363xgaw-icedos-github_icedos_hardware-cachyos-kernel-subflake";
    };
    icedos-github_icedos_kde = {
      url = "github:icedos/kde/44ae36eb6f87513a943e9975e18c0585fe3385af";
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
      url = "github:icedos/providers/05a5417205a6942ddb7cc9b135c59db4d267aa7e";
    };
    icedos-github_icedos_providers-jovian = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "path:/nix/store/mig8wny974gspz9l9a1i5bqa6a57d2k6-icedos-github_icedos_providers-jovian-subflake";
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
      url = "github:icedos/tweaks/66f93bb9618bb489221c251a7dc3ae4a9e00fda3";
    };
    icedos-state = {
      flake = false;
      url = "path:/nix/store/j6wbfrphyisfksh1spjwjb6qn9ycy5j2-icedos";
    };
    nixpkgs = {
      url = "github:nixos/nixpkgs/55bfb4d7437bd4e09ab7cba58a43bd68eb310044";
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
