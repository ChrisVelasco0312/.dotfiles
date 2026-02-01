# Java Development Workflow with NixOS and Neovim

This document outlines the complete Java development environment setup and workflow using NixOS, Home Manager, and Neovim as the primary editor.

## 🛠 Development Environment Overview

### Installed Tools & Versions

- **Java Runtime**: OpenJDK 23.0.2 (2025-01-21)
- **Build Tool**: Apache Maven 3.9.9
- **Editor**: Neovim with Java LSP support
- **Language Server**: Eclipse JDT Language Server (jdtls) v1.46.1
- **Debugging**: nvim-dap (Debug Adapter Protocol)
- **Additional Tools**: Lombok support, Docker Compose

### System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Neovim        │    │   Eclipse JDTLS │    │   OpenJDK 23    │
│   ├─ LSP Client │◄──►│   Language      │◄──►│   Runtime       │
│   ├─ nvim-jdtls │    │   Server        │    │   Environment   │
│   └─ nvim-dap   │    └─────────────────┘    └─────────────────┘
└─────────────────┘
         │
         ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Maven 3.9.9   │    │   Lombok        │    │   Docker        │
│   Build Tool    │    │   Annotations   │    │   Containers    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Quick Start

### 1. Project Setup

#### Creating a New Maven Project
```bash
# Navigate to your projects directory
cd ~/projects

# Create a new Maven project
mvn archetype:generate \
  -DgroupId=com.example.myapp \
  -DartifactId=my-java-app \
  -DarchetypeArtifactId=maven-archetype-quickstart \
  -DinteractiveMode=false

cd my-java-app
```

#### Project Structure Recognition
The Java LSP automatically detects projects using these markers:
- `gradlew` (Gradle wrapper)
- `mvnw` (Maven wrapper)  
- `.git` (Git repository)

### 2. Opening Projects in Neovim

```bash
# Open the project root directory
nvim .

# Or open specific Java files
nvim src/main/java/com/example/App.java
```

## 📝 Neovim Java Features

### Language Server Protocol (LSP) Features

#### Navigation & Discovery
| Keybinding | Action | Description |
|------------|--------|-------------|
| `gd` | Go to Definition | Jump to where symbol is defined |
| `gI` | Go to Implementation | Jump to implementation |
| `<leader>D` | Type Definition | Show type definition |
| `<leader>ds` | Document Symbols | List symbols in current file |
| `<leader>ws` | Workspace Symbols | Search symbols across workspace |

#### Code Actions & Refactoring
| Command | Action |
|---------|--------|
| `:lua vim.lsp.buf.code_action()` | Show available code actions |
| `:lua vim.lsp.buf.rename()` | Rename symbol |
| `:lua vim.lsp.buf.format()` | Format code using Google Java Style |

#### Workspace Management
| Keybinding | Action |
|------------|--------|
| `<leader>wl` | List workspace folders |
| `<leader>wa` | Add workspace folder |
| `<leader>wr` | Remove workspace folder |

### Autocompletion & Intellisense

The setup includes smart autocompletion with:
- **Method signatures** with parameter hints
- **Import organization** (auto-imports)
- **Favorite static members** for common testing frameworks:
  - JUnit Jupiter assertions
  - Hamcrest matchers
  - Mockito mocking
  - Java utility methods

### Code Generation

Automatic code generation for:
- **toString()** methods with custom templates
- **hashCode() and equals()** using Java 7+ Objects
- **Getters and setters**
- **Constructors**

### Import Management

- **Star threshold**: 9999 (prefers explicit imports)
- **Static star threshold**: 9999 (prefers explicit static imports)
- Automatic import organization on save (when enabled)

## 🏗 Build & Execution Workflow

### Maven Commands

```bash
# Compile the project
mvn compile

# Run tests
mvn test

# Package the application
mvn package

# Clean and rebuild
mvn clean compile

# Run the application (if main class is configured)
mvn exec:java -Dexec.mainClass="com.example.App"

# Install to local repository
mvn install
```

### IDE Integration with Maven

The LSP server automatically:
- Detects Maven projects via `pom.xml`
- Downloads dependencies
- Configures classpath
- Updates project configuration on POM changes

## Debugging Setup

### Debug Adapter Protocol (DAP)

The environment includes `nvim-dap` for debugging support:

```lua
-- Example DAP configuration (can be added to your config)
local dap = require('dap')

dap.configurations.java = {
  {
    type = 'java',
    request = 'launch',
    name = 'Launch Java Application',
    mainClass = '${workspaceFolder}/src/main/java/com/example/App.java',
    args = {},
  }
}
```

### Setting Breakpoints

