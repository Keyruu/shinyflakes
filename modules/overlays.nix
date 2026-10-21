{ inputs, lib, ... }:
let
  overlay = final: prev: {
    zellij = inputs.zellij.packages.${final.stdenv.hostPlatform.system}.default;
    # The pinned nixpkgs khal passes a list to sphinxHook, which expects a string.
    khal = prev.khal.overrideAttrs (_: { sphinxBuilders = "html man"; });
    # FIXME: Remove after nixpkgs includes https://github.com/NixOS/nixpkgs/pull/576504.
    linuxPackages_6_18 = prev.linuxPackages_6_18.extend (kernelFinal: kernelPrev: {
      ryzen-smu = kernelPrev.ryzen-smu.overrideAttrs (old: {
        preInstall = (old.preInstall or "") + ''
          make -C ${kernelFinal.kernel.dev}/lib/modules/${kernelFinal.kernel.modDirVersion}/build \
            M=$PWD INSTALL_MOD_PATH=$out INSTALL_MOD_DIR=kernel/drivers/ryzen_smu DEPMOD=true \
            ${lib.escapeShellArgs kernelFinal.kernel.commonMakeFlags} modules_install
        '';
        # Upstream's installPhase copies an unsigned .ko over Kbuild's compressed module.
        postInstall = (old.postInstall or "") + ''
          rm "$out/lib/modules/${kernelFinal.kernel.modDirVersion}/kernel/drivers/ryzen_smu/ryzen_smu.ko"
        '';
      });
    });
    # FIXME: Remove after nixpkgs includes https://github.com/NixOS/nixpkgs/pull/576469.
    linuxPackages_zen = prev.linuxPackages_zen.extend (kernelFinal: kernelPrev: {
      xpad-noone = kernelPrev.xpad-noone.overrideAttrs (old: {
        makeFlags = old.makeFlags ++ [
          "KERNEL_SRC=${kernelFinal.kernel.dev}/lib/modules/${kernelFinal.kernel.modDirVersion}/build"
          "INSTALL_MOD_PATH=${builtins.placeholder "out"}"
          "INSTALL_MOD_DIR=kernel/drivers/xpad-noone"
          "INSTALL_MOD_STRIP=1"
          "DEPMOD=true"
        ];
        installTargets = [ "modules_install" ];
        installFlags = [
          "-C"
          "${kernelFinal.kernel.dev}/lib/modules/${kernelFinal.kernel.modDirVersion}/build"
          "M=$(PWD)"
        ];
        installPhase = null;
        strictDeps = true;
        __structuredAttrs = true;
      });
    });
  };
in
{
  den.default.nixos.nixpkgs.overlays = [ overlay ];
  den.default.homeManager.nixpkgs.overlays = [ overlay ];

  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [ overlay ];
    };
  };
}
