{
  python312,
  lib,
  fetchFromGitHub,
  fetchPypi,
  packageOverrides ? self: super: {},
  pkgs,
}: let
  defaultOverrides = [
    # Override the version of some packages pinned in Home Assistant's setup.py and requirements_all.txt
    (self: super: {
      pydantic-settings = super.pydantic-settings.overridePythonAttrs (oldAttrs: rec {
        version = "2.3.4";
        src = fetchFromGitHub {
          owner = "pydantic";
          repo = "pydantic-settings";
          rev = "refs/tags/v${version}";
          hash = "sha256-tLF7LvsXryhbThaNl6koM0bGM8EOaA+aH2fGqzR8GKE=";
        };
      });

      pydantic = super.pydantic.overridePythonAttrs (oldAttrs: rec {
        version = "2.7.3";
        src = fetchFromGitHub {
          owner = "pydantic";
          repo = "pydantic";
          rev = "refs/tags/v${version}";
          hash = "sha256-L4w/vcSIFqftWR336/SmOPO1lHf3eMET1Fzy2gNrsc4=";
        };
      });

      pyperclip = super.pyperclip.overridePythonAttrs (oldAttrs: rec {
        pname = "pyperclip";
        version = "1.8.2";
        src = fetchPypi {
          inherit pname version;
          hash = "sha256-EFJUqLBJNPC8hOnCTrNgpZGq9lNcne9fKdkq8Qepv1c=";
        };
      });

      textual = super.textual.overridePythonAttrs (oldAttrs: rec {
        version = "0.74.0";
        src = fetchFromGitHub {
          owner = "Textualize";
          repo = "textual";
          rev = "refs/tags/v${version}";
          hash = "sha256-A+L0Qwt7qKbHRcUEx9YNvb0A9OXpyMFb2b0R2KzdGhc=";
        };
      });

      pytest = super.pytest.overridePythonAttrs (oldAttrs: rec {
        pname = "pytest";
        version = "8.3.1";
        src = fetchPypi {
          inherit pname version;
          hash = "sha256-fo5cWr1uk8scwVHyPletwx/PjP0qP/LaY+I/cy3jXbY=";
        };
        patches = [];
      });
    })
  ];

  python = python312.override {
    self = python;
    packageOverrides = lib.composeManyExtensions (defaultOverrides ++ [packageOverrides]);
  };
in
  python.pkgs.buildPythonPackage rec {
    pname = "posting";
    version = "1.10.1";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-II5CARCmWL8DcHllfmgIX9MThzwR8CcZZHw4hAlx+dA=";
    };

    build-system = with python.pkgs; [
      hatchling
    ];

    dependencies = with python.pkgs;
      [
        click
        xdg-base-dirs
        click-default-group
        httpx
        pyperclip
        pydantic
        pyyaml
        pydantic-settings
        python-dotenv
        textual
      ]
      ++ [(pkgs.callPackage ./textual-autocomplete.nix {})];
  }
