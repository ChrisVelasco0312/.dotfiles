# React Native devShell template

Copy `flake.nix` and `.envrc` into the **root of every new React Native project**,
then allow direnv to load it:

```bash
cp ~/.dotfiles/templates/react-native/flake.nix   ~/projects/myapp/flake.nix
cp ~/.dotfiles/templates/react-native/.envrc      ~/projects/myapp/.envrc
cd ~/projects/myapp
direnv allow
```

direnv (already configured system-wide) will auto-load the pinned
`nodejs_20` + `jdk17` + `watchman` + Android SDK paths the moment you `cd`
into the project. No global Node version changes, no `nix develop` to remember.

> After the first copy, run `nix flake update` inside the project periodically
> to pick up newer nixpkgs. Each project keeps its own `flake.lock`.

See `docs/react-native-development-workflow.md` for the full workflow.