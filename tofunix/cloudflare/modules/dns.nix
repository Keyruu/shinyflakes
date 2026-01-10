{ lib, config, ... }:
let
  # Type that accepts strings or anything with __toString (like ref.x.y.z)
  refOrStrType = lib.types.mkOptionType {
    name = "refOrStr";
    description = "string or reference";
    check = val: builtins.isString val || val ? __toString;
  };

  singleValueRecordOptions = {
    content = lib.mkOption {
      type = refOrStrType;
      description = "DNS record content/value (string or reference)";
    };

    proxied = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = "Whether to proxy through Cloudflare. Defaults to true.";
    };

    cnames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Additional CNAME aliases pointing to this record";
    };
  };

  multiValueRecordOptions = {
    content = lib.mkOption {
      type = refOrStrType;
      description = "DNS record content/value (string or reference)";
    };

    proxied = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = "Whether to proxy through Cloudflare. Defaults to false for TXT and MX.";
    };

    priority = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Priority for MX and SRV records";
    };
  };
in
{
  options.cloudflare.zones = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          zoneId = lib.mkOption {
            type = refOrStrType;
            description = "Cloudflare zone ID (string or reference)";
          };

          records = lib.mkOption {
            type = lib.types.submodule {
              options = {
                a = lib.mkOption {
                  type = lib.types.attrsOf (lib.types.submodule { options = singleValueRecordOptions; });
                  default = { };
                  description = "A records (IPv4 addresses)";
                };

                aaaa = lib.mkOption {
                  type = lib.types.attrsOf (lib.types.submodule { options = singleValueRecordOptions; });
                  default = { };
                  description = "AAAA records (IPv6 addresses)";
                };

                cname = lib.mkOption {
                  type = lib.types.attrsOf (lib.types.submodule { options = singleValueRecordOptions; });
                  default = { };
                  description = "CNAME records";
                };

                mx = lib.mkOption {
                  type = lib.types.attrsOf (
                    lib.types.attrsOf (lib.types.submodule { options = multiValueRecordOptions; })
                  );
                  default = { };
                  description = "MX records (mail servers)";
                };

                txt = lib.mkOption {
                  type = lib.types.attrsOf (
                    lib.types.attrsOf (lib.types.submodule { options = multiValueRecordOptions; })
                  );
                  default = { };
                  description = "TXT records";
                };

                ns = lib.mkOption {
                  type = lib.types.attrsOf (
                    lib.types.attrsOf (lib.types.submodule { options = multiValueRecordOptions; })
                  );
                  default = { };
                  description = "NS records (nameservers)";
                };

                srv = lib.mkOption {
                  type = lib.types.attrsOf (
                    lib.types.attrsOf (lib.types.submodule { options = multiValueRecordOptions; })
                  );
                  default = { };
                  description = "SRV records";
                };
              };
            };
            default = { };
            description = "DNS records organized by type";
          };
        };
      }
    );
    default = { };
    description = "Cloudflare DNS zones and their records";
  };

  config = lib.mkIf (config.cloudflare.zones != { }) {
    resource.cloudflare_dns_record =
      let
        cfg = config.cloudflare.zones;

        sanitizeName =
          domain:
          let
            specialChars = lib.stringToCharacters "!\"#$%&'()*+,/:;<=>?[\\]^`{|}~_ ";
          in
          lib.pipe domain [
            (builtins.replaceStrings [ "@" "." ] [ "root" "-" ])
            (builtins.replaceStrings specialChars (map (_: "") specialChars))
          ];

        shouldProxy =
          recordType: record:
          if record.proxied != null then
            record.proxied
          else
            !(builtins.elem recordType [
              "TXT"
              "MX"
            ]);

        mkRecord =
          domain: zone: recordType: recordName: record:
          let
            typeUpper = lib.toUpper recordType;
            fullName = "${recordName}.${domain}";
            sanitizedName = sanitizeName fullName;
            resourceName = "${recordType}-${sanitizedName}${
              lib.optionalString (record.comment or null != null) "-${record.comment}"
            }";

            baseRecord = {
              zone_id = zone.zoneId;
              name = recordName;
              type = typeUpper;
              inherit (record) content;
              ttl = 1;
              proxied = shouldProxy typeUpper record;
            }
            // lib.optionalAttrs (record.priority or null != null) { inherit (record) priority; }
            // lib.optionalAttrs (record.comment or null != null) { inherit (record) comment; };
          in
          lib.nameValuePair resourceName baseRecord;

        mkCnameAliases =
          domain: zone: recordName: record:
          map (
            cname:
            let
              fullName = "${cname}.${domain}";
              sanitizedName = sanitizeName fullName;
              resourceName = "cname-${sanitizedName}";
            in
            lib.nameValuePair resourceName {
              zone_id = zone.zoneId;
              name = cname;
              type = "CNAME";
              content = "${recordName}.${domain}";
              ttl = 1;
              proxied = true;
            }
          ) (record.cnames or [ ]);

        mkSingleValueRecords =
          domain: zone: recordType: records:
          lib.pipe records [
            (lib.mapAttrsToList (
              recordName: record:
              [ (mkRecord domain zone recordType recordName record) ]
              ++ (mkCnameAliases domain zone recordName record)
            ))
            lib.flatten
          ];

        mkMultiValueRecords =
          domain: zone: recordType: records:
          lib.pipe records [
            (lib.mapAttrsToList (
              recordName: recordAttrs:
              lib.mapAttrsToList (
                recordKey: record: mkRecord domain zone recordType recordName (record // { comment = recordKey; })
              ) recordAttrs
            ))
            lib.flatten
          ];

        mkZoneRecords =
          domain: zone:
          let
            recs = zone.records or { };
          in
          lib.flatten [
            (lib.optionalAttrs (recs ? a) (mkSingleValueRecords domain zone "a" recs.a))
            (lib.optionalAttrs (recs ? aaaa) (mkSingleValueRecords domain zone "aaaa" recs.aaaa))
            (lib.optionalAttrs (recs ? cname) (mkSingleValueRecords domain zone "cname" recs.cname))

            (lib.optionalAttrs (recs ? mx) (mkMultiValueRecords domain zone "mx" recs.mx))
            (lib.optionalAttrs (recs ? txt) (mkMultiValueRecords domain zone "txt" recs.txt))
            (lib.optionalAttrs (recs ? ns) (mkMultiValueRecords domain zone "ns" recs.ns))
            (lib.optionalAttrs (recs ? srv) (mkMultiValueRecords domain zone "srv" recs.srv))
          ];

        allRecords = lib.flatten (lib.mapAttrsToList (domain: zone: mkZoneRecords domain zone) cfg);
      in
      builtins.listToAttrs allRecords;
  };
}