```bash
# In Neovim normal mode
:lua require('dap').toggle_breakpoint()

# Start debugging
:lua require('dap').continue()
```

## 🎨 Code Formatting

### Google Java Style

The setup uses Google Java Style guidelines:

1. **Style file location**: `~/.local/share/eclipse/eclipse-java-google-style.xml`
2. **Download the style file**:
   ```bash
   mkdir -p ~/.local/share/eclipse
   curl -o ~/.local/share/eclipse/eclipse-java-google-style.xml \
     https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml
   ```

### Format Commands

| Command | Action |
|---------|--------|
| `:Format` | Format current buffer |
| `:FormatOnSaveToggle` | Toggle automatic formatting on save |

## 🧪 Testing Workflow

### JUnit Integration

The autocomplete includes JUnit Jupiter assertions:

```java
// Type 'assert' and use autocomplete
assertThat(actual).isEqualTo(expected);
assertEquals(expected, actual);
assertTrue(condition);
```

### Running Tests

```bash
# Run all tests
mvn test

# Run specific test class
mvn test -Dtest=MyTestClass

# Run specific test method
mvn test -Dtest=MyTestClass#testMethod

# Run tests with debug output
mvn test -X
```

## 📦 Dependency Management

### Adding Dependencies

Edit `pom.xml` to add dependencies:

```xml
<dependencies>
  <dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter</artifactId>
    <version>5.10.0</version>
    <scope>test</scope>
  </dependency>
</dependencies>
```

The LSP will automatically detect changes and update the classpath.

### Lombok Support

Lombok is pre-installed and configured:

```java
import lombok.Data;
import lombok.Builder;

@Data
@Builder
public class User {
    private String name;
    private String email;
}
```

## 🐳 Containerization

### Docker Integration

Docker Compose is available for containerized development:

```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "8080:8080"
    volumes:
      - .:/workspace
```

```bash
# Build and run with Docker Compose
docker-compose up --build
```

## Troubleshooting

### Common Issues

#### 1. LSP Not Starting
```bash
# Check if jdtls is available
which jdtls

# Check Java version
java -version

# Restart LSP server
:LspRestart
```

#### 2. Maven Dependencies Not Resolving
```bash
# Force dependency resolution
mvn dependency:resolve

# Clean and reinstall
mvn clean install
```

#### 3. Format Not Working
```bash
# Check if Google Style file exists
ls ~/.local/share/eclipse/eclipse-java-google-style.xml

# Download if missing (see Code Formatting section)
```

### Log Files

- **JDTLS logs**: `~/.local/share/eclipse/<project-name>/.metadata/.log`
- **Neovim LSP logs**: `:LspLog`

## 🔄 Workflow Example

### Complete Development Cycle

1. **Create Project**:
   ```bash
   mvn archetype:generate -DgroupId=com.example -DartifactId=my-app
   cd my-app
   nvim .
   ```

2. **Edit Code**: Use Neovim with full LSP support for navigation, completion, and refactoring

3. **Build & Test**:
   ```bash
   mvn compile test
   ```

4. **Debug**: Set breakpoints and use DAP for debugging

5. **Package & Deploy**:
   ```bash
   mvn package
   # Run the JAR or deploy to containers
   ```

## Advanced Features

### Custom Keybindings

Add to your Neovim config for Java-specific bindings:

```lua
-- Java-specific keybindings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    local opts = { buffer = true }
    vim.keymap.set('n', '<leader>jo', '<cmd>lua require("jdtls").organize_imports()<CR>', opts)
    vim.keymap.set('n', '<leader>jv', '<cmd>lua require("jdtls").extract_variable()<CR>', opts)
    vim.keymap.set('n', '<leader>jc', '<cmd>lua require("jdtls").extract_constant()<CR>', opts)
    vim.keymap.set('n', '<leader>jm', '<cmd>lua require("jdtls").extract_method()<CR>', opts)
  end,
})
```

### Project Templates

Create custom Maven archetypes for common project structures:

```bash
# Spring Boot project
mvn archetype:generate \
  -DgroupId=com.example \
  -DartifactId=spring-app \
  -DarchetypeGroupId=org.springframework.boot \
  -DarchetypeArtifactId=spring-boot-starter-web
```

## Additional Resources

- [Eclipse JDT Language Server Wiki](https://github.com/eclipse/eclipse.jdt.ls/wiki)
- [Maven Documentation](https://maven.apache.org/guides/)
- [Neovim LSP Configuration](https://neovim.io/doc/user/lsp.html)
- [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html)

---

*This workflow is optimized for the NixOS + Home Manager + Neovim development environment. All tools are declaratively managed and reproducible across systems.*
