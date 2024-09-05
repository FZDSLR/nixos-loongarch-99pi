{
  description = "NixOS running on Loongarch 99pi";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable-small";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  }: let
    buildFeaturesKernel = {
      config = "loongarch64-linux";
      gcc.arch = "loongarch64";
    };

    overlay = (import ./overlays);

    pkgsKernelCross = import nixpkgs {
      localSystem = "x86_64-linux";
      crossSystem = buildFeaturesKernel;
      overlays = [overlay];
    };
  in {
    # expose this flake's overlay
    overlays.default = overlay;

    # cross-build an sd-image
    nixosConfigurations.loong99pi = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = {
        inherit nixpkgs;
      };
      modules = [
        ./modules/nixos-loong-cross-system.nix
        ./modules/loong99pi-conf.nix
        ./modules/sd-image/sd-image-99pi.nix
        ./modules/user-group.nix
        {nixpkgs.config.allowUnsupportedSystem = true;}
      ];
    };
    packages.x86_64-linux = {
      sdImage = self.nixosConfigurations.loong99pi.config.system.build.sdImage;

      pkgsKernelCross = pkgsKernelCross;
    };

    # use `nix develop .#fhsEnv` to enter the fhs test environment defined here.
    devShells.x86_64-linux.fhsEnv = let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        overlays = [overlay];
      };
    in
      # the code here is mainly copied from:
      #   https://nixos.wiki/wiki/Linux_kernel#Embedded_Linux_Cross-compile_xconfig_and_menuconfig
      (pkgs.buildFHSUserEnv {
        name = "kernel-build-env";
        targetPkgs = pkgs_: (with pkgs_;
          [
            # we need theses packages to run `make menuconfig` successfully.
            pkg-config
            ncurses

            pkgsKernelCross.gcc13Stdenv.cc
            gcc
            ubootTools
          ]
          ++ pkgs.linux.nativeBuildInputs);
        runScript = pkgs.writeScript "init.sh" ''
          # set the cross-compilation environment variables.
          # export CROSS_COMPILE=loongarch64-unknown-linux-gnu-
          export CROSS_COMPILE=loongarch64-linux-
          export ARCH=loongarch
          export PKG_CONFIG_PATH="${pkgs.ncurses.dev}/lib/pkg-config/"

          # set the CFLAGS and CPPFLAGS to enable the rv64gc and lp64d.
          # as described here:
          #   https://github.com/graysky2/kernel_compiler_patch#alternative-way-to-define-a--march-option-without-this-patch
          #  -mno-lasx -mno-lsx
          export KCFLAGS=' -march=loongarch64'
          export KCPPFLAGS=' -march=loongarch64'

          export MENUCONFIG_COLOR=mono

          exec bash
        '';
      })
      .env;
  };
}
