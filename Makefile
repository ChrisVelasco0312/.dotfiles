show-cmds:
	cat Makefile
flake:
	sudo nixos-rebuild switch --flake .#nixos
update:
	sudo nixos-rebuild switch --upgrade --flake .#nixos
home:
	home-manager switch --flake .#cavelasco@nixos 
build:
	make build-flake
	make build-home
backup-configs:
	home-manager switch -b backup --flake .#cavelasco@nixos
clean:
	nix-collect-garbage
