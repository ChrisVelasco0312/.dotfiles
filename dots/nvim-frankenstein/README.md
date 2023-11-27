# FRANKENSTEIN NEOVIM CONFIGURATION

This is my experimental neovim configuration.
A work in progress. May contain bugs

Based on the following projects:

- [craftzdog/nvim](https://github.com/craftzdog/dotfiles-public)
- [kickstart](https://github.com/nvim-lua/kickstart.nvim)

### INSTALL

1.  Install dependencies:

    - [NVM](https://github.com/nvm-sh/nvm)
    - Fish terminal
    - tree-sitter CLI

2.  Clone and run fkstn-nvim:
    - `git clone https://github.com/ChrisVelasco0312/nvim-frankenstein ~/.config/nvim --depth 1 && nvim`

### ABOUT PACKER TO LAZY MIGRATION

It is important to delete the linked packer files in order to get lazy ready to work

- Remove the .local related files

  ```sh
  rm -rf ~/.local/share/nvim/site/pack/packer/start/packer.nvim
  ```
