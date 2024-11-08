{ lib
, python39
, fetchFromGitHub
, fetchurl
, darwin
}:

let
  # Define PyObjC wheel packages
  pyobjc-wheels = {
    pyobjc-core = {
      file = "pyobjc_core-10.3.1-cp39-cp39-macosx_10_9_universal2.whl";
      url = "https://files.pythonhosted.org/packages/b5/60/219460b689b10a8bdc0699e6512165b050545fbfc76c1ba5bc7f33c18bbd/pyobjc_core-10.3.1-cp39-cp39-macosx_10_9_universal2.whl";
      hash = "sha256-y5AfzmXJvkIMQNim7m//X/J8aUX0T9cZGYm5grqmbeo=";
    };
    pyobjc-framework-Cocoa = {
      file = "pyobjc_framework_Cocoa-10.3.1-cp39-cp39-macosx_10_9_universal2.whl";
      url = "https://files.pythonhosted.org/packages/70/52/0376b7548a73c724dfcf38623e6ec843dd3bf164ca6193c7ed145e60dded/pyobjc_framework_Cocoa-10.3.1-cp39-cp39-macosx_10_9_universal2.whl";
      hash = "sha256-dD0qGsCAJ/0J6rZYFMeQAqHQQh18AHT/0SF7ZWCIl0Q=";
    };
    pyobjc-framework-CoreServices = {
      file = "pyobjc_framework_CoreServices-10.3.1-cp36-abi3-macosx_11_0_universal2.whl";
      url = "https://files.pythonhosted.org/packages/82/41/a14f936b823d615bf799341adebed81b26bd641a0962e313f008bf23e0d6/pyobjc_framework_CoreServices-10.3.1-cp36-abi3-macosx_11_0_universal2.whl";
      hash = "sha256-zLZBE+5hKgUwirjtV+wiTiJEXVoSW+wR4kw11Y0fd+Q=";
    };
    pyobjc-framework-FSEvents = {
      file = "pyobjc_framework_FSEvents-10.3.1-cp36-abi3-macosx_11_0_universal2.whl";
      url = "https://files.pythonhosted.org/packages/b9/32/7d7b848cb444737bc87d86f38a1eadf52907e4525506b3e72d4dd9ebb944/pyobjc_framework_FSEvents-10.3.1-cp36-abi3-macosx_11_0_universal2.whl";
      hash = "sha256-KC6+66AZBST+HV0h1ynry3A043moA5pszfX1xuRHDgI=";
    };
  };

  # Create custom Python with PyObjC wheels
  newPython = python39.override {
    self = newPython;
    packageOverrides = pself: psuper: {
      pyobjc-core = pself.buildPythonPackage {
        pname = "pyobjc-core";
        version = "10.3.1";
        format = "wheel";
        src = fetchurl {
          inherit (pyobjc-wheels.pyobjc-core) url hash;
        };
      };

      pyobjc-framework-Cocoa = pself.buildPythonPackage {
        pname = "pyobjc-framework-Cocoa";
        version = "10.3.1";
        format = "wheel";
        src = fetchurl {
          inherit (pyobjc-wheels.pyobjc-framework-Cocoa) url hash;
        };
        propagatedBuildInputs = [ pself.pyobjc-core ];
      };

      pyobjc-framework-CoreServices = pself.buildPythonPackage {
        pname = "pyobjc-framework-CoreServices";
        version = "10.3.1";
        format = "wheel";
        src = fetchurl {
          inherit (pyobjc-wheels.pyobjc-framework-CoreServices) url hash;
        };
        propagatedBuildInputs = [ pself.pyobjc-core pself.pyobjc-framework-Cocoa ];
      };

      pyobjc-framework-FSEvents = pself.buildPythonPackage {
        pname = "pyobjc-framework-FSEvents";
        version = "10.3.1";
        format = "wheel";
        src = fetchurl {
          inherit (pyobjc-wheels.pyobjc-framework-FSEvents) url hash;
        };
        propagatedBuildInputs = [ pself.pyobjc-core ];
      };
    };
  };

  # Create Python environment with PyObjC
  pythonWithPyObjC = newPython.withPackages (ps: with ps; [
    pyobjc-core
    pyobjc-framework-Cocoa
    pyobjc-framework-CoreServices
    pyobjc-framework-FSEvents
  ]);
in
python39.pkgs.buildPythonApplication rec {
  pname = "finder-sidebar-editor";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "robperc";
    repo = "FinderSidebarEditor";
    rev = "master";
    sha256 = "sha256-WPYNxnCkaVziNt85RoJ6uJPkY1PhFiUKKcFl+rzUZ+o=";
  };

  #patches = [ ./debug.patch ];

  # Instead of patches, we'll modify the source directly
  postPatch = ''
    substituteInPlace FinderSidebarEditor.py \
      --replace "from LaunchServices import" "from CoreServices.LaunchServices import" \
      --replace "def __init__(self):" $'def __init__(self):\n        print("Initializing FinderSidebar...")' \
      --replace "def update(self):" $'def update(self):\n        print("Updating favorites...")'
  '';

  format = "other";

  buildInputs = [
    darwin.apple_sdk.frameworks.Cocoa
    darwin.apple_sdk.frameworks.CoreServices
    darwin.apple_sdk.frameworks.Foundation
  ];

  propagatedBuildInputs = [
    pythonWithPyObjC
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp FinderSidebarEditor.py $out/bin/finder-sidebar-editor.py

    # Create wrapper script that suppresses deprecation warnings
    cat > $out/bin/finder-sidebar-editor << EOF
    #!${pythonWithPyObjC}/bin/python3
    import warnings
    import sys
    import argparse
    import runpy

    warnings.filterwarnings("ignore", category=DeprecationWarning)

    # Run the script directly
    script = runpy.run_path("${placeholder "out"}/bin/finder-sidebar-editor.py")
    FinderSidebar = script['FinderSidebar']

    if __name__ == "__main__":
        sidebar = FinderSidebar()
        parser = argparse.ArgumentParser()
        parser.add_argument("--list", action="store_true", help="List current items")
        parser.add_argument("--add", help="Path to add")
        parser.add_argument("--name", help="Name for added path")
        parser.add_argument("--remove", help="Name of item to remove")
        args = parser.parse_args()

        if args.list:
            for name, path in sidebar.favorites.items():
                print(f"{name} -> {path}")
        elif args.add:
            sidebar.add(args.add)
        elif args.remove:
            sidebar.remove(args.remove)
    EOF
    chmod +x $out/bin/finder-sidebar-editor
  '';

  meta = with lib; {
    description = "Python tool to manage macOS Finder sidebar";
    homepage = "https://github.com/robperc/FinderSidebarEditor";
    platforms = platforms.darwin;
    mainProgram = "finder-sidebar-editor";
  };
} 