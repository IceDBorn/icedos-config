{
  inputs.icedos.url = "github:icedos/core";
  # inputs.icedos.url = "path:/home/ice/Projects/icedos/core";

  outputs =
    { icedos, self, ... }:
    icedos.lib.mkIceDOS {
      configRoot = self;
    };
}
