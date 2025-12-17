{ pkgs, ... }:
let
  modsecurity-crs = pkgs.modsecurity-crs.overrideAttrs (_oldAttrs: {
    version = "4.16.0";
    src = pkgs.fetchFromGitHub {
      owner = "coreruleset";
      repo = "coreruleset";
      tag = "v4.16.0";
      hash = "sha256-RYCv5ujnzLua26OtGBi1r5+8qZKddmKb/8No4cfIhTE=";
    };
  });

  mainConf = pkgs.writeText "main.conf" ''
    Include /etc/nginx/modsec/modsecurity.conf
    Include /etc/nginx/modsec/crs-setup.conf
    Include /etc/nginx/modsec/rules/*.conf
  '';

  modsec = pkgs.runCommand "modsec" { } ''
    mkdir -p $out

    cp ${mainConf} $out/main.conf
    cp ${pkgs.libmodsecurity}/share/modsecurity/modsecurity.conf-recommended $out/modsecurity.conf
    ${pkgs.gnused}/bin/sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' $out/modsecurity.conf
    cp ${pkgs.libmodsecurity}/share/modsecurity/unicode.mapping $out/unicode.mapping
    cp ${modsecurity-crs}/share/modsecurity-crs/crs-setup.conf.example $out/crs-setup.conf
    cp -L -r ${modsecurity-crs}/rules $out/rules

    rm $out/rules/REQUEST-949-BLOCKING-EVALUATION.conf
  '';
in
{
  environment.systemPackages = [
    pkgs.libmodsecurity
    modsecurity-crs
  ];

  environment.etc."nginx/modsec" = {
    user = "nginx";
    group = "nginx";
    source = modsec;
  };

  services.nginx = {
    clientMaxBodySize = "500M";
    additionalModules = with pkgs.nginxModules; [ modsecurity ];
    appendHttpConfig = ''
      modsecurity on;
      modsecurity_rules_file /etc/nginx/modsec/main.conf;
    '';
  };
}
