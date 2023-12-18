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
      nodePackages.eslint
      nodePackages.prettier
    ];

    extraLuaConfig = ''
      ${builtins.readFile ./nvim-lua/init.lua } 
      ${builtins.readFile ./nvim-lua/base.lua } 
      ${builtins.readFile ./nvim-lua/maps.lua }
      -- plugins config
      ${builtins.readFile ./nvim-lua/plugins/telescope.lua }
      ${builtins.readFile ./nvim-lua/plugins/autopairs.lua }
      ${builtins.readFile ./nvim-lua/plugins/autotag.lua }
      ${builtins.readFile ./nvim-lua/plugins/bufferline.lua }
      ${builtins.readFile ./nvim-lua/plugins/cmp.lua }
      ${builtins.readFile ./nvim-lua/plugins/lsp-config.lua }
      ${builtins.readFile ./nvim-lua/plugins/mason.lua }
      ${builtins.readFile ./nvim-lua/plugins/onedark.lua }
      ${builtins.readFile ./nvim-lua/plugins/treesitter.lua }
      ${builtins.readFile ./nvim-lua/plugins/prettier.lua }
      ${builtins.readFile ./nvim-lua/plugins/null-ls.lua }
      ${builtins.readFile ./nvim-lua/plugins/lualine.lua }
    '';

    plugins = with pkgs.vimPlugins; [
      # you can use plugins from the pkgs
      vim-which-key
      nvim-treesitter.withAllGrammars
      ## telescope
      telescope-nvim
      telescope-fzf-native-nvim
      telescope-file-browser-nvim
      ## misc
      nvim-autopairs
      bufferline-nvim
      ## autocompletion
      nvim-cmp
      cmp-nvim-lsp
      lspkind-nvim
      cmp_luasnip
      cmp-buffer
      luasnip
      ##  lsp
      nvim-lspconfig
      mason-nvim
      mason-lspconfig-nvim
      neodev-nvim
      ## theme
      onedark-nvim
      ## copilot
      #TODO: Add codeium configurations
      # codeium-vim
      plenary-nvim
      nvim-ts-autotag
      no-neck-pain-nvim
      vim-prettier
      null-ls-nvim
      lualine-nvim
      nvim-web-devicons
      vim-startify
      comment-nvim
      vim-fugitive
      vim-rhubarb
    ];
  };
}
