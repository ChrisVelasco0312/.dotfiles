{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "node";
  nativeBuildInputs = with pkgs; [
    nodejs_20
  ];
  shellHook = ''
     export PATH="$PWD/node_modules/.bin/:$PATH"
  '';
}
