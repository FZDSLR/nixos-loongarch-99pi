self: super: {
  linuxPackages_loong99pi = super.linuxPackagesFor (
    super.callPackage ../pkgs/kernel {
      src = super.fetchgit {
        url = "https://gitee.com/FZDSLR/linux-kernel-for-99pi.git";
        rev = "7e09206df204e5d1d2a2d9525ea0e64fa1f5150b";
        sha256 = "sha256-E23QV3Q8PGlAGJj9VZsNGlsLJCLUPfqCZJ8uOc0qLqI=";
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

  unixbench = (super.unixbench.overrideAttrs (      
    finalAttrs: previousAttrs: {
      buildInputs = previousAttrs.buildInputs ++ [super.bash];
      preFixup = ''
        substituteInPlace $out/libexec/pgms/multi.sh \
          --replace '/bin/sh "$' '${super.bash}/bin/bash "$'
    
        substituteInPlace $out/bin/ubench \
          --subst-var out
    
        wrapProgram $out/bin/ubench \
          --prefix PATH : ${super.lib.makeBinPath previousAttrs.runtimeDependencies}
      '';
    }
  )).override {
    withGL = false;
    withX11perf = false;
    # runtimeShell = super.bash;
  };

  libseccomp-git = ( super.libseccomp.overrideAttrs (
    finalAttrs: previousAttrs: {
      version = "2.5.6";
      src = super.fetchurl {
        url = "https://github.com/seccomp/libseccomp/archive/2847f10dddca72167309c04cd09f326fd3b78e2f.tar.gz";
        sha256 = "sha256-QWj717SKfqKjblBr6SKGUR70SeWeRa/69tQhIFzh8PQ=";
      };
      preConfigure = ''
        sed -i -e "s/0.0.0/2.5.6/" configure.ac
        ./autogen.sh
      '';
      nativeBuildInputs = previousAttrs.nativeBuildInputs ++ [super.autoreconfHook];
      doCheck = false;
    }
  ));

  netavark = super.netavark.override (old: {
    rustPlatform = old.rustPlatform // {
      buildRustPackage = args: old.rustPlatform.buildRustPackage (args // {
        # override src/cargoHash/buildFeatures here
       version = "1.11.0";
       src = super.fetchgit {
          url = "https://github.com/containers/netavark.git";
          rev = "ab4f101a39b687c01e2df578162c2fa16a881c1b";
          sha256 = "sha256-X7AnOPX+Jvbfn6cOZUUv6vXp3v6yC9VFDqNElcQpsTk=";
       };
       cargoHash = "sha256-rHiOT0MYlxafGZU9aXIguf5C1gYvIz9PaRu+OpTQ1ss=";
       nativeBuildInputs = [super.go-md2man  super.installShellFiles super.mandown super.protobuf];
      });
    };
  });
  
  conmon = super.conmon.override {
    libseccomp = self.libseccomp-git;
  };

  crun = super.crun.override {
    libseccomp = self.libseccomp-git;
  };

  slirp4netns = super.slirp4netns.override {
    libseccomp = self.libseccomp-git;
  };

  podman = super.podman.override {
    extraRuntimes = [ self.crun ];
    libseccomp = self.libseccomp-git;
  };

  openldap = super.openldap.overrideAttrs {
    doCheck = false;
  };

  liburcu = super.liburcu.overrideAttrs (
    finalAttrs: previousAttrs: {
    # stdenv = super.withCFlags [" --host=loongarch64-linux-gnu"] super.stdenv;
      buildFlags = [" --host=loongarch64-unknown-linux-gnu"]; 
    }
  );

  openblas = super.openblas.overrideAttrs (old: {
    version = "0.3.28";
    src = super.fetchFromGitHub {
      owner = "OpenMathLib";
      repo = "OpenBLAS";
      rev = "v0.3.28";
      hash = "sha256-430zG47FoBNojcPFsVC7FA43FhVPxrulxAW3Fs6CHo8=";
    };
    patches = [];
    makeFlags = super.lib.lists.remove "BINARY=64" old.makeFlags;
  });

  opencv4 = super.opencv4.override {
    enableGStreamer = false;
    enableCuda = false;
 #   enableBlas = false;
    enableFfmpeg = false;
  };

  pythonOverrides = python-self: python-super: {
    opencv4f = python-super.toPythonModule((self.opencv4.overrideAttrs (old: {
      cmakeFlags = old.cmakeFlags ++ [
        "-DPYTHON3_INCLUDE_PATH=${python-self.python}/include/${python-self.python.libPrefix}"
        "-DPYTHON3_NUMPY_INCLUDE_DIRS=${python-self.numpy}/${python-self.python.sitePackages}/numpy/core/include"
      ];
    })).override {
      enablePython = true;
      pythonPackages = python-self;
    });

    onnx = python-super.onnx.overridePythonAttrs(old: rec {
      preConfigure = old.preConfigure + ''
        export CMAKE_ARGS+=" -DONNX_CUSTOM_PROTOC_EXECUTABLE=${super.protobuf_21}/bin/protoc -DONNX_USE_PROTOBUF_SHARED_LIBS=OFF "
      '';
      buildInputs = old.buildInputs ++ [super.protobuf_21];
    });

    luma-core = python-self.callPackage ../pkgs/luma/core.nix { };
    luma-oled = python-self.callPackage ../pkgs/luma/oled.nix { };
  };

  python311b = super.python311.override { packageOverrides = self.pythonOverrides; };


  cockpit = super.cockpit.overrideAttrs ( old: {
    # configureFlags = old.configureFlags ++ ["--with-pamdir=${super.pam}/include/security"];
    buildInputs = old.buildInputs ++ [super.pam];
    nativeBuildInputs = old.nativeBuildInputs ++[super.glib];
    #preConfigure = ''
    #  $CFLAGS = "$CFLAGS -I${super.pam}/include"
    #  $LDFLAGS = "$LDFLAGS -L${super.pam}/include"
    #'';
  });

  cockpit-podman = super.callPackage ../pkgs/cockpit-podman {};

# https://github.com/NixOS/nixpkgs/issues/226147
#  neovim-unwrapped = super.neovim-unwrapped.override {
#    lua = super.lua5_1;
#  };
#
#  neovim-loong = self.wrapNeovim self.neovim-unwrapped {};

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
