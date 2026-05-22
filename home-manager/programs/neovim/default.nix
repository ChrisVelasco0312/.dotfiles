{
  # config, 
  pkgs
, # lib, 
  # inputs, 
  ...
}:
{
  programs.neovim =
    let
      toLuaFile = file: "lua << EOF\n${builtins.readFile file}\nEOF\n";
    in
    {
      enable = true;
      viAlias = true;
      vimAlias = true;
      withRuby = false;
      withPython3 = false;

      extraPackages = with pkgs; [
        emmet-ls
        tree-sitter
        vscode-langservers-extracted
        typescript
        typescript-language-server
        eslint
        luajitPackages.lua-lsp
        nixd
        nixpkgs-fmt
        prettier
        clang-tools
        lldb

        (python3.withPackages (ps: with ps; [
          python-lsp-server
          python-lsp-ruff
          mypy
          python-lsp-black
          isort
          rope
        ])) 
      ];

      initLua = ''
        ${builtins.readFile ./nvim-lua/init.lua } 
        ${builtins.readFile ./nvim-lua/base.lua } 
        ${builtins.readFile ./nvim-lua/maps.lua }
        -- plugins config
        ${builtins.readFile ./nvim-lua/plugins/alpha.lua}
        ${builtins.readFile ./nvim-lua/plugins/autotag.lua }
        ${builtins.readFile ./nvim-lua/plugins/autopairs.lua }
        ${builtins.readFile ./nvim-lua/plugins/telescope.lua }
        ${builtins.readFile ./nvim-lua/plugins/trouble.lua }
        ${builtins.readFile ./nvim-lua/plugins/git.lua }
      '';

      plugins = with pkgs.vimPlugins; [
        alpha-nvim # dashboard
        ## telescope dependencies
        telescope-nvim
        telescope-fzf-native-nvim
        telescope-file-browser-nvim
        nvim-autopairs
        {
          plugin = git-blame-nvim;
          type = "viml";
          config = toLuaFile ./nvim-lua/plugins/git-blame.lua;
        }
        {
          plugin = oil-nvim;
          type = "viml";
          config = toLuaFile ./nvim-lua/plugins/oil.lua;
        }
        {
          plugin = nvim-lspconfig;
          type = "viml";
          config = toLuaFile ./nvim-lua/plugins/lsp.lua;
        }
        lsp-colors-nvim
        trouble-nvim
        {
          plugin = bufferline-nvim;
          type = "viml";
          config = toLuaFile ./nvim-lua/plugins/bufferline.lua;
        }
        {
          plugin = own-lualine-nvim;
          type = "viml";
          config = toLuaFile ./nvim-lua/plugins/lualine.lua;
        }
        plenary-nvim
        lspkind-nvim
        ## autocompletion
        {
          plugin = nvim-cmp;
          type = "viml";
          config = toLuaFile ./nvim-lua/plugins/cmp.lua;
        }
        nvim-cmp
        cmp-nvim-lsp
        cmp_luasnip
        cmp-buffer
        {
          plugin = onedark-nvim;
          type = "viml";
          config = toLuaFile ./nvim-lua/plugins/onedark.lua;
        }
        {
          plugin = none-ls-nvim;
          type = "viml";
          config = toLuaFile ./nvim-lua/plugins/null-ls.lua;
        }
        {
          plugin = nvim-treesitter.withAllGrammars;
          type = "viml";
          config = toLuaFile ./nvim-lua/plugins/treesitter.lua;
        }
        {
          plugin = zen-mode-nvim;
          type = "viml";
          config = toLuaFile ./nvim-lua/plugins/zenmode.lua;
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
        {
          plugin = copilot-vim;
          type = "viml";
          config = toLuaFile ./nvim-lua/plugins/copilot.lua;
        }
        ## opencode dependencies
        snacks-nvim
        {
          plugin = opencode-nvim;
          type = "viml";
          config = toLuaFile ./nvim-lua/plugins/opencode.lua;
        }
        {
          plugin = markdown-preview-nvim;
          type = "viml";
          config = toLuaFile ./nvim-lua/plugins/markdownpreview.lua;
        }
        {
          plugin = obsidian-nvim;
          type = "viml";
          config = toLuaFile ./nvim-lua/plugins/obsidian.lua;
        }
        {
          plugin = nvim-peekup;
          type = "viml";
          config = toLuaFile ./nvim-lua/plugins/peekup.lua;
        }
        {
          plugin = lspsaga-nvim;
          type = "viml";
          config = toLuaFile ./nvim-lua/plugins/lsp-saga.lua;
        }
        {
          plugin = harpoon2;
          type = "viml";
          config = toLuaFile ./nvim-lua/plugins/harpoon.lua;
        }
        {
          plugin = nvim-ufo;
          type = "viml";
          config = toLuaFile ./nvim-lua/plugins/ufo.lua;
        }
        
        #JAVA 
        {
          plugin = nvim-dap;
          type = "viml";
          config = toLuaFile ./nvim-lua/plugins/dap.lua;
        }
        nvim-jdtls
      ];
    };
}
