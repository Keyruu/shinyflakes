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
      short = "d";
      description = "subdomain (result: <subdomain>.tunnel.peeraten.net)";
      required = true;
      argument = "NAME";
    }
    {
      name = "server";
      description = "frp server host";
      default = "100.67.0.1";
      argument = "ADDR";
    }
    {
      name = "server-port";
      short = "P";
      description = "frp server port";
      default = "7000";
      argument = "PORT";
    }
    {
      name = "token-file";
      short = "f";
      description = "path to file containing frp auth token";
      default = "";
      argument = "FILE";
    }
    {
      name = "token";
      short = "t";
      description = "frp auth token (prefer --token-file)";
      default = "";
      argument = "TOKEN";
    }
  ];

  script = ''
    if [ -z "$token" ] && [ -z "$token_file" ]; then
      die "Either --token or --token-file is required"
    fi

    TOKEN_VALUE="$token"
    if [ -n "$token_file" ]; then
      if [ ! -f "$token_file" ]; then
        die "Token file not found: $token_file"
      fi
      TOKEN_VALUE=$(cat "$token_file")
    fi

    blue "Exposing localhost:$port → https://$subdomain.tunnel.peeraten.net"
    echo ""

    ${pkgs.frp}/bin/frpc http \
      --server-addr "$server" \
      --server-port "$server_port" \
      --token "$TOKEN_VALUE" \
      --proxy-name "$subdomain" \
      --local-port "$port" \
      --sd "$subdomain"
  '';
}
