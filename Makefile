show-cmds:
	cat Makefile

.i-home:
	@if command -v home-manager > /dev/null; then \
		echo "Home Manager is already installed. Skipping installation."; \
		exit 0; \
	else \
		nix-channel --add https://github.com/nix-community/home-manager/archive/release-24.11.tar.gz home-manager; \
		nix-channel --update; \
		nix-shell '<home-manager>' -A install; \
	fi

flake:
	sudo nixos-rebuild switch --flake .#nixos --impure
	make home

update:
	sudo nixos-rebuild switch --upgrade --flake .#nixos --impure

home: .i-home
	home-manager switch --flake .#cavelasco@nixos 

build:
	make flake

backup-configs:
	home-manager switch -b backup --flake .#cavelasco@nixos

clean:
	nix-collect-garbage

wallpaper-fix:
	rm -f ~/.cache/album_covers/rofi_list_cache.txt
	python3 ~/.dotfiles/dots/hypr/wallpaper-picker.py --recent --force
