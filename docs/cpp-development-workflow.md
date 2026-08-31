# C/C++ Development Workflow on NixOS

This guide outlines the workflow for C and C++ development on your NixOS system, using Neovim as your IDE.

## 1. Environment Setup

We have configured your system with the following tools:
*   **Compilers:** `gcc`, `clang`
*   **Build Tools:** `gnumake` (Make), `cmake`
*   **Debugger:** `lldb`, `gdb`
*   **IDE:** Neovim with `clangd` (LSP) and `nvim-dap` (Debugging)

### Project-Specific Environments (Recommended)
While global tools are installed, the "Nix way" is to use reproducible environments per project.

#### Using `nix shell` (Quick)
For a quick shell with all tools:
```bash
nix shell nixpkgs#clang nixpkgs#cmake nixpkgs#gnumake nixpkgs#lldb
```

#### Using `devbox` (Recommended for Projects)
1.  Initialize devbox in your project root:
    ```bash
    devbox init
    ```
2.  Add packages:
    ```bash
    devbox add clang cmake gnumake lldb
    ```
3.  Enter the shell:
    ```bash
    devbox shell
    ```
    (Or just run `devbox run build` if you define scripts).

## 2. Creating a Project

### Standard CMake Project Structure
```bash
mkdir my-project
cd my-project
mkdir src build include
touch CMakeLists.txt src/main.cpp
```

### Example `CMakeLists.txt`
```cmake
cmake_minimum_required(VERSION 3.10)
project(MyProject)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON) # Crucial for Neovim LSP!

add_executable(my_app src/main.cpp)
```

### Example `src/main.cpp`
```cpp
#include <iostream>

int main() {
    std::cout << "Hello from Neovim!" << std::endl;
    return 0;
}
```

## 3. Configuring Neovim (LSP)

For `clangd` (the C++ language server) to work correctly (find headers, understand flags), it needs a `compile_commands.json` file.

**Step 1: Generate `compile_commands.json`**
Run this in your project root:
```bash
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
ln -s build/compile_commands.json .
```
*The symlink ensures `clangd` finds the file in the root.*

**Step 2: Open Neovim**
```bash
nvim src/main.cpp
```
You should now see:
*   Syntax highlighting.
*   Diagnostics (errors/warnings).
*   Autocomplete (type `std::` to test).
*   `gd` to go to definition.
*   `K` to hover documentation.

## 4. Compiling

From the terminal (or Neovim terminal `<leader>st` if configured, or just `:term`):
```bash
# Configure (only needed once or when adding files)
cmake -S . -B build

# Build
cmake --build build
```
The executable will be in `build/my_app`.

## 5. Debugging in Neovim

We have configured `nvim-dap` with `lldb`.

1.  Open your source file (`src/main.cpp`).
2.  Set a breakpoint: In **Normal mode**, press `<leader>b` (leader is **space**, so: `Space` then `b`) on the line you want to stop at. You should see a breakpoint marker in the sign column.
3.  Start debugging: Press `<F5>`.
4.  **Select Executable:** The first time, it will ask for the path to the executable. Enter:
    ```
    build/my_app
    ```
    (or whatever your executable is named).

### Controls
*   **F5:** Continue / Start
*   **F10:** Step Over
*   **F11:** Step Into
*   **F12:** Step Out
*   **Leader + b:** Toggle Breakpoint
*   **Leader + dr:** Open REPL (to inspect variables)

### If `<leader>b` doesn’t work
Run `:verbose nmap <leader>b` to see what it is mapped to (and which file last set it).

## 6. Troubleshooting

*   **LSP not finding headers?** Ensure `compile_commands.json` exists in the root.
    - On **NixOS**, if `compile_commands.json` uses a Nix-store compiler (e.g. `/nix/store/.../g++`), `clangd` may still show `iostream file not found` unless it is started with `--query-driver` that matches Nix paths. (This is handled in our Neovim `clangd` config.)
*   **Debugger not starting?** Ensure `lldb` is installed (`lldb --version`). If `lldb-vscode` is missing, you might need to install the full `lldb` package (which we did).
    - On **NixOS**, the debug adapter binary is often **`lldb-dap`** (not `lldb-vscode`).
*   **"No active adapter"?** Check `dap.lua` config or run `:checkhealth dap`.

## Quick Checklist for New Projects
1.  `mkdir build`
2.  `cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON`
3.  `ln -s build/compile_commands.json .`
4.  `nvim .`
