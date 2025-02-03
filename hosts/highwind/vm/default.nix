{inputs, pkgs, ...}: {
  # hardware.opengl = {
  #   enable = true;
  # };
  # virtualisation.libvirt.enable = true;
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      ovmf.enable = true;
      runAsRoot = true;
      package = pkgs.qemu_kvm;
    };
  };

  environment.systemPackages = with pkgs; [
    virt-manager
  ];

  networking.bridges.br0.interfaces = ["eth0"];
  networking.interfaces.br0 = {
    useDHCP = false;
    ipv4.addresses = [{
      "address" = "192.168.100.11";
      "prefixLength" = 24;
    }];
  };

  # networking.interfaces.virbr0 = {
  #   useDHCP = false;
  #   ipv4.addresses = [
  #     {
  #       address = "192.168.100.11";
  #       prefixLength = 24;
  #     }
  #   ];
  # };
  #
  # virtualisation.libvirt.connections = {
  #   "qemu:///session".domains = [
  #     {
  #       definition = inputs.nixvirt.lib.domain.writeXML (
  #         inputs.nixvirt.lib.domain.templates.linux {
  #           name = "hass";
  #           uuid = "589ccdb2-9315-4c92-8eff-9bfdfcf3cd57";
  #           memory = {
  #             count = 8;
  #             unit = "GiB";
  #           };
  #           storage_vol = "/etc/haos/haos_ova.qcow2";
  #         }
  #       );
  #       active = true;
  #     }
  #   ];
  #
  #   "qemu:///system".networks = [
  #     {
  #       definition = inputs.nixvirt.lib.network.writeXML (inputs.nixvirt.lib.network.templates.bridge
  #         {
  #           bridge_name = "virbr0";
  #           uuid = "25279040-d7b7-454c-a8f4-50bfd64f5f4e";
  #           subnet_byte = 99;
  #         });
  #       active = true;
  #     }
  #   ];
  # };
}
