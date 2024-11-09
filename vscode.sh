#!/usr/bin/env bash

# Array of extensions in format: "publisher name version"
extensions=(
    "equinusocio vsc-material-theme 34.7.5"
    "equinusocio vsc-material-theme-icons 3.8.8"
    "fill-labs dependi 0.7.10"
    "formulahendry auto-close-tag 0.5.15"
    "github copilot-chat 0.21.2"
    "github vscode-github-actions 0.27.0"
    "hbenl test-explorer 2.22.1"
    "hdevalke rust-test-lens 1.0.0"
    "jscearcy rust-doc-viewer 4.2.0"
    "ms-vscode-remote remote-containers 0.388.0"
    "ms-vscode makefile-tools 0.11.13"
    "ms-vscode test-adapter-converter 0.2.0"
    "nomicfoundation hardhat-solidity 0.8.6"
    "pkief material-icon-theme 5.12.0"
    "ritwickdey liveserver 5.7.9"
    "swellaby vscode-rust-test-adapter 0.11.0"
    "usernamehw errorlens 3.20.0"
)

for ext in "${extensions[@]}"; do
    read -r publisher name version <<< "$ext"
    echo "Fetching hash for $publisher.$name@$version"
    hash=$(nix-prefetch-url --unpack "https://marketplace.visualstudio.com/_apis/public/gallery/publishers/$publisher/vsextensions/$name/$version/vspackage")
    echo "\"$publisher.$name@$version\": \"$hash\","
done