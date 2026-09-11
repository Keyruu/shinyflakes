{
  den.aspects.browsers.vivaldi = {
    homeManager =
      { inputs', ... }:
      {
        # Official HM module covers package + extensions via home.file.
        # Vivaldi reads External Extensions JSON from ~/.config/vivaldi/.
        programs.vivaldi = {
          enable = true;
          extensions = [
            "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password
            "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
            "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
            "gebbhagfogifgggkldgodflihgfeippi" # Return YouTube Dislike
            "kcmipingpfbohfjckomimmahknoddnke" # Vicinae Integration
          ];
          # Vicinae ships its native messaging host at
          # $out/etc/chromium/native-messaging-hosts/com.vicinae.vicinae.json —
          # the HM module joins + symlinks to ~/.config/vivaldi/NativeMessagingHosts.
          nativeMessagingHosts = [ inputs'.vicinae.packages.default ];
        };

        # chromeenterprise policies — same schema as helium's Layer A.
        # Vivaldi reads from ~/.config/vivaldi/policies/managed/.
        xdg.configFile."vivaldi/policies/managed/vivaldi.json".text = builtins.toJSON {
          DefaultSearchProviderEnabled = true;
          DefaultSearchProviderName = "Kagi";
          DefaultSearchProviderKeyword = "kagi.com";
          DefaultSearchProviderSearchURL = "https://kagi.com/search?q={searchTerms}";
          DefaultSearchProviderSuggestURL = "https://kagisuggest.com/api/autosuggest?q={searchTerms}";
          DefaultSearchProviderNewTabURL = "https://kagi.com/";

          PasswordManagerEnabled = false;
          AutofillAddressEnabled = false;
          AutofillCreditCardEnabled = false;
        };
      };
  };
}
