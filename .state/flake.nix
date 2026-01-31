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
      url = "path:/nix/store/n9ixh0h3vga34pys5c7d3ii0czhgvv1l-icedos-config";
    };
    icedos-core = {
      follows = "icedos-config/icedos";
    };
    icedos-github_icedborn_claude-icedos = {
      url = "github:icedborn/claude-icedos/357779cee933b0b40021169e3eaea1b2331cce7d";
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
      url = "github:icedos/apps/2265e70f7087eba00e65e5de6d51d03fddd6d34c";
    };
    icedos-github_icedos_apps-celluloid = {
      inputs = { };
      url = "path:/nix/store/bakwi8d6hcgmmjnmrrr4nzvwjhwsbcix-icedos-github_icedos_apps-celluloid-subflake";
    };
    icedos-github_icedos_desktop = {
      url = "github:icedos/desktop/e98ac02a4f6286ced134a81bb55e3ca75a5d8fdd";
    };
    icedos-github_icedos_desktop-stylix = {
      inputs = {
        nixpkgs = {
          follows = "nixpkgs";
        };
      };
      url = "path:/nix/store/crb5iyljvk4kh2mf3bnb9a21v4l8jvbg-icedos-github_icedos_desktop-stylix-subflake";
    };
    icedos-github_icedos_hardware = {
      url = "github:icedos/hardware/e5919e73a73697fded43a24d0675d325bdf2256e";
    };
    icedos-github_icedos_hardware-cachyos-kernel = {
      inputs = { };
      url = "path:/nix/store/nl0j3c1b9kfq6myq2fwj2fmz5h44sffm-icedos-github_icedos_hardware-cachyos-kernel-subflake";
    };
    icedos-github_icedos_kde = {
      url = "github:icedos/kde/04c0ac1c0e662a9ac9b66aedeb25ef5843f01366";
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
      url = "path:/nix/store/7aczmhzngbc9q0dx2mfb2apjvbq0hdhw-icedos-github_icedos_kde-default-subflake";
    };
    icedos-github_icedos_mcp-server = {
      url = "github:icedos/mcp-server/943fb0130448cd09312f9bee61ea98e819fb1754";
    };
    icedos-github_icedos_providers = {
      url = "github:icedos/providers/5d7e31dc0d66939b2bf0525434fab1d1a95e35cd";
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
      url = "github:icedos/tweaks/b7b36923082a06bea76a79f4b60e5810a988ebf1";
    };
    icedos-github_icedos_virtualisation = {
      url = "github:icedos/virtualisation/f7cdb7e73347210e165d3e0d0bcd9c31d302ac07";
    };
    icedos-state = {
      flake = false;
      url = "path:/nix/store/j6wbfrphyisfksh1spjwjb6qn9ycy5j2-icedos";
    };
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
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
            "beekeeper-studio-6.0.5"
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
