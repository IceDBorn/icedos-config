{
  inputs = {
    home-manager = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "github:nix-community/home-manager/c58f54c733a7894d84fa2fdff26cc12088c4b78c";
    };
    icedos-config = {
      url = "path:/nix/store/x2rk203dy3pfx8f4qq5c056s5k0nfh25-icedos-config";
    };
    icedos-core = {
      follows = "icedos-config/icedos";
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
    icedos-github_icedos_ai-tools = {
      url = "github:icedos/ai-tools/702b816bdf4385e481fe00e960b85ce8770a1172";
    };
    icedos-github_icedos_apps = {
      url = "github:icedos/apps/b525aeb2a7865d7c9ff02beb2c448f3a19c5dc57";
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
    icedos-github_icedos_hardware = {
      url = "github:icedos/hardware/20dac88403173aa9831721428bb8c7a9aab4295c";
    };
    icedos-github_icedos_hardware-cachyos-kernel = {
      inputs = { };
      url = "path:/nix/store/g4px6y5c80r4pxka18n58y90p363xgaw-icedos-github_icedos_hardware-cachyos-kernel-subflake";
    };
    icedos-github_icedos_kde = {
      url = "github:icedos/kde/d8b459de425a492a94323ba1e46cc314c502ab22";
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
      url = "github:icedos/providers/05a5417205a6942ddb7cc9b135c59db4d267aa7e";
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
      url = "github:icedos/tweaks/aecc0335e62253e80f5c614a575499531fab1f14";
    };
    icedos-github_icedos_virtualisation = {
      url = "github:icedos/virtualisation/eac61965dc47fccc50f7f6c67f4a379b5ea6a4d8";
    };
    icedos-overlay-github_nixos_nixpkgs_nixos-unstable-small = {
      url = "github:nixos/nixpkgs/nixos-unstable-small";
    };
    icedos-state = {
      flake = false;
      url = "path:/nix/store/j6wbfrphyisfksh1spjwjb6qn9ycy5j2-icedos";
    };
    nixpkgs = {
      url = "github:nixos/nixpkgs/7fd4004d0511991fff3a0524856a9be09e28c5f0";
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
            "beekeeper-studio-6.1.4"
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

          ({ config, lib, ... }: {
            # Head of the list, so the source swap runs BEFORE downstream
            # `overrideAttrs` patch overlays it would otherwise clobber.
            nixpkgs.overlays = lib.mkBefore (
              icedosLib.pkgs.overlaysFromChannel config.icedos
                inputs."icedos-overlay-github_nixos_nixpkgs_nixos-unstable-small"
                [ "typescript-language-server" ]
            );
          })

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
