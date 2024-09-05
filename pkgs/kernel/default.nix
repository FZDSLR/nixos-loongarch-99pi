# =================================================================================================
# function `buildLinux`:
#   https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/os-specific/linux/kernel/generic.nix
# Note that this method will use the deconfig in source tree, 
# commbined the common configuration defined in pkgs/os-specific/linux/kernel/common-config.nix, 
# it't not suitable for embedded systems, so we can NOT use it here.
# Instead, we need to use the method `linuxManualConfig` to build the kernel.
# =================================================================================================

# If you already have a generated configuration file, you can build a kernel that uses it with pkgs.linuxManualConfig
# The difference between deconfig and the generated configuration file is that the generated configuration file is more complete,
# 
{
  lib,
  src,
  stdenv,
  ubootTools,
  linuxManualConfig,
  buildPackages,
  ...
}:
(linuxManualConfig {
  version = "6.9.0-rc7";
  modDirVersion = "6.9.0-rc7";

  inherit src lib stdenv;
  
  # path to the generated kernel config file
  # 
  # you can generate the config file based on the revyos_defconfig 
  # by running `make revyos_defconfig` in the kernel source tree.
  # and then copy the generated file(`.config`) to ./revyos_config in the same directory of this file.
  # 
  #   make revyos_defconfig   # generate the config file from revyos_defconfig (the default config file)
  #   make menuconfig        # view and modify the generated config file(.config) via Terminal UI
  #                          # input / to search, Ctrl+Backspace to delete.
  #
  # and need to add these three lines to the end of the generated config file:
  #   CONFIG_DMIID=y
  #   CONFIG_VECTOR=n
  #   CONFIG_THEAD_ISA=n
  configfile = ./ls2k0300_99_pai_tfcard_config;
  
  # extraMeta.branch = "lp4a";

  allowImportFromDerivation = true;

  extraMakeFlags = ["-j1"];
}).overrideAttrs (old: {
  name = "k"; # shorten the kernel name, dodge uboot length limits, otherwise it will make uboot fail to load kernel. 
  nativeBuildInputs = old.nativeBuildInputs ++ [ubootTools];
  buildFlags = ["vmlinuz.efi"] ++ old.buildFlags;

  postInstall = let 
    modDirVersion = "6.9.0-rc7"; 
  in
  ''
    mkdir -p $dev
    cp vmlinux $dev/
    cp arch/loongarch/boot/uImage.gz $out/uImage
    if [ -z "''${dontStrip-}" ]; then
      installFlagsArray+=("INSTALL_MOD_STRIP=1")
    fi
    make modules_install $makeFlags "''${makeFlagsArray[@]}" \
      $installFlags "''${installFlagsArray[@]}"
    unlink $out/lib/modules/${modDirVersion}/build
    rm -f $out/lib/modules/${modDirVersion}/source
 
    mkdir -p $dev/lib/modules/${modDirVersion}/{build,source}
 
    # To save space, exclude a bunch of unneeded stuff when copying.
    (cd .. && rsync --archive --prune-empty-dirs \
        --exclude='/build/' \
        * $dev/lib/modules/${modDirVersion}/source/)
 
    cd $dev/lib/modules/${modDirVersion}/source
 
    cp $buildRoot/{.config,Module.symvers} $dev/lib/modules/${modDirVersion}/build
    make modules_prepare $makeFlags "''${makeFlagsArray[@]}" O=$dev/lib/modules/${modDirVersion}/build
 
    # For reproducibility, removes accidental leftovers from a `cc1` call
    # from a `try-run` call from the Makefile
    rm -f $dev/lib/modules/${modDirVersion}/build/.[0-9]*.d
 
    # Keep some extra files on some arches (powerpc, aarch64)
    for f in arch/powerpc/lib/crtsavres.o arch/arm64/kernel/ftrace-mod.o; do
      if [ -f "$buildRoot/$f" ]; then
        cp $buildRoot/$f $dev/lib/modules/${modDirVersion}/build/$f
      fi
    done
 
    # !!! No documentation on how much of the source tree must be kept
    # If/when kernel builds fail due to missing files, you can add
    # them here. Note that we may see packages requiring headers
    # from drivers/ in the future; it adds 50M to keep all of its
    # headers on 3.10 though.
 
    chmod u+w -R ..
    arch=$(cd $dev/lib/modules/${modDirVersion}/build/arch; ls)
 
    # Remove unused arches
    for d in $(cd arch/; ls); do
      if [ "$d" = "$arch" ]; then continue; fi
      if [ "$arch" = arm64 ] && [ "$d" = arm ]; then continue; fi
      rm -rf arch/$d
    done
 
    # Remove all driver-specific code (50M of which is headers)
    rm -fR drivers
 
    # Keep all headers
    find .  -type f -name '*.h' -print0 | xargs -0 -r chmod u-w
 
    # Keep linker scripts (they are required for out-of-tree modules on aarch64)
    find .  -type f -name '*.lds' -print0 | xargs -0 -r chmod u-w
 
    # Keep root and arch-specific Makefiles
    chmod u-w Makefile arch/"$arch"/Makefile*
 
    # Keep whole scripts dir
    chmod u-w -R scripts
 
    # Delete everything not kept
    find . -type f -perm -u=w -print0 | xargs -0 -r rm
 
    # Delete empty directories
    find -empty -type d -delete
  '';
#  preInstall = old.preInstall + ''\necho $PWD'' ;
#  preInstall = let 
#    installkernel = buildPackages.writeShellScriptBin "installkernel" ''
#      cp -av $2 $4
#      cp -av $3 $4
#      ls --all
#      echo $PWD
#      echo $2
#      cp -av $(dirname "$2")/uImage $4
#      echo "error" >&2
#      '';
#    in ''
#      installFlagsArray+=("-j1")
#      export HOME=${installkernel}
#    '';
})
