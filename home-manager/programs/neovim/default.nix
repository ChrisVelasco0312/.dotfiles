{ 
  # config, 
  pkgs, 
  # lib, 
  # inputs, 
  ... 
}:
{ programs.neovim = 
  let
    # toLua = str: "lua << EOF\n${str}\nEOF\n";
    toLuaFile = file: "lua << EOF\n${builtins.readFile file}\nEOF\n";
  in
  {
    enable = true;
  	viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [
      tree-sitter
      nodePackages.vscode-langservers-extracted
      nodePackages.typescript
      nodePackages.typescript-language-server 
      nodePackages.eslint
      luajitPackages.lua-lsp
      # rnix-lsp
      nil
    ];

    extraLuaConfig = ''
      ${builtins.readFile ./nvim-lua/init.lua } 
      ${builtins.readFile ./nvim-lua/base.lua } 
      ${builtins.readFile ./nvim-lua/maps.lua }
      -- plugins config
      ${builtins.readFile ./nvim-lua/plugins/autotag.lua }
      ${builtins.readFile ./nvim-lua/plugins/autopairs.lua }
      ${builtins.readFile ./nvim-lua/plugins/telescope.lua }
      ${builtins.readFile ./nvim-lua/plugins/trouble.lua }
      ${builtins.readFile ./nvim-lua/plugins/git.lua }
    '';

  plugins = with pkgs.vimPlugins; [
      ## telescope dependencies
      telescope-nvim
      telescope-fzf-native-nvim
      telescope-file-browser-nvim
      nvim-autopairs
      {
        plugin = oil-nvim;
        config = toLuaFile ./nvim-lua/plugins/oil.lua;
      }
      {
        plugin = nvim-lspconfig;
        config = toLuaFile ./nvim-lua/plugins/lsp.lua;
      }
      lsp-colors-nvim
      trouble-nvim
      {
        plugin = bufferline-nvim;
        config = toLuaFile ./nvim-lua/plugins/bufferline.lua;
      }
      {
        plugin = own-lualine-nvim;
        config = toLuaFile ./nvim-lua/plugins/lualine.lua;
      }
      plenary-nvim
      lspkind-nvim
      ## autocompletion
      {
        plugin = nvim-cmp;
        config =  toLuaFile ./nvim-lua/plugins/cmp.lua;
      }
      nvim-cmp
      cmp-nvim-lsp
      cmp_luasnip
      cmp-buffer
      {
        plugin = onedark-nvim;
        config =  toLuaFile ./nvim-lua/plugins/onedark.lua;
      }
      {
        plugin = vim-prettier;
        config = toLuaFile ./nvim-lua/plugins/prettier.lua;
      }
      {
        plugin = null-ls-nvim;
        config = toLuaFile ./nvim-lua/plugins/null-ls.lua;
      }
      {
        plugin = nvim-treesitter.withAllGrammars;
        config = toLuaFile ./nvim-lua/plugins/treesitter.lua;
      }
      {
        plugin = no-neck-pain-nvim;
        config = toLuaFile ./nvim-lua/plugins/noneck.lua;
      }
      vim-which-key
      ## misc
      luasnip
      ##  lsp
      neodev-nvim
      nvim-ts-autotag
      nvim-web-devicons
      comment-nvim
      vim-fugitive
      vim-rhubarb
      gitsigns-nvim
      todo-comments-nvim
      copilot-vim
      {
        plugin = markdown-preview-nvim;
        config = toLuaFile ./nvim-lua/plugins/markdownpreview.lua;
      }
      {
        plugin = obsidian-nvim;
        config = toLuaFile ./nvim-lua/plugins/obsidian.lua;
      }
      {
        plugin = nvim-peekup;
        config = toLuaFile ./nvim-lua/plugins/peekup.lua;
      }
      {
        plugin = lspsaga-nvim;
        config = toLuaFile ./nvim-lua/plugins/lsp-saga.lua;
      }
      {
        plugin = harpoon2;
        config = toLuaFile ./nvim-lua/plugins/harpoon.lua;
      }
      #JAVA 
      nvim-dap
      nvim-jdtls
    ];
  };
}
