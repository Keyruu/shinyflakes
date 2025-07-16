{ pkgs, lib, ... }:
let
  modsecurity-crs = pkgs.modsecurity-crs.overrideAttrs (oldAttrs: {
    version = "4.16.0";
    src = pkgs.fetchFromGitHub {
      owner = "coreruleset";
      repo = "coreruleset";
      tag = "v4.16.0";
      hash = "sha256-RYCv5ujnzLua26OtGBi1r5+8qZKddmKb/8No4cfIhTE=";
    };
  });
in
{
  environment.systemPackages = [
    pkgs.libmodsecurity
    modsecurity-crs
  ];

  environment.etc."nginx/modsec/main.conf" = {
    user = "nginx";
    group = "nginx";
    text = ''
      Include /etc/nginx/modsec/modsecurity.conf
      Include /etc/nginx/modsec/crs-setup.conf
      Include /etc/nginx/modsec/rules/*.conf
    '';
  };

  # Copy ModSecurity rules to /etc
  system.activationScripts.modsecurity-rules = # sh
    ''
      mkdir -p /etc/nginx/modsec
      cp -f ${pkgs.libmodsecurity}/share/modsecurity/modsecurity.conf-recommended /etc/nginx/modsec/modsecurity.conf
      ${pkgs.gnused}/bin/sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/g' /etc/nginx/modsec/modsecurity.conf
      cp -f ${pkgs.libmodsecurity}/share/modsecurity/unicode.mapping /etc/nginx/modsec/unicode.mapping
      cp -f ${modsecurity-crs}/share/modsecurity-crs/crs-setup.conf.example /etc/nginx/modsec/crs-setup.conf
      rm -rf /etc/nginx/modsec/rules
      cp -rf ${modsecurity-crs}/rules /etc/nginx/modsec/rules
      rm /etc/nginx/modsec/rules/REQUEST-949-BLOCKING-EVALUATION.conf
      chown -R nginx:nginx /etc/nginx/modsec
    '';

  services.nginx = {
    clientMaxBodySize = "500M";
    additionalModules = with pkgs.nginxModules; [ modsecurity ];
  };
}
