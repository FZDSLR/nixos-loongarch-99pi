{ lib, pkgs, ... }: {

  # =========================================================================
  #      Board specific configuration
  # =========================================================================

  boot = {
    kernelPackages = pkgs.linuxPackages_loong99pi; # 定义使用的内核版本
  
    initrd.includeDefaultModules = false;
    initrd.availableKernelModules = lib.mkForce [ # 内核模块
      "ext4" 
      "sd_mod" 
      "mmc_block" # "spi_nor"
      # "xhci_hcd"
      "usbhid" "hid_generic"
    ];
  };

  systemd.services."serial-getty@hvc0" = { # 虚拟控制台
    enable = false;
  };


  # Some filesystems (e.g. zfs) have some trouble with cross (or with BSP kernels?) here.
  boot.supportedFilesystems = lib.mkForce [
    "vfat"
    "ext4"
    "btrfs"
  ];

  # powerManagement.cpuFreqGovernor = "ondemand";

  networking.wireless.enable = true;
  networking.wireless.userControlled.enable = true;

  hardware = {
    deviceTree = { # 设备树
      name = "loongson_2k0300_99_pai_tfcard.dtb";
      overlays = [
        # custom deviceTree here
      ];
    };
    # enableRedistributableFirmware = true;

    # TODO GPU driver
    graphics = {
      enable = false;
    };

    # firmwares
    firmware = [
      # TODO add GPU firmware
    ];
  };

  services.xserver.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "unstable"; # Did you read the comment?

  # =========================================================================
  #      Base NixOS Configuration
  # =========================================================================

  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    git      # used by nix flakes
    curl
    fish
    vim

    neofetch
    # fastfetch
    # lm_sensors  # `sensors`
    htop     # replacement of htop/nmon

    openssl
    usbutils
    iw
    # Peripherals
 #   mtdutils
 #   i2c-tools
 #   minicom
  ];

  programs.ssh.package = pkgs.openssh;
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      X11Forwarding = lib.mkDefault false;
      PasswordAuthentication = lib.mkDefault true;
    };
    openFirewall = lib.mkDefault true;
  };

}
