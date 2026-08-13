{ ... }:
{
  den.aspects.server.nginx-extras = {
    nixos = { ... }: {
      services.nginx.clientMaxBodySize = "5000M";
    };
  };
}
