{
  # inputs.icedos.url = "github:icedos/core";
  inputs.icedos.url = "path:/home/ice/.code/icedos/core";

  outputs =
    { icedos, self, ... }:
    icedos.lib.mkIceDOS {
      configRoot = self;
    };
}
