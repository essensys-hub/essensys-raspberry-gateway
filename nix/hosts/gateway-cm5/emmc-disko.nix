# eMMC layout for CM5 — matches essensys-prepare-nixos-mmc.sh (boot 512M + root ext4)
{ ... }:
{
  disko.devices = {
    disk.emmc = {
      type = "disk";
      device = "/dev/mmcblk0";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            priority = 1;
            name = "boot";
            start = "1MiB";
            size = "512MiB";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              extraArgs = [ "-F" "32" "-n" "boot" ];
              mountpoint = "/boot";
            };
          };
          root = {
            priority = 2;
            name = "root";
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              extraArgs = [ "-L" "nixos" ];
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
