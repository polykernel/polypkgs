# Ported from https://github.com/NixOS/nixpkgs/blob/807e9154dcb16384b1b765ebe9cd2bba2ac287fd/pkgs/misc/cups/drivers/canon/default.nix

{
  dream2nix,
  config,
  lib,
  ...
}:

let
  inherit (config.deps) stdenv;

  system = if stdenv.hostPlatform.system == "x86_64-linux" then
    "intel"
  else if stdenv.hostPlatform.system == "aarch64-linux" then
    "arm"
  else
    throw "Unsupported platform for Canon UFRII Drivers: ${stdenv.hostPlatform.system}";

  version = "6.00";
  dl = "6/0100009236/20";
  region = "us";
  suffix = "02";

  ld64 = "${stdenv.cc}/nix-support/dynamic-linker";
  libs = lib.makeLibraryPath config.mkDerivation.buildInputs;

  versionNoDots = builtins.replaceStrings [ "." ] [ "" ] version;

  src_canon = config.deps.fetchurl {
    url = "https://gdlp01.c-wss.com/gds/${dl}/linux-UFRII-drv-v${versionNoDots}-${region}-${suffix}.tar.gz";
    hash = "sha256-lktesKcGsHOUMgmeq04KYck6qai/tS/ZN2ptB8F/n4s=";
  };
