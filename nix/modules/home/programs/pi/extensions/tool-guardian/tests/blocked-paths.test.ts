import { strict as assert } from "node:assert";
import { describe, it } from "node:test";
import { isBlockedPath } from "../utils.ts";

describe("isBlockedPath", () => {
  const blockedPaths = [
    // SOPS / secrets
    "/run/secrets/db-password",
    "/run/secrets/api-key",
    "nix/secrets.yaml",
    "nix/secrets.yml",
    ".sops.yaml",
    ".sops.yml",
    "keys/sops.age",

    // Env files
    ".env",
    ".env.local",
    ".env.production",
    ".env.staging",
    "app/.env",
    "app/.env.local",

    // SSH
    "/home/user/.ssh/id_ed25519",
    "/home/user/.ssh/id_rsa",
    "/home/user/.ssh/id_rsa.pub",
    "/home/user/.ssh/id_ecdsa",
    "/home/user/.ssh/authorized_keys",
    "/home/user/.ssh/known_hosts",
    "/home/user/.ssh/config",
    "~/.ssh/id_ed25519",

    // GPG / age
    "/home/user/.gnupg/private-keys-v1.d/key",
    "master-key.age",
    "keys/identity.age",

    // Credentials
    "/home/user/.netrc",
    "/home/user/.git-credentials",
    "/home/user/.npmrc",
    "/home/user/.docker/config.json",
  ];

  for (const p of blockedPaths) {
    it(`blocks: ${p}`, () => {
      assert.ok(isBlockedPath(p) !== undefined, `expected BLOCKED: ${p}`);
    });
  }

  const allowedPaths = [
    // Normal files
    "nix/hosts/mentat/configuration.nix",
    "nix/modules/nixos/core.nix",
    "src/main.ts",
    "README.md",
    "flake.nix",
    "package.json",

    // Env templates (should be allowed)
    ".env.example",
    ".env.sample",
    ".env.template",

    // Files that look similar but aren't secrets
    "docs/secrets-guide.md",
    "src/run/secrets.ts",
  ];

  for (const p of allowedPaths) {
    it(`allows: ${p}`, () => {
      assert.ok(isBlockedPath(p) === undefined, `expected ALLOWED: ${p}`);
    });
  }
});
