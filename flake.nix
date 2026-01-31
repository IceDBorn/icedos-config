{
  inputs.icedos.url = "github:icedos/core";
  # inputs.icedos.url = "path:/mnt/storage/Projects/icedos/core";

  outputs =
    { icedos, self, ... }:
    icedos.lib.mkIceDOS {
      configRoot = self;
    };
}
