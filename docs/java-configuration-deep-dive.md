# Java Configuration Deep Dive

This document provides a technical explanation of the Java development environment configuration across NixOS (Home Manager) and Neovim. It covers each tool, its purpose, and how components integrate.

---

## 1. NixOS / Home Manager Java Stack

### 1.1 Core Components

#### jdk21

**Purpose**: Java Development Kit (JDK) providing the runtime and development tools.

**What it enables**:
- Compilation of Java source code (`javac`)
- JVM execution (`java`)
- Java runtime for jdtls (Language Server requires JDK 17+)

**Configuration in home.nix**:
```nix
sessionVariables = {
  JAVA_HOME = "${pkgs.jdk21}/lib/openjdk";
};
```

The `JAVA_HOME` environment variable points to the JDK installation, used by build tools and the language server to locate the JVM.

#### maven

**Purpose**: Build automation and dependency management tool.

**What it enables**:
- Project initialization from archetypes
- Dependency resolution and download
- Compilation, testing, packaging
- Plugin execution (e.g., lombok-maven-plugin)

#### jdt-language-server (jdtls)

**Purpose**: Eclipse JDT Language Server - implements LSP for Java.

**What it enables**:
- Language Server Protocol (LSP) for Java
- IntelliSense-style code completion
- Diagnostics and error highlighting
- Refactoring operations
- Code navigation (go to definition, references)
- Import organization
- Debug adapter for Java (integrates with nvim-dap)

**Installation**: Included in `home.packages`:
```nix
jdt-language-server
```

#### lombok

**Purpose**: Annotation processor that generates boilerplate code at compile time.

**What it enables**:
- `@Data`, `@Getter`, `@Setter` - generates accessors
- `@Builder` - generates builder pattern
- `@NoArgsConstructor`, `@AllArgsConstructor` - generates constructors
- `@EqualsAndHashCode`, `@ToString` - generates methods

**Configuration**: The LSP is configured to recognize lombok annotations and provide completions for generated code.

#### tmc-cli

**Purpose**: TestMyCode CLI - used for educational/testing platforms.

### 1.2 File Type Configuration

**Location**: `home-manager/programs/neovim/nvim-lua/ftplugin/java.lua`

The ftplugin is sourced in home.nix:
```nix
xdg.configFile."nvim/ftplugin/java.lua".source = ./programs/neovim/nvim-lua/ftplugin/java.lua;
```

This file contains the JDTLS initialization logic that runs when opening Java files.

---

## 2. Neovim Java Configuration

### 2.1 Plugin Stack

#### nvim-jdtls

**Purpose**: Neovim plugin providing JDTLS integration.

**What it enables**:
- Starting/configuring jdtls instance
- JDTLS-specific commands (organize imports, extract variable, etc.)
- Debug adapter integration

**Configuration**:
```nix
nvim-jdtls
```

#### nvim-dap

**Purpose**: Debug Adapter Protocol implementation for Neovim.

**What it enables**:
- Launch debugging sessions
- Set breakpoints (line, conditional)
- Step through code (over, into, out)
- Inspect variables
- Call stack navigation
- REPL for expression evaluation

**Keybindings** (from dap.lua):
| Key | Action |
|-----|--------|
| F5 | Continue |
| F10 | Step Over |
| F11 | Step Into |
| F12 | Step Out |
| \<leader>b | Toggle Breakpoint |
| \<leader>B | Set Breakpoint |
| \<leader>lp | Log Point |
| \<leader>dr | Open REPL |
| \<leader>dl | Run Last |

Note: The current dap.lua doesn't include Java-specific configurations - only C/C++/Rust. Java debugging requires additional setup.

### 2.2 LSP Configuration

**Location**: `nvim-lua/plugins/lsp.lua`

```lua
vim.lsp.config('jdtls', {
  cmd = { 'jdtls' },
  filetypes = { 'java' },
  root_markers = { 'pom.xml', 'build.gradle', '.git' },
  capabilities = capabilities,
})
```

The LSP is configured to:
- Use `jdtls` command
- Activate for `java` files
- Find project root using `pom.xml`, `build.gradle`, or `.git`

### 2.3 JDTLS Initialization (ftplugin/java.lua)

The ftplugin provides detailed JDTLS configuration:

#### Root Detection

```lua
local root_markers = {'gradlew', 'mvnw', '.git'}
local root_dir = require('jdtls.setup').find_root(root_markers)
```

