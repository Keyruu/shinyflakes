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

  # Override pcre2 to disable JIT to fix segfaults in sljit_free_exec during worker shutdown
  # See: https://github.com/PCRE2Project/pcre2/issues/399
  pcre2-no-jit = pkgs.pcre2.overrideAttrs (oldAttrs: {
    configureFlags = (oldAttrs.configureFlags or [ ]) ++ [ "--disable-jit" ];
  });

  # Create custom package set with JIT-disabled libmodsecurity
  customPkgs = pkgs.extend (
    final: prev: {
      libmodsecurity = prev.libmodsecurity.override {
        pcre2 = pcre2-no-jit;
      };
    }
  );

  mainConf = pkgs.writeText "main.conf" ''
    Include /etc/nginx/modsec/modsecurity.conf
    Include /etc/nginx/modsec/crs-setup.conf
    Include /etc/nginx/modsec/rules/*.conf
  '';

  modsec = pkgs.runCommand "modsec" { } ''
    mkdir -p $out

    cp ${mainConf} $out/main.conf
    cp ${customPkgs.libmodsecurity}/share/modsecurity/modsecurity.conf-recommended $out/modsecurity.conf

    # ${pkgs.gnused}/bin/sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' $out/modsecurity.conf

    cp ${customPkgs.libmodsecurity}/share/modsecurity/unicode.mapping $out/unicode.mapping
    cp ${modsecurity-crs}/share/modsecurity-crs/crs-setup.conf.example $out/crs-setup.conf

    cp -L -r ${modsecurity-crs}/rules $out/rules
    chmod -R +w $out/rules
    rm $out/rules/*-BLOCKING-EVALUATION.conf
  '';
in
{
  environment.systemPackages = [
    customPkgs.libmodsecurity
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
    # additionalModules = with customPkgs.nginxModules; [ modsecurity ];
    # fixes segfaults in workers, this might be related https://github.com/nginx/nginx/issues/1027
    # appendConfig = ''
    #   pcre_jit off;
    # '';
    # appendHttpConfig = ''
    #   modsecurity on;
    #   modsecurity_rules_file /etc/nginx/modsec/main.conf;
    # '';
  };
}
