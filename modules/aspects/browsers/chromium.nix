{ ... }:
{
  den.aspects.browsers.chromium = {
    homeManager =
      {
        pkgs,
        lib,
        ...
      }:
      {
        programs.chromium = {
          enable = true;
          extensions = [
            { id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa"; } # 1Password
            { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # SponsorBlock
            { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # Dark Reader
            { id = "gebbhagfogifgggkldgodflihgfeippi"; } # Return YouTube Dislike
            { id = "kcmipingpfbohfjckomimmahknoddnke"; } # Vicinae Integration
          ];
        };

        # chromeenterprise policies not covered by programs.chromium.
        # Skipped: ExtensionInstallForcelist — programs.chromium.extensions writes
        # External Extensions/<id>.json which is functionally equivalent.
        xdg.configFile."chromium/policies/managed/policies.json".text =
          builtins.toJSON {
            DefaultSearchProviderEnabled = true;
            DefaultSearchProviderName = "Uruky";
            DefaultSearchProviderKeyword = "uruky.com";
            DefaultSearchProviderSearchURL = "https://uruky.com/search?q={searchTerms}";
            DefaultSearchProviderNewTabURL = "https://uruky.com/";

            PasswordManagerEnabled = false;
            AutofillAddressEnabled = false;
            AutofillCreditCardEnabled = false;
          };
      };
  };
}