Detects project root by looking for Gradle/Maven wrappers or git.

#### Workspace Directory

```lua
local workspace_folder = home .. "/.local/share/eclipse/" .. vim.fn.fnamemodify(root_dir, ":p:h:t")
```

JDTLS stores project-specific data (indexes, caches) in a dedicated workspace folder per project.

#### Dynamic Java Path Resolution

```lua
local function get_java_executable()
  local java_path = vim.fn.exepath('java')
  if java_path ~= '' then
    return java_path
  end
  return "/home/cavelasco/.nix-profile/bin/java"
end
```

Dynamically resolves Java executable path, with fallbacks.

#### JDTLS Settings

**Format Settings**:
```lua
java.format.settings.url = "/.local/share/eclipse/eclipse-java-google-style.xml"
java.format.settings.profile = "GoogleStyle"
```

Uses Google Java Style guide for code formatting.

**Signature Help**:
```lua
java.signatureHelp.enabled = true
```

Shows method parameter hints during completion.

**Content Provider**:
```lua
java.contentProvider.preferred = 'fernflower'
```

Uses Fernflower decompiler to show decompiled sources from dependencies.

**Completion Favorites**:
```lua
java.completion.favoriteStaticMembers = {
  "org.hamcrest.MatcherAssert.assertThat",
  "org.junit.jupiter.api.Assertions.*",
  "org.mockito.Mockito.*",
  "java.util.Objects.requireNonNull",
}
```

Prioritizes these static imports in completions.

**Filtered Types**:
```lua
java.completion.filteredTypes = {
  "com.sun.*",
  "jdk.*",
  "sun.*",
}
```

Excludes internal JDK types from completions.

**Source Organization**:
```lua
java.sources.organizeImports.starThreshold = 9999
java.sources.organizeImports.staticStarThreshold = 9999
```

High thresholds prevent star imports (`java.util.*`), preferring explicit imports.

**Code Generation**:
```lua
java.codeGeneration.toString.template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}"
java.codeGeneration.hashCodeEquals.useJava7Objects = true
java.codeGeneration.useBlocks = true
```

Generates modern Java code (Objects class, blocks).

**Runtime Configuration**:
```lua
java.configuration.runtimes = {
  {
    name = "JavaSE-21",
    path = java_home,
    default = true,
  }
}
```

Configures JavaSE-21 as the target runtime.

**Maven/Gradle**:
```lua
java.configuration.maven.downloadSources = true
java.configuration.maven.updateSnapshots = true
java.configuration.gradle.wrapperEnabled = true
```

Enables automatic source download and Gradle wrapper detection.

#### JDTLS Command

```lua
cmd = {
  "jdtls",
  "--java-executable", java_executable,
  "--no-validate-java-version",
  "--jvm-arg=-Dlog.level=WARNING",
  "--jvm-arg=-Djava.home=" .. java_home,
  "-data", workspace_folder,
}
```

Launches jdtls with:
- Custom Java executable
- Disabled version validation (for compatibility)
- Reduced log verbosity
- Explicit Java home
- Workspace data directory

---

## 3. Integration Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      Neovim                                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │  nvim-jdtls │  │   nvim-dap  │  │  nvim-cmp (completion)  │ │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘ │
│         │                │                      │               │
│         ▼                ▼                      ▼               │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                    LSP Client (vim.lsp)                    │ │
│  └─────────────────────────────────────────────────────────────┘ │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                     jdt-language-server                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │  Eclipse    │  │   Debug     │  │   Code Index            │ │
│  │  JDT Core   │  │   Adapter   │  │   (symbols, refs)       │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                        jdk21                                    │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │   javac     │  │    java     │  │   jvm libs             │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Summary of Enabling Features

| Component | Enables |
|-----------|---------|
| jdk21 | Runtime, compilation |
| maven | Build, dependency management |
| jdt-language-server | LSP server |
| nvim-jdtls | Neovim-JDTLS integration |
| nvim-dap | Debugging |
| lombok | Annotation processing |
| Google Java Style | Consistent formatting |
| fernflower | Dependency source viewing |
| JavaSE-21 runtime | Target JDK version |

---

## 5. References

- [Eclipse JDT Language Server](https://github.com/eclipse/eclipse.jdt.ls)
- [nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls)
- [nvim-dap](https://github.com/mfussenegger/nvim-dap)
- [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html)