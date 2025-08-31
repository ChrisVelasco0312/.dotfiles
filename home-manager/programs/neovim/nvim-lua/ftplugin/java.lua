local home = os.getenv('HOME')
local jdtls = require('jdtls')

-- File types that signify a Java project's root directory. This will be
-- used by eclipse to determine what constitutes a workspace
local root_markers = {'gradlew', 'mvnw', '.git'}
local root_dir = require('jdtls.setup').find_root(root_markers)

-- eclipse.jdt.ls stores project specific data within a folder. If you are working
-- with multiple different projects, each project must use a dedicated data directory.
-- This variable is used to configure eclipse to use the directory name of the
-- current project found using the root_marker as the folder for project specific data.
local workspace_folder = home .. "/.local/share/eclipse/" .. vim.fn.fnamemodify(root_dir, ":p:h:t")

-- Helper function for creating keymaps
function nnoremap(rhs, lhs, bufopts, desc)
  bufopts.desc = desc
  vim.keymap.set("n", rhs, lhs, bufopts)
end

-- Get Java executable path dynamically
local function get_java_executable()
  local java_path = vim.fn.exepath('java')
  if java_path ~= '' then
    return java_path
  end
  -- Fallback to the hardcoded path
  return "/home/cavelasco/.nix-profile/bin/java"
end

-- Get Java home directory dynamically
local function get_java_home()
  local java_home = os.getenv('JAVA_HOME')
  if java_home and java_home ~= '' then
    return java_home
  end
  -- Fallback: try to get it from the java executable
  local java_exec = get_java_executable()
  if java_exec then
    -- Remove /bin/java from the path to get the home directory
    return vim.fn.fnamemodify(java_exec, ":h:h")
  end
  -- Final fallback
  return "/nix/store/*/openjdk-21*/lib/openjdk"
end

local java_executable = get_java_executable()
local java_home = get_java_home()

-- Debug: Print Java executable and home paths
vim.api.nvim_echo({{"Java executable: " .. java_executable, "Comment"}}, false, {})
vim.api.nvim_echo({{"Java home: " .. java_home, "Comment"}}, false, {})

local config = {
  flags = {
    debounce_text_changes = 80,
    allow_incremental_sync = true,
  },
  root_dir = root_dir, -- Set the root directory to our found root_marker
  -- Here you can configure eclipse.jdt.ls specific settings
  -- These are defined by the eclipse.jdt.ls project and will be passed to eclipse when starting.
  -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
  -- for a list of options
  settings = {
    java = {
      format = {
        settings = {
          -- Use Google Java style guidelines for formatting
          -- To use, make sure to download the file from https://github.com/google/styleguide/blob/gh-pages/eclipse-java-google-style.xml
          -- and place it in the ~/.local/share/eclipse directory
          url = "/.local/share/eclipse/eclipse-java-google-style.xml",
          profile = "GoogleStyle",
        },
      },
      signatureHelp = { enabled = true },
      contentProvider = { preferred = 'fernflower' },  -- Use fernflower to decompile library code
      -- Specify any completion options
      completion = {
        favoriteStaticMembers = {
          "org.hamcrest.MatcherAssert.assertThat",
          "org.hamcrest.Matchers.*",
          "org.hamcrest.CoreMatchers.*",
          "org.junit.jupiter.api.Assertions.*",
          "java.util.Objects.requireNonNull",
          "java.util.Objects.requireNonNullElse",
          "org.mockito.Mockito.*"
        },
        filteredTypes = {
          "com.sun.*",
          "io.micrometer.shaded.*",
          "java.awt.*",
          "jdk.*", "sun.*",
        },
      },
      -- Specify any options for organizing imports
      sources = {
        organizeImports = {
          starThreshold = 9999;
          staticStarThreshold = 9999;
        },
      },
      -- How code generation should act
      codeGeneration = {
        toString = {
          template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}"
        },
        hashCodeEquals = {
          useJava7Objects = true,
        },
        useBlocks = true,
      },
      -- If you are developing in projects with different Java versions, you need
      -- to tell eclipse.jdt.ls to use the location of the JDK for your Java version
      -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
      -- And search for `interface RuntimeOption`
      -- The `name` is NOT arbitrary, but must match one of the elements from `enum ExecutionEnvironment` in the link above
      configuration = {
        runtimes = {
          {
            name = "JavaSE-21",
            path = java_home,
            default = true,
          }
        },
        -- Additional configuration to help with runtime detection
        updateBuildConfiguration = "automatic",
        maven = {
          downloadSources = true,
          updateSnapshots = true,
        },
        gradle = {
          wrapperEnabled = true,
        },
      }
    }
  },
  -- cmd is the command that starts the language server. Whatever is placed
  -- here is what is passed to the command line to execute jdtls.
  -- Note that eclipse.jdt.ls must be started with a Java version of 17 or higher
  -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
  -- for the full list of options
  cmd = {
    "jdtls",
    "--java-executable", java_executable,
    "--no-validate-java-version",  -- Disable Java version validation to avoid issues
    "--jvm-arg=-Dlog.level=WARNING",  -- Reduce log verbosity
    "--jvm-arg=-Djava.home=" .. java_home,  -- Explicitly set Java home
    "-data", workspace_folder,
  },
}

-- Finally, start jdtls. This will run the language server using the configuration we specified,
-- setup the keymappings, and attach the LSP client to the current buffer

jdtls.start_or_attach(config)
