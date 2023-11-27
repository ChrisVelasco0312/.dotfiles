build-flake:
	 sudo nixos-rebuild switch --flake .#nixos
build-home:
	home-manager switch --flake .#cavelasco@nixos
build:
	make build-flake
	make build-home
backup-configs:
	home-manager switch -b backup --flake .#cavelasco@nixos
clean:
	nix-collect-garbage
	

