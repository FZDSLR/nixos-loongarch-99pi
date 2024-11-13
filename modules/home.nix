{ config, pkgs, lib, ... }:

# let python =
#     let
#     packageOverrides = self:
#     super: {
#       opencv4 = super.opencv4.override {
#         enableGStreamer = false;
#         enableCuda = false;
#         enableFfmpeg = false;
# #        enablePython = true;
# #        pythonPackages = super;
#       };
#     };
#     in
#       pkgs.python3.override {inherit packageOverrides; self = python;};
# in
{
  home.username = "fzdslr";
  home.homeDirectory = "/home/fzdslr";

  home.packages = with pkgs;[
    which
    sl

    gcc13 
    gnumake

  ];

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting  
    '';
    shellAliases = {
      la = "eza --git --long --all --git --header";
    };
    plugins = [
      { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish; }
    ];
  };

  programs.eza = {
    enable = true;
  };

  programs.bat = {
    enable = true;
  };

  programs.vim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      vim-startify
    ];
  };

  programs.fastfetch = {
    enable = true;
    package = pkgs.fastfetch.override {
      rpmSupport = false;
      vulkanSupport = false;
      waylandSupport = false;
      x11Support = false;
    };
    settings = {
      logo = {
        type = "small";
      };
      display = {
        separator = "-> ";
        size = {
          binaryPrefix = "jedec";
        };
      };
      modules = [
        {
          type = "OS";
          key = "OS     ";
        }
        {
          type = "kernel";
          key = "Kernel ";
        }
        {
          type = "CPU";
          key = "CPU    ";
        }
        {
          type = "Memory";
          key = "Memory ";
        }
        {
          type = "Swap";
          key = "Swap   ";
        }
        {
          type = "Disk";
          key = "Disk   ";
        }
        {
          type = "uptime";
          key = "Uptime ";
        }
      ];
    };
  };

  home.stateVersion = "24.11";
  programs.home-manager.enable = true;
}
