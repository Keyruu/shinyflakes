{ pkgs, perSystem, ... }:

perSystem.pog.pog.pog {
  name = "mesh-expose";
  description = "Expose a local port to the internet via frp tunnel";

  flags = [
    {
      name = "port";
      short = "p";
      description = "local port to expose";
      required = true;
      argument = "PORT";
    }
    {
      name = "subdomain";
      short = "s";
      description = "subdomain (result: <subdomain>.tunnel.peeraten.net)";
      required = true;
      argument = "NAME";
    }
    {
      name = "server";
      description = "frp server address";
      default = "100.67.0.1:7000";
      argument = "ADDR";
    }
    {
      name = "token-file";
      short = "t";
      description = "path to file containing frp auth token";
      default = "";
      argument = "FILE";
    }
    {
      name = "token";
      description = "frp auth token (prefer --token-file)";
      default = "";
      argument = "TOKEN";
    }
  ];

  script = ''
    if [ -z "$token" ] && [ -z "$token_file" ]; then
      die "Either --token or --token-file is required"
    fi

    AUTH_ARGS=""
    if [ -n "$token_file" ]; then
      if [ ! -f "$token_file" ]; then
        die "Token file not found: $token_file"
      fi
      AUTH_ARGS="--token-source file --token-source-file-path $token_file"
    else
      AUTH_ARGS="--token $token"
    fi

    blue "Exposing localhost:$port → https://$subdomain.tunnel.peeraten.net"
    echo ""

    ${pkgs.frp}/bin/frpc http \
      --server-addr "$server" \
      $AUTH_ARGS \
      --local-port "$port" \
      --subdomain "$subdomain"
  '';
}
