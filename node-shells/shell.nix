{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "node";
  nativeBuildInputs = with pkgs; [
    nodejs-18_x
    nodePackages."tree-sitter-cli"
  ];
  shellHook = ''
     export PATH="$PWD/node_modules/.bin/:$PATH"
  '';
}
