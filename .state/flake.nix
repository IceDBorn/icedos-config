{
  inputs = {
    home-manager = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:nix-community/home-manager/7b4c5ec4bedaf1e062bbc1bcaeddbc6bd242aa1b";
    };
    icedos-config = {
      url = "path:/nix/store/li1rhh7cy55a78a2bgc02b9ga4cbizgh-icedos-config";
    };
    icedos-core = {
      follows = "icedos-config/icedos";
    };
    icedos-github_icedborn_claude-icedos = {
      url = "github:icedborn/claude-icedos/6638f5628a95e4884391a1ad063fe25bdcc3b53a";
    };
    icedos-github_icedborn_dtek-tools = {
      url = "github:icedborn/dtek-tools/2d697e9c8aefdb9675517348b676be8eec4738c6";
    };
    icedos-github_icedborn_dtek-tools-opencart-mcp = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "path:/nix/store/k8cs1si8xqwfwy6m2pghxh9158l6qmm7-icedos-github_icedborn_dtek-tools-opencart-mcp-subflake";
    };
    icedos-github_icedos_apps = {
      url = "github:icedos/apps/85251afe6535da89711999caf2d476a90a300aac";
    };
    icedos-github_icedos_apps-celluloid = {
      inputs = { };
      url = "path:/nix/store/bakwi8d6hcgmmjnmrrr4nzvwjhwsbcix-icedos-github_icedos_apps-celluloid-subflake";
    };
    icedos-github_icedos_desktop = {
      url = "github:icedos/desktop/69cb21a9a9c57418054d16750ae723d0d88f0923";
    };
    icedos-github_icedos_desktop-stylix = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "path:/nix/store/pd7k8xibfqwaa05yzjrxqbwyixj7rldj-icedos-github_icedos_desktop-stylix-subflake";
    };
    icedos-github_icedos_hardware = {
      url = "github:icedos/hardware/7ae052bdfe21948a5a9b6084073ca46007159c4f";
    };
    icedos-github_icedos_hardware-cachyos-kernel = {
      inputs = { };
      url = "path:/nix/store/g4px6y5c80r4pxka18n58y90p363xgaw-icedos-github_icedos_hardware-cachyos-kernel-subflake";
    };
    icedos-github_icedos_kde = {
      url = "github:icedos/kde/fff4b8e1b46b84ff22c112328d1b0201a48ad825";
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
    icedos-github_icedos_mcp-server = {
      url = "github:icedos/mcp-server/25c79016e48849c10c0c2e5dddc4014544528509";
    };
    icedos-github_icedos_providers = {
      url = "github:icedos/providers/86f823cc597a496a3b8f4424ab3bb168d806303f";
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
      url = "github:icedos/tweaks/95c46f51bc85b1cbcc4d58bef2750581a26addab";
    };
    icedos-github_icedos_virtualisation = {
      url = "github:icedos/virtualisation/eac61965dc47fccc50f7f6c67f4a379b5ea6a4d8";
    };
    icedos-state = {
      flake = false;
      url = "path:/nix/store/j6wbfrphyisfksh1spjwjb6qn9ycy5j2-icedos";
    };
    nixpkgs = {
      url = "github:nixos/nixpkgs/7a0f122f5090cf4c2ade2a13a0e229d4e19ba71f";
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
            "beekeeper-studio-6.1.1"
          ];
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
                default = "/home/ice/.code/icedos/config/.state";
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
              boot.kernelModules = [ ];
              boot.extraModulePackages = [ ];

              fileSystems."/" = {
                device = "/dev/mapper/luks-f325f7e2-0c7c-4fff-9d4d-bf32766e8609";
                fsType = "xfs";
              };

              boot.initrd.luks.devices."luks-f325f7e2-0c7c-4fff-9d4d-bf32766e8609".device =
                "/dev/disk/by-uuid/f325f7e2-0c7c-4fff-9d4d-bf32766e8609";

              fileSystems."/boot" = {
                device = "/dev/disk/by-uuid/B097-9882";
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
