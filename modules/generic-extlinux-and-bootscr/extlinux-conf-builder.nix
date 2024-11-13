{ pkgs }:

pkgs.substituteAll {
  src = ./extlinux-conf-builder.sh;
  isExecutable = true;
  path = [pkgs.coreutils pkgs.gnused pkgs.gnugrep pkgs.ubootTools];
  inherit (pkgs) bash;
}
