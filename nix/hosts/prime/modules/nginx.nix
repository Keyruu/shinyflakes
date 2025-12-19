{ pkgs, lib, ... }:
let
  # renovate: datasource=github-releases depName=coreruleset/coreruleset
  crsVersion = "v4.21.0";
  modsecurity-crs = pkgs.modsecurity-crs.overrideAttrs (_oldAttrs: {
    version = crsVersion;
    src = pkgs.fetchFromGitHub {
      owner = "coreruleset";
      repo = "coreruleset";
      tag = crsVersion;
      hash = "sha256-mItipTFsRug0y7dyRCkWcqaWDcDetT35SiSKG/RDsII=";
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

    # ${pkgs.gnused}/bin/sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' $out/modsecurity.conf
    # increase pcre limits because of segfaults produces by the complex owasp rules
    ${pkgs.gnused}/bin/sed -i 's/SecPcreMatchLimit 1000/SecPcreMatchLimit 500000/g' $out/modsecurity.conf
    ${pkgs.gnused}/bin/sed -i 's/SecPcreMatchLimitRecursion 1000/SecPcreMatchLimitRecursion 500000/g' $out/modsecurity.conf

    cp ${pkgs.libmodsecurity}/share/modsecurity/unicode.mapping $out/unicode.mapping
    cp ${modsecurity-crs}/share/modsecurity-crs/crs-setup.conf.example $out/crs-setup.conf

    cp -L -r ${modsecurity-crs}/rules $out/rules
    chmod -R +w $out/rules
    rm $out/rules/*-BLOCKING-EVALUATION.conf
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
    package = pkgs.nginxMainline;
    additionalModules = with pkgs.nginxModules; [ modsecurity ];
    appendHttpConfig = ''
      modsecurity on;
      modsecurity_rules_file /etc/nginx/modsec/main.conf;
    '';
  };
}
