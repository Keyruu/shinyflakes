import { strict as assert } from "node:assert";
import { describe, it } from "node:test";
import { createReviewScope, hasFilters, isInReviewScope } from "../scope.ts";

describe("createReviewScope", () => {
  it("returns empty scope with no env vars", () => {
    const scope = createReviewScope({});
    assert.deepEqual(scope.includePatterns, []);
    assert.deepEqual(scope.excludePatterns, []);
    assert.deepEqual(scope.includeExtensions, []);
    assert.deepEqual(scope.excludeExtensions, []);
  });

  it("parses include extensions with and without dots", () => {
    const scope = createReviewScope({ GUARDIAN_REVIEW_INCLUDE_EXTENSIONS: ".ts,tsx,.nix" });
    assert.deepEqual(scope.includeExtensions, [".ts", ".tsx", ".nix"]);
  });

  it("parses exclude extensions", () => {
    const scope = createReviewScope({ GUARDIAN_REVIEW_EXCLUDE_EXTENSIONS: ".lock,.snap" });
    assert.deepEqual(scope.excludeExtensions, [".lock", ".snap"]);
  });

  it("parses include patterns", () => {
    const scope = createReviewScope({ GUARDIAN_REVIEW_INCLUDE: "src/**/*.ts,*.nix" });
    assert.deepEqual(scope.includePatterns, ["src/**/*.ts", "*.nix"]);
  });

  it("parses exclude patterns", () => {
    const scope = createReviewScope({ GUARDIAN_REVIEW_EXCLUDE: "dist/**,*.generated.*" });
    assert.deepEqual(scope.excludePatterns, ["dist/**", "*.generated.*"]);
  });
});

describe("isInReviewScope", () => {
  it("allows everything with empty scope", () => {
    const scope = createReviewScope({});
    assert.ok(isInReviewScope("src/main.ts", scope));
    assert.ok(isInReviewScope("package.json", scope));
    assert.ok(isInReviewScope("any/file.lock", scope));
  });

  it("filters by include extensions", () => {
    const scope = createReviewScope({ GUARDIAN_REVIEW_INCLUDE_EXTENSIONS: ".ts,.tsx" });
    assert.ok(isInReviewScope("src/main.ts", scope));
    assert.ok(isInReviewScope("src/App.tsx", scope));
    assert.ok(!isInReviewScope("package.json", scope));
    assert.ok(!isInReviewScope("bun.lock", scope));
  });

  it("filters by exclude extensions", () => {
    const scope = createReviewScope({ GUARDIAN_REVIEW_EXCLUDE_EXTENSIONS: ".lock,.snap" });
    assert.ok(isInReviewScope("src/main.ts", scope));
    assert.ok(!isInReviewScope("bun.lock", scope));
    assert.ok(!isInReviewScope("test/__snapshots__/foo.snap", scope));
  });

  it("exclude extensions take precedence over include", () => {
    const scope = createReviewScope({
      GUARDIAN_REVIEW_INCLUDE_EXTENSIONS: ".ts,.lock",
      GUARDIAN_REVIEW_EXCLUDE_EXTENSIONS: ".lock",
    });
    assert.ok(isInReviewScope("src/main.ts", scope));
    assert.ok(!isInReviewScope("bun.lock", scope));
  });

  it("filters by include glob patterns", () => {
    const scope = createReviewScope({ GUARDIAN_REVIEW_INCLUDE: "src/**" });
    assert.ok(isInReviewScope("src/main.ts", scope));
    assert.ok(isInReviewScope("src/utils/helper.ts", scope));
    assert.ok(!isInReviewScope("dist/main.js", scope));
    assert.ok(!isInReviewScope("package.json", scope));
  });

  it("filters by exclude glob patterns", () => {
    const scope = createReviewScope({ GUARDIAN_REVIEW_EXCLUDE: "dist/**,node_modules/**" });
    assert.ok(isInReviewScope("src/main.ts", scope));
    assert.ok(!isInReviewScope("dist/main.js", scope));
    assert.ok(!isInReviewScope("node_modules/foo/index.js", scope));
  });

  it("exclude patterns take precedence over include", () => {
    const scope = createReviewScope({
      GUARDIAN_REVIEW_INCLUDE: "src/**",
      GUARDIAN_REVIEW_EXCLUDE: "src/generated/**",
    });
    assert.ok(isInReviewScope("src/main.ts", scope));
    assert.ok(!isInReviewScope("src/generated/types.ts", scope));
  });

  it("matches basename-only patterns against any path", () => {
    const scope = createReviewScope({ GUARDIAN_REVIEW_INCLUDE: "*.nix" });
    assert.ok(isInReviewScope("flake.nix", scope));
    assert.ok(isInReviewScope("nix/hosts/mentat/configuration.nix", scope));
    assert.ok(!isInReviewScope("src/main.ts", scope));
  });

  it("combines extensions and patterns", () => {
    const scope = createReviewScope({
      GUARDIAN_REVIEW_INCLUDE_EXTENSIONS: ".ts,.tsx",
      GUARDIAN_REVIEW_EXCLUDE: "src/generated/**",
    });
    assert.ok(isInReviewScope("src/main.ts", scope));
    assert.ok(!isInReviewScope("src/generated/types.ts", scope));
    assert.ok(!isInReviewScope("README.md", scope));
  });
});

describe("hasFilters", () => {
  it("returns false for empty scope", () => {
    assert.ok(!hasFilters(createReviewScope({})));
  });

  it("returns true when any filter is set", () => {
    assert.ok(hasFilters(createReviewScope({ GUARDIAN_REVIEW_INCLUDE: "*.ts" })));
    assert.ok(hasFilters(createReviewScope({ GUARDIAN_REVIEW_EXCLUDE: "*.lock" })));
    assert.ok(hasFilters(createReviewScope({ GUARDIAN_REVIEW_INCLUDE_EXTENSIONS: ".ts" })));
    assert.ok(hasFilters(createReviewScope({ GUARDIAN_REVIEW_EXCLUDE_EXTENSIONS: ".lock" })));
  });
});
