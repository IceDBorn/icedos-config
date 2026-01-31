{
  inputs.icedos.url = "github:icedos/core";

  outputs =
    { icedos, self, ... }:
    icedos.lib.mkIceDOS {
      configRoot = self;
    };
}
