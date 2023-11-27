build-flake:
	 sudo nixos-rebuild switch --flake .#nixos
build-home:
	home-manager switch --flake .#cavelasco@nixos
build:
	make build-flake
	make build-home
clean:
	nix-collect-garbage
	