in
{
  imports = [
    dream2nix.modules.dream2nix.mkDerivation
  ];

  name = "canon-cups-ufr2";
  inherit version;

  deps = { nixpkgs, ... }: {
    inherit (nixpkgs)
      stdenv
      fetchurl
      pkg-config
      makeWrapper
      unzip
      autoconf
      automake
      libtool_1_5
      cups
      zlib
      jbigkit
      glib
      gtk3
      libxml2
      gdk-pixbuf
      pango
      cairo
      atk
      libredirect
      ghostscript
      ;
  };

  mkDerivation = {
    src = src_canon;

    nativeBuildInputs = with config.deps; [ makeWrapper unzip autoconf automake libtool_1_5 pkg-config ];

    buildInputs = with config.deps; [ cups zlib jbigkit glib gtk3 libxml2 gdk-pixbuf pango cairo atk ];

    postUnpack = ''
      (
        cd $sourceRoot
        tar -xf Sources/cnrdrvcups-lb-${version}-1.${suffix}.tar.xz
        sed -ie "s@_prefix=/usr@_prefix=$out@" cnrdrvcups-common-${version}/allgen.sh
        sed -ie "s@_libdir=/usr/lib@_libdir=$out/lib@" cnrdrvcups-common-${version}/allgen.sh
        sed -ie "s@_bindir=/usr/bin@_bindir=$out/bin@" cnrdrvcups-common-${version}/allgen.sh
        sed -ie "s@/usr@$out@" cnrdrvcups-common-${version}/{{backend,rasterfilter}/Makefile.am,rasterfilter/cnrasterproc.h}
        sed -ie "s@etc/cngplp@$out/etc/cngplp@" cnrdrvcups-common-${version}/cngplp/Makefile.am
        sed -ie "s@usr/share/cngplp@$out/usr/share/cngplp@" cnrdrvcups-common-${version}/cngplp/src/Makefile.am
        patchShebangs cnrdrvcups-common-${version}

        sed -ie "s@_prefix=/usr@_prefix=$out@" cnrdrvcups-lb-${version}/allgen.sh
        sed -ie "s@_libdir=/usr/lib@_libdir=$out/lib@" cnrdrvcups-lb-${version}/allgen.sh
        sed -ie "s@_bindir=/usr/bin@_bindir=$out/bin@" cnrdrvcups-lb-${version}/allgen.sh
        sed -ie '/^cd \.\.\/cngplp/,/^cd files/{/^cd files/!{d}}' cnrdrvcups-lb-${version}/allgen.sh
        sed -ie "s@cd \.\./pdftocpca@cd pdftocpca@" cnrdrvcups-lb-${version}/allgen.sh
        sed -ie "s@/usr@$out@" cnrdrvcups-lb-${version}/pdftocpca/Makefile.am
        sed -i "/CNGPLPDIR/d" cnrdrvcups-lb-${version}/Makefile
        patchShebangs cnrdrvcups-lb-${version}
      )
    '';

    installPhase = ''
      runHook preInstall

      (
        cd cnrdrvcups-common-${version}
        ./allgen.sh
        make install
      )
      (
        cd cnrdrvcups-common-${version}/Rule
        mkdir -p $out/share/cups/usb
        install -m 644 *.usb-quirks $out/share/cups/usb
      )
      (
        cd cnrdrvcups-lb-${version}
        ./allgen.sh
        make install

        mkdir -p $out/share/cups/model
        install -m 644 ppd/*.ppd $out/share/cups/model/
      )

      (
        cd lib
        mkdir -p $out/lib
        install -m 755 libs64/${system}/libColorGearCufr2.so.2.0.0 $out/lib
        install -m 755 libs64/${system}/libcaepcmufr2.so.1.0 $out/lib
        install -m 755 libs64/${system}/libcaiocnpkbidir.so.1.0.0 $out/lib
        install -m 755 libs64/${system}/libcaiousb.so.1.0.0 $out/lib
        install -m 755 libs64/${system}/libcaiowrapufr2.so.1.0.0 $out/lib
        install -m 755 libs64/${system}/libcanon_slimufr2.so.1.0.0 $out/lib
        install -m 755 libs64/${system}/libcanonufr2r.so.1.0.0 $out/lib
        install -m 755 libs64/${system}/libcnaccm.so.1.0 $out/lib
        install -m 755 libs64/${system}/libcnlbcmr.so.1.0 $out/lib
        install -m 755 libs64/${system}/libcnncapcmr.so.1.0 $out/lib
        install -m 755 libs64/${system}/libufr2filterr.so.1.0.0 $out/lib

        install -m 755 libs64/${system}/cnpdfdrv $out/bin
        install -m 755 libs64/${system}/cnpkbidir $out/bin
        install -m 755 libs64/${system}/cnpkmoduleufr2r $out/bin
        install -m 755 libs64/${system}/cnrsdrvufr2 $out/bin
        install -m 755 libs64/${system}/cnsetuputil2 $out/bin/cnsetuputil2

        mkdir -p $out/share/cnpkbidir
        install -m 644 libs64/${system}/cnpkbidir_info* $out/share/cnpkbidir

        mkdir -p $out/share/ufr2filter
        install -m 644 libs64/${system}/ThLB* $out/share/ufr2filter
      )

      (
        cd $out/lib

        ln -sf libColorGearCufr2.so.2.0.0 libColorGearCufr2.so
        ln -sf libColorGearCufr2.so.2.0.0 libColorGearCufr2.so.2
        ln -sf libcaepcmufr2.so.1.0 libcaepcmufr2.so
        ln -sf libcaepcmufr2.so.1.0 libcaepcmufr2.so.1
        ln -sf libcaiocnpkbidir.so.1.0.0 libcaiocnpkbidir.so
        ln -sf libcaiocnpkbidir.so.1.0.0 libcaiocnpkbidir.so.1
        ln -sf libcaiowrapufr2.so.1.0.0 libcaiowrapufr2.so
        ln -sf libcaiowrapufr2.so.1.0.0 libcaiowrapufr2.so.1
        ln -sf libcanon_slimufr2.so.1.0.0 libcanon_slimufr2.so
        ln -sf libcanon_slimufr2.so.1.0.0 libcanon_slimufr2.so.1
        ln -sf libcanonufr2r.so.1.0.0 libcanonufr2r.so
        ln -sf libcanonufr2r.so.1.0.0 libcanonufr2r.so.1
        ln -sf libcnlbcmr.so.1.0 libcnlbcmr.so
        ln -sf libcnlbcmr.so.1.0 libcnlbcmr.so.1
        ln -sf libufr2filterr.so.1.0.0 libufr2filterr.so
        ln -sf libufr2filterr.so.1.0.0 libufr2filterr.so.1
        ln -sf libuictlufr2r.so.1.0.0 libuictlufr2r.so
        ln -sf libuictlufr2r.so.1.0.0 libuictlufr2r.so.1

        patchelf --set-rpath "$(cat $NIX_CC/nix-support/orig-cc)/lib:${libs}:${stdenv.cc.cc.lib}/lib64:${stdenv.cc.libc}/lib64:$out/lib" libcanonufr2r.so.1.0.0
        patchelf --set-rpath "$(cat $NIX_CC/nix-support/orig-cc)/lib:${libs}:${stdenv.cc.cc.lib}/lib64:${stdenv.cc.libc}/lib64" libcaepcmufr2.so.1.0
        patchelf --set-rpath "$(cat $NIX_CC/nix-support/orig-cc)/lib:${libs}:${stdenv.cc.cc.lib}/lib64:${stdenv.cc.libc}/lib64" libColorGearCufr2.so.2.0.0
      )

      (
        cd $out/bin
        patchelf --set-interpreter "$(cat ${ld64})" --set-rpath "${libs}:${stdenv.cc.cc.lib}/lib64:${stdenv.cc.libc}/lib64" cnsetuputil2 cnpdfdrv
        patchelf --set-interpreter "$(cat ${ld64})" --set-rpath "${libs}:${stdenv.cc.cc.lib}/lib64:${stdenv.cc.libc}/lib64:$out/lib" cnpkbidir cnrsdrvufr2 cnpkmoduleufr2r cnjbigufr2

        wrapProgram $out/bin/cnrsdrvufr2 \
          --prefix LD_LIBRARY_PATH ":" "$out/lib" \
          --set LD_PRELOAD "${config.deps.libredirect}/lib/libredirect.so" \
          --set NIX_REDIRECTS /usr/bin/cnpkmoduleufr2r=$out/bin/cnpkmoduleufr2r:/usr/bin/cnjbigufr2=$out/bin/cnjbigufr2

        wrapProgram $out/bin/cnsetuputil2 \
          --set LD_PRELOAD "${config.deps.libredirect}/lib/libredirect.so" \
          --set NIX_REDIRECTS /usr/share/cnsetuputil2=$out/usr/share/cnsetuputil2
      )

      (
        cd lib/data/ufr2
        mkdir -p $out/share/caepcm
        install -m 644 *.ICC $out/share/caepcm
        install -m 644 *.icc $out/share/caepcm
        install -m 644 *.PRF $out/share/caepcm
        install -m 644 CnLB* $out/share/caepcm
      )

      (
        cd cnrdrvcups-utility-${version}/data
        mkdir -p $out/usr/share/cnsetuputil2
        install -m 644 cnsetuputil* $out/usr/share/cnsetuputil2
      )

      makeWrapper "${config.deps.ghostscript}/bin/gs" "$out/bin/gs" \
        --prefix LD_LIBRARY_PATH ":" "$out/lib" \
        --prefix PATH ":" "$out/bin"

      runHook postInstall
    '';
  };

  public = {
    meta = with lib; {
      description = "Canon UFR II/UFRII LT Linux printer drivers for CUPS";
      homepage = "https://www.canon.com/";
      sourceProvenance = [ sourceTypes.binaryNativeCode ];
      license = licenses.unfree;
      maintainers = [ maintainers.polykernel ];
      platforms = [ "x86_64-linux" "aarch64-linux" ];
    };
  };
}
