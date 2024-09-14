{ lib, pkgs, ... }:
{
  nixpkgs.crossSystem = {
    system = "loongarch64-linux";
    config = "loongarch64-unknown-linux-gnu";
    linux-kernel = {
      name = "loong64";
      baseConfig = "defconfig";
      target = "uImage";
      DTB = true;
    };
  };
  # modules = [ (import ../overlays) ];
  nixpkgs.overlays = [(import ../overlays/default.nix)];
}
