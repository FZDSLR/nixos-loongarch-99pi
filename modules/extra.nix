{ lib, pkgs, nixpkgs, ... }: {

  users.users."fzdslr" = {
    hashedPassword = "$y$j9T$NZY7.GJLZWNyMlxD/XWQq/$ireCUMLao7t/mT/jrInr.ADGR8eVzUnHYhKw81qIYT8";

    isNormalUser = true;
    home = "/home/fzdslr";
    extraGroups = ["users" "networkmanager" "wheel" "docker" "spi" "i2c" "gpio" "navidrome"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYA3PS2P9GDKxQ/0XavUaCgHRDpvFQwnmytCQAHkX53 fzdslr_nixos_z3air"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHU/bF4HG69uDm/JkNYUJi8RdmHK0N7YanuLgK8GaMFd fzdslr@qq.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIALKfA+7TiISP4WoSVU4QORt9VmAJFcBpSglRrMQCxc+ fzdslr-win-to-go"
    ];
  };

  users.users.root = {
    hashedPassword = "$y$j9T$W66K1V8tXxYsCfTTXrQeT1$sSayRSX/4hnjuI2XKI5M1dczYy8uM/gy/F0CVSbDSe";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYA3PS2P9GDKxQ/0XavUaCgHRDpvFQwnmytCQAHkX53 fzdslr_nixos_z3air"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHU/bF4HG69uDm/JkNYUJi8RdmHK0N7YanuLgK8GaMFd fzdslr@qq.com"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIALKfA+7TiISP4WoSVU4QORt9VmAJFcBpSglRrMQCxc+ fzdslr-win-to-go"
    ];
  };

  networking.hostName = "LoongArch99pi-NixOS";

  networking.firewall.enable = false;

  nixpkgs.config.allowUnfree = true;

  hardware.i2c.enable = true;

  users.groups.gpio = {};
  users.groups.spi = {};
  services.udev.extraRules = ''
    SUBSYSTEM=="gpio", KERNEL=="gpiochip*", ACTION=="add", RUN+="${pkgs.bash}/bin/bash -c 'chown root:gpio /sys/class/gpio/export /sys/class/gpio/unexport ; chmod 220 /sys/class/gpio/export /sys/class/gpio/unexport'"
    SUBSYSTEM=="gpio", KERNEL=="gpio*", ACTION=="add",RUN+="${pkgs.bash}/bin/bash -c 'chown root:gpio /sys%p/active_low /sys%p/direction /sys%p/edge /sys%p/value ; chmod 660 /sys%p/active_low /sys%p/direction /sys%p/edge /sys%p/value'"
    SUBSYSTEM=="spidev", KERNEL=="spidev1.0", GROUP="spi", MODE="0660"
  '';

  imports = lib.optional (builtins.pathExists ./secret.nix) ./secret.nix;

  environment.systemPackages = with pkgs; [
    file
    tree
    gnutar
    p7zip

    cowsay

    podman-tui # status of containers in the terminal
    docker-compose

    (python311b.withPackages (ps: with ps;[
      requests
      flask
      spidev
      numpy
      opencv4f
      pillow
      smbus2
      python-periphery
      luma-oled
      uptime
      distro
      psutil
    ]))

    cockpit-podman
  ];

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };

  services.nginx = {
    enable = true;
    virtualHosts."127.0.0.1" = {
      root = "/var/www/site-1/";
    };
  };

  networking.firewall.allowedTCPPorts = [ 80 ];
  system.activationScripts = {
    installNginx = ''
      mkdir -p /var/www/site-1 #
      chown -R nginx:nginx /var/www/site-1

      # Create the index.html file and add the content
      cat <<EOF > /var/www/site-1/index.html
      <html>
      <head>
      <meta http-equiv="Content-Type" content="text/html;charset=utf-8"/>
      </head>
      <body>
      <center>
      <h1> 对，对吗？ </h1>
      <p> 啊对的对的，啊不对不对 </p>
      </center>
      </body>
      </html>
      EOF

      chown nginx:nginx /var/www/site-1/index.html
      '';
  };

  services.cockpit = {
    enable = true;
    openFirewall = true;
  };

  services.navidrome = {
    enable= true;
    openFirewall = true;
    settings.Port = 1453;
    settings.Address = "0.0.0.0";
    settings = {
      MusicFolder = "/media/music";
      DefaultLanguage = "zh-Hans";
      EnableTranscodingConfig = "true";
      DefaultTheme = "Catppuccin Macchiato";
    };
  };

  virtualisation.containers.enable = true;
  virtualisation = {
    podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };
}
