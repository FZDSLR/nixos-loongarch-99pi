{ lib, pkgs, ... }:

let
  username = "loong";
  hostname = "loongarch-99pi";
  # To generate a hashed password run `mkpasswd`.
  # this is the hash of the password "loongarch"
  hashedPassword = "$y$j9T$.2iIfEhaIWmyGOWUY2Hus.$HfIWdv6xkxkCdtjNDCr7gFsKyHYSAi1opvKHqfwta64";
  # TODO replace this with your own public key!
  publickey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJYA3PS2P9GDKxQ/0XavUaCgHRDpvFQwnmytCQAHkX53 fzdslr_nixos_z3air";
in {
  # =========================================================================
  #      Users & Groups NixOS Configuration
  # =========================================================================

  networking.hostName = lib.mkDefault hostname;

  users.users.root = {
    openssh.authorizedKeys.keys = lib.mkDefault [
      publickey
    ];
  };

  users.users."${username}" = {
    inherit hashedPassword;

    isNormalUser = true;
    home = "/home/${username}";
    extraGroups = ["users" "networkmanager" "wheel" "docker"];
    openssh.authorizedKeys.keys = [
      publickey
    ];
  };

  users.groups = {
    "${username}" = {};
    docker = {};
  };
}
