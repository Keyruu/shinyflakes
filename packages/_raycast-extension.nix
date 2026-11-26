# Builds one extension from raycast/extensions. Replaces vicinae's
# mkRayCastExtension, whose importNpmLock reads package-lock.json from the
# fetched source during eval (import-from-derivation); npmDepsHash avoids that.
{ buildNpmPackage, fetchFromGitHub }:
{
  name,
  rev,
  hash,
  npmDepsHash,
  ...
}@args:
buildNpmPackage (
  {
    inherit name npmDepsHash;
    src =
      fetchFromGitHub {
        owner = "raycast";
        repo = "extensions";
        inherit rev hash;
        sparseCheckout = [ "/extensions/${name}" ];
      }
      + "/extensions/${name}";

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r "$HOME/.config/raycast/extensions/"*/. $out/
      runHook postInstall
    '';
  }
  // removeAttrs args [
    "rev"
    "hash"
  ]
)
