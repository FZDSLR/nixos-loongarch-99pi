self: super: {
  linuxPackages_thead = super.linuxPackagesFor (
    super.callPackage ../pkgs/kernel {
      src = super.fetchgit {
        url = "https://gitee.com/FZDSLR/linux-kernel-for-99pi.git";
        rev = "245cd912625c7fa1640cf99b8087931613636dbf";
        sha256 = "sha256-6i45DsCUGr6Xo9s4T7D2iYGslrYx5VPEMGyWq8JMGpc=";
      };
      stdenv = super.gcc13Stdenv;
    }
  );

  # libressl 高版本在龙下无法过编译
  libressl = super.libressl_3_6;

  # musl 使用 1.2.5，低于此版本不支持龙架构

  musl = (
    super.musl.overrideAttrs (
      finalAttrs: previousAttrs: {
        version = "1.2.5";
        src = super.fetchurl {
          url = "https://musl.libc.org/releases/musl-1.2.5.tar.gz";
          sha256 = "sha256-qaEYu+hNh2TaDqDSizqz+uhHf8fkCF2QECuFlvx8deQ=";
        };
        patches = [
          (super.fetchurl {
            url = "https://raw.githubusercontent.com/openwrt/openwrt/87606e25afac6776d1bbc67ed284434ec5a832b4/toolchain/musl/patches/300-relative.patch";
            sha256 = "0hfadrycb60sm6hb6by4ycgaqc9sgrhh42k39v8xpmcvdzxrsq2n";
          })
        ];
      }
    )
  );

  ubootTools = (
    super.ubootTools.overrideAttrs (
      finalAttrs: previousAttrs: {
        version = "2024.04";
        src = super.fetchgit {
          url = "https://gitee.com/FZDSLR/uboot-la-99pi.git";
          rev = "52c5ac25f9542da6e1864fb77733d9b90726da1c";
          sha256 = "sha256-0jWwo0zUI3YjBfO2gSoWJ7W1fPx639pBnM598gQ88JI=";
        };
        patches = [ ];
      }
    )
  );

  dbus = super.dbus.override {
    enableSystemd = true;
  };

  systemd =
    (super.systemd.overrideAttrs (previousAttrs: rec {
      postInstall =
        let
          optionalString = self.lib.optionalString;
        in
        (previousAttrs.postInstall or "")
        + ''
          if [[ $out == *"systemd-loongarch64-unknown-linux-gnu"* ]]; then
          cat << EOF > $out/example/systemd/system/systemd-hibernate-clear.service     
          [Unit]
          Description=System Hibernate
          Documentation=man:systemd-hibernate.service(8)
          DefaultDependencies=no
          Requires=sleep.target
          After=sleep.target
            
          [Service]
          Type=oneshot
          ExecStart=$out/lib/systemd/systemd-sleep hibernate
          EOF

          cat << EOF > $out/example/systemd/system/systemd-bootctl@.service
          [Unit]
          Description=Boot Entries Service
          Documentation=man:bootctl(1)
          DefaultDependencies=no
          Conflicts=shutdown.target
          After=local-fs.target
          Before=shutdown.target

          [Service]
          Environment=LISTEN_FDNAMES=varlink
          ExecStart=$out/bin/bootctl
          EOF

          cat << EOF > $out/example/systemd/system/systemd-bootctl.socket
          [Unit]
          Description=Boot Entries Service Socket
          Documentation=man:bootctl(1)
          DefaultDependencies=no
          After=local-fs.target
          Before=sockets.target

          [Socket]
          ListenStream=/run/systemd/io.systemd.BootControl
          FileDescriptorName=varlink
          SocketMode=0600
          Accept=yes
          EOF

          cat << EOF > $out/example/systemd/system/systemd-creds@.service
          [Unit]
          Description=Credential Encryption/Decryption
          Documentation=man:systemd-creds(1)
          DefaultDependencies=no
          Conflicts=shutdown.target initrd-switch-root.target
          Before=shutdown.target initrd-switch-root.target

          [Service]
          Environment=LISTEN_FDNAMES=varlink
          ExecStart=$out/bin/systemd-creds
          EOF

          cat << EOF > $out/example/systemd/system/systemd-creds.socket
          [Unit]
          Description=Credential Encryption/Decryption
          Documentation=man:systemd-creds(1)
          DefaultDependencies=no
          Before=sockets.target

          [Socket]
          ListenStream=/run/systemd/io.systemd.Credentials
          FileDescriptorName=varlink
          SocketMode=0666
          Accept=yes
          MaxConnectionsPerSource=16
          EOF

          fi
        '';
    })).override
      {
        withTpm2Tss = false;
        # withEfi = false;
      };
}
