{ config, pkgs, lib, ... }:
{
  programs.neovim = {
    enable = true;
  	viAlias = true;
    vimAlias = true;

    # read in the vim config from filesystem
    # this enables syntaxhighlighting when editing those
    # extraConfig = builtins.concatStringsSep "\n" [
      #(lib.strings.fileContents ./plugins.vim)
      #(lib.strings.fileContents ./lsp.vim)

      # this allows you to add lua config files
      # ''
      #   lua << EOF
      #   ${lib.strings.fileContents ./config.lua}
      #   ${lib.strings.fileContents ./lsp.lua}
      #   EOF
      # ''
    # ];

    extraPackages = with pkgs; [
      tree-sitter
      nodePackages.typescript
      nodePackages.typescript-language-server 
    ];

    extraLuaConfig = ''
      ${builtins.readFile ./nvim-lua/init.lua } 
      ${builtins.readFile ./nvim-lua/base.lua } 
      ${builtins.readFile ./nvim-lua/plugins/telescope.lua }
    '';

    plugins = with pkgs.vimPlugins; [
      # you can use plugins from the pkgs
      vim-which-key
      nvim-treesitter.withAllGrammars
      telescope-nvim
      telescope-fzf-native-nvim
      telescope-file-browser-nvim
    ];
  };
}