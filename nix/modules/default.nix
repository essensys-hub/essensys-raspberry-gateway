{
  imports = [
    ./essensys/default.nix
    ./essensys/nginx.nix
    ./essensys/backend.nix
    ./essensys/frontend.nix
    ./essensys/traefik.nix
    ./essensys/redis.nix
    ./essensys/mosquitto.nix
    ./essensys/optional-services.nix
    ./gateway/dual-nic.nix
    ./gateway/dnsmasq-armoire.nix
    ./gateway/nvme-layout.nix
    ./platform/cm5-rpi5.nix
  ];
}
