# Java Development Workflow with NixOS and Neovim

A practical guide to writing Java on this machine: creating projects and classes, generating constructors/accessors, and organising a Maven project that grows beyond a handful of files.

Everything below was checked against the tools actually installed in this environment. Where a feature is _not_ available (Java debugging, Lombok support, the VS Code "pick fields" dialog), it is called out instead of being presented as working.

## 1. What is installed

| Tool                                | Version / role                                                       |
| ----------------------------------- | -------------------------------------------------------------------- |
| OpenJDK                             | 21.0.12.1 (`JAVA_HOME` points at the JDK 21 Nix store path)          |
| Apache Maven                        | 3.9.16                                                               |
| Eclipse JDT Language Server (jdtls) | 1.61.0                                                               |
| Neovim                              | 0.12.6 with native `vim.lsp.config`                                  |
| nvim-jdtls                          | extra jdtls integration (`:Jdt…` commands)                           |
| nvim-cmp + LuaSnip                  | completion; no custom Java snippets are installed                    |
| nvim-dap                            | installed, but **no Java debug adapter is configured**               |
| Lombok                              | 1.18.46 binary is installed, but **not wired into jdtls** (see §5.7) |

### What works, at a glance

| Task                                      | Available?                | How                                                                 |
| ----------------------------------------- | ------------------------- | ------------------------------------------------------------------- |
| Create a Maven project                    | Yes                       | `mvn archetype:generate`                                            |
| Create a class/interface/enum/record      | Yes                       | oil/`:e`, or the `Create class 'X'` quick fix                       |
| Generate constructors, getters, setters   | Yes                       | `;ca` → `Generate …`                                                |
| Choose a subset of fields in a dialog     | **No**                    | Neovim does not implement the VS Code wizard; use per-field actions |
| Generate `toString`, `equals`, `hashCode` | Yes                       | `;ca` → `Generate …`                                                |
| Format and organise imports               | Yes                       | `:Format`, `require('jdtls').organize_imports()`                    |
| Compile from the editor                   | Yes                       | `:JdtCompile`                                                       |
| Build, test, run                          | Yes                       | `mvn compile`, `mvn test`, `mvn exec:java`                          |
| Debug Java with breakpoints               | **No**                    | No Java configuration in `dap.lua`                                  |
| Lombok annotations                        | **No** (until configured) | Requires the jdtls `-javaagent` flag                                |

## 2. Quick start

### 2.1 Create the project

```bash
cd ~/projects

mvn archetype:generate \
  -DgroupId=com.example.shop \
  -DartifactId=shop \
  -DarchetypeArtifactId=maven-archetype-quickstart \
  -DinteractiveMode=false

cd shop
```

The quickstart archetype still generates an old JUnit 3.8.1 test and no compiler release setting. Section 6.8 shows the small `pom.xml` changes that bring it to Java 21 and JUnit 5.

### 2.2 Create the Maven wrapper

```bash
mvn wrapper:wrapper
```

This creates `mvnw`, `mvnw.cmd`, and `.mvn/wrapper/`. Besides making the build reproducible for other machines, it matters for Neovim: the nvim-jdtls ftplugin looks for `gradlew`, `mvnw`, or `.git` to decide where the project root is. A plain Maven project with only `pom.xml` does not match that list, so the wrapper is the simplest way to get a correct root and a per-project jdtls workspace. (The native `lsp.lua` jdtls configuration does include `pom.xml`, but the wrapper makes both configurations agree.)

### 2.3 Open it

```bash
nvim .
```

Open any file under `src/main/java/...`. The first jdtls start imports the Maven project and downloads dependencies; this can take a while. Check progress with `:JdtShowLogs` if nothing happens.

### 2.4 First build

```bash
mvn test
```

## 3. Neovim keybindings for Java

### Navigation and information

| Key          | Action                          |
| ------------ | ------------------------------- |
| `gd`         | Go to definition                |
| `gI`         | Go to implementation            |
| `gt`         | Go to type definition (Lspsaga) |
| `<leader>D`  | Type definition                 |
| `<leader>ds` | Document symbols (Telescope)    |
| `<leader>ws` | Workspace symbols (Telescope)   |
| `<leader>wl` | List workspace folders          |
| `K`          | Hover documentation             |
| `<leader>K`  | Signature help                  |
| `ln`         | Toggle outline                  |

### Editing

| Key / command                    | Action                                    |
| -------------------------------- | ----------------------------------------- |
| `;ca`                            | Code actions (normal **and** visual mode) |
| `:lua vim.lsp.buf.code_action()` | Code actions without Lspsaga (fallback)   |
| `gr`                             | Rename symbol                             |
| `gp`                             | Peek definition                           |
| `-`                              | Open the current file's directory in oil  |
| `_`                              | Open Neovim's working directory in oil    |
| `:Format`                        | Format the current buffer with jdtls      |
| `:FormatOnSaveToggle`            | Toggle format-on-save (off by default)    |

### jdtls commands

These are created when a jdtls client attaches to a Java buffer:

| Command            | Action                                                                       |
| ------------------ | ---------------------------------------------------------------------------- |
| `:JdtCompile`      | Compile the current project and report errors                                |
| `:JdtUpdateConfig` | Re-read the project configuration (use `:JdtUpdateConfig!` for all projects) |
| `:JdtRestart`      | Restart jdtls for this buffer                                                |
| `:JdtShowLogs`     | Open the jdtls log                                                           |
| `:JdtBytecode`     | Show bytecode of the class under the cursor                                  |
| `:JdtJshell`       | Open a JShell connected to the project                                       |

`;ca` is the important one: nearly every code-generation feature in this guide is a jdtls code action exposed through it.

## 4. Creating classes and packages

### 4.1 The rules Maven and Java enforce

- A public top-level type must live in a file with the same name: `Product.java` → `public class Product`.
- The `package` declaration must match the directory under `src/main/java`:
  `package com.example.shop.model;` → `src/main/java/com/example/shop/model/Product.java`.
- Use lowercase package names and no hyphens: `com.example.shop`, not `com.example.my-shop`.
- One public top-level type per file; helper types can be package-private in the same file, but a separate file is usually clearer.
- Tests mirror the main package under `src/test/java`.

### 4.2 Create a class file with oil

From a Java buffer, press `-` to open its directory (or `_` for the project working directory). Oil buffers are editable:

1. Add a line with the new file, for example `Product.java`.
2. To create it inside a new package, use the full relative path: `model/Product.java`. Intermediate directories are created automatically.
3. Write the oil buffer with `:w`. Oil applies the file creation.
4. Open the file and add the package declaration and class body:

```java
package com.example.shop.model;

public class Product {
}
```

Oil only creates files; it does not write Java boilerplate. The next section removes most of the typing.

### 4.3 Create a class from an unresolved reference

jdtls can create the file for you. In an existing class, reference a type that does not exist yet:

```java
Product product = new Product();
```

Save the buffer, put the cursor on `Product`, and press `;ca`. Choose one of:

- `Create class 'Product'`
- `Create class 'Product' in package 'com.example.shop.model'`

jdtls creates the compilation unit with the correct package declaration and a class stub. This also works for `Create interface '…'`, `Create enum '…'`, and `Create record '…'`.

There is **no** "new class wizard" command in Neovim: no prompt asks for the package, modifiers, or superclass. The quick fix uses the context of the reference, and you edit the generated stub afterwards.

### 4.4 What the editor will not do

- It will not create a package directory by itself unless you create a type in it (oil or the quick fix).
- It will not add a `package` line to an empty file.
- It will not move an existing class to another package for you (use `gr` to rename, then move the file; imports are updated by the LSP).

## 5. Generating constructors, getters, and setters

All of this is done by jdtls code actions through Lspsaga.

### 5.1 Write the fields first

Generation works from the fields that already exist. Start with the state, not the boilerplate:

```java
package com.example.shop.model;

public class Book {
    private String title;
    private String author;
    private int year;
}
```

### 5.2 Open the generators

1. Put the cursor inside the class body (not on the `package` or `import` lines).
2. Press `;ca`.
3. Pick the action you want:

| Action                                | Result                                       |
| ------------------------------------- | -------------------------------------------- |
| `Generate Constructors...`            | One constructor taking all fields            |
| `Generate Getters and Setters...`     | Getter and setter for every eligible field   |
| `Generate Getters...`                 | Getter for every eligible field              |
| `Generate Setters...`                 | Setter for every eligible field              |
| `Generate Getter for 'title'`         | Getter for one field                         |
| `Generate Setter for 'title'`         | Setter for one field                         |
| `Generate toString()...`              | `toString` using the configured template     |
| `Generate hashCode() and equals()...` | Both methods, using `java.util.Objects`      |
| `Generate Delegate Methods...`        | Delegate methods for a field                 |
| `Override/Implement Methods...`       | Pick interface/abstract methods to implement |
| `Add unimplemented methods`           | Quick fix on a class with missing methods    |
| `Assign parameter to new field`       | Quick fix inside a constructor               |
| `Create field 'name'`                 | Quick fix on an unresolved field             |

The `...` actions apply to **all** fields. Neovim does not advertise the prompt/wizard capability that VS Code uses, so there is no field-selection dialog. To generate a subset:

- use the per-field `Generate Getter for '…'` / `Generate Setter for '…'` actions, or
- generate everything and delete the accessors you do not want.

`final` fields do not get setters, which is the correct behaviour for immutable classes.

### 5.3 Worked example

Starting from the `Book` class above:

1. `;ca` → `Generate Constructors...`
2. `;ca` → `Generate Getters...` (or `Generate Getters and Setters...` if the fields are mutable)
3. `;ca` → `Generate toString()...`
4. `;ca` → `Generate hashCode() and equals()...`
5. `:Format`

The result is ordinary Java source that you own and can edit; nothing is hidden behind annotations:

```java
public Book(String title, String author, int year) {
    this.title = title;
    this.author = author;
    this.year = year;
}

public String getTitle() {
    return title;
}

// ... other accessors ...

@Override
public String toString() {
    return "Book{title=" + title + ", author=" + author + ", year=" + year + "}";
}

@Override
public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    Book book = (Book) o;
    return year == book.year
        && Objects.equals(title, book.title)
        && Objects.equals(author, book.author);
}

@Override
public int hashCode() {
    return Objects.hash(title, author, year);
}
```

The exact output depends on the jdtls settings in `ftplugin/java.lua`: `useJava7Objects = true`, `useBlocks = true`, and the custom `toString` template `${object.className}{${member.name()}=${member.value}, ${otherMembers}}`.

### 5.4 If a generator is missing from `;ca`

- The cursor must be inside the type body.
- The file must be saved and the diagnostics must have settled; jdtls computes actions from the current AST.
- `Generate Getters...` needs at least one field.
- `Override/Implement Methods...` needs a superclass or interface with unimplemented methods.
- If the project is not imported (see §12), most actions are unavailable. Run `:JdtUpdateConfig` or `:JdtRestart`.

### 5.5 Records: no boilerplate at all

For a simple immutable value, a `record` replaces the constructor, getters, `toString`, `equals`, and `hashCode`:

```java
package com.example.shop.model;

public record Book(String title, String author, int year) {
}
```

Use a class with generated accessors when you need mutable state, validation with a specific constructor shape, or JavaBean-style `getX()` names expected by a framework. Records generate `title()`, not `getTitle()`.

### 5.6 After generating code

- `:Format` — format the buffer.
- `:lua require('jdtls').organize_imports()` — sort and add imports (star imports are disabled by the `starThreshold = 9999` setting).
- `:JdtCompile` — compile immediately and show errors in the quickfix list.
- `:JdtRestart` — restart the server if the classpath or generated sources look stale.

The guide does not install `<leader>jo`/`<leader>jv` keymaps; if you want them, add them to `ftplugin/java.lua` and rebuild the Home Manager configuration (see §12.5).

### 5.7 A note on Lombok

Lombok is **not active** in the editor. The Nix package and the `lombok` binary are installed, but the jdtls command in `ftplugin/java.lua` does not pass `-javaagent`, and Maven needs the dependency in the POM. Until both are done, `@Data`, `@Builder`, etc. show up as unresolved symbols.

If you want Lombok, add the dependency to `pom.xml`:

```xml
<dependency>
  <groupId>org.projectlombok</groupId>
  <artifactId>lombok</artifactId>
  <version>1.18.46</version>
  <scope>provided</scope>
</dependency>
```

and add the agent to the `cmd` table in `ftplugin/java.lua`:

```lua
local lombok_jar = vim.fn.fnamemodify(vim.fn.exepath('lombok'), ':h:h')
  .. '/share/java/lombok.jar'

-- inside the cmd table:
"--jvm-arg=-javaagent:" .. lombok_jar,
```

Then run `make home` and restart Neovim. For the exercises in this guide, generated accessors and records are simpler because they work without extra configuration.

## 6. Maven project structure

### 6.1 Why the standard layout

Maven's default layout is not cosmetic. It is a contract that every Maven plugin, jdtls, and CI system already understands:

```
src/main/java       production sources
src/main/resources  production resources (loaded from the classpath)
src/test/java       test sources
src/test/resources  test resources
target/             build output — generated, never edit, safe to delete
pom.xml             project coordinates, dependencies, build settings
```

Because the paths are conventional, `mvn compile` needs no list of source files, jdtls knows which directories are source roots, and tests are compiled against the main classes but not shipped with them. `target/` is disposable: `mvn clean` removes it, and it should be in `.gitignore`.

### 6.2 An annotated tree for a multi-class project

```
shop/
├── pom.xml
├── mvnw
├── mvnw.cmd
├── .mvn/wrapper/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/example/shop/
│   │   │       ├── App.java                 # entry point
│   │   │       ├── model/
│   │   │       │   ├── Product.java
│   │   │       │   ├── Customer.java
│   │   │       │   └── Order.java
│   │   │       ├── service/
│   │   │       │   ├── OrderService.java
│   │   │       │   └── PricingService.java
│   │   │       └── repository/
│   │   │           ├── ProductRepository.java       # interface
│   │   │           └── InMemoryProductRepository.java
│   │   └── resources/
│   │       └── application.properties
│   └── test/
│       ├── java/com/example/shop/
│       │   ├── model/OrderTest.java
│       │   └── service/OrderServiceTest.java
│       └── resources/
│           └── test-data.csv
└── target/                                 # generated by Maven
```

Rules of thumb:

- `model` holds data and behaviour of domain objects; `service` holds use cases; `repository` hides storage. This is **package by layer**.
- For a larger application, **package by feature** (`order/`, `catalog/`, `customer/`) scales better because each package changes together. Pick one style per project and stay consistent.
- Keep the test package identical to the main package (`com.example.shop.service`). Package-private classes then remain testable without making everything public.
- Directories are packages. Adding a file in the wrong directory produces a package-mismatch error.

### 6.3 Creating packages and classes

With oil (`-` or `_`):

1. Navigate to `src/main/java/com/example/shop`.
2. Add `service/OrderService.java` as a line and `:w`. Oil creates `service/` and the file.
3. Open the file and write `package com.example.shop.service;` plus the class.
4. Use `;ca` to generate members.

Alternatively, use the unresolved-reference quick fix from §4.3. Both routes end with the same on-disk layout.

### 6.4 The build lifecycle

| Command        | What it does                                                              |
| -------------- | ------------------------------------------------------------------------- |
| `mvn validate` | Validate the project is correct and all required information is available |
| `mvn compile`  | Compile `src/main/java` into `target/classes`                             |
| `mvn test`     | Compile and run tests                                                     |
| `mvn package`  | Run tests and build the JAR in `target/`                                  |
| `mvn verify`   | Run integration checks after packaging                                    |
| `mvn install`  | Put the artifact in the local repository (`~/.m2`)                        |
| `mvn clean`    | Delete `target/`                                                          |

Useful variants:

```bash
mvn -q compile                       # quiet output
mvn -q test                          # run all tests
mvn test -Dtest=OrderServiceTest     # one test class
mvn test -Dtest=OrderServiceTest#addsItem   # one test method
mvn -DskipTests package              # build without running tests
mvn dependency:tree                  # see direct and transitive dependencies
mvn -U clean package                 # force snapshot/dependency updates
```

### 6.5 Running the application

After `mvn compile`:

```bash
java -cp target/classes com.example.shop.App
```

Or let Maven resolve the classpath and run it (the exec plugin is downloaded on first use):

```bash
mvn -q exec:java -Dexec.mainClass=com.example.shop.App
```

Pass arguments with `-Dexec.args="..."`. For a runnable JAR, configure `maven-jar-plugin` with a `mainClass`; `mvn package` then produces `target/shop-1.0-SNAPSHOT.jar`.

### 6.6 Dependencies

Edit `pom.xml` directly (open it with `:e pom.xml` or oil). jdtls is configured with `updateBuildConfiguration = "automatic"`, so saving the POM normally triggers a classpath refresh. If completion still does not see the library:

```bash
mvn -U dependency:resolve
```

then run `:JdtUpdateConfig!` and `:JdtRestart`.

Dependency scopes worth knowing:

- `compile` (default) — needed to compile and run.
- `test` — only on the test classpath (JUnit, assertions, mocking).
- `provided` — needed to compile, supplied at runtime (servlet API, Lombok).

### 6.7 Java 21 compiler settings

The old quickstart POM has no compiler configuration. Add this to the `<project>` element so Maven and jdtls agree on the language level:

```xml
<properties>
  <maven.compiler.release>21</maven.compiler.release>
  <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
</properties>
```

### 6.8 Upgrading the generated test to JUnit 5

Replace the generated JUnit 3.8.1 dependency:

```xml
<dependencies>
  <dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter</artifactId>
    <version>5.10.2</version>
    <scope>test</scope>
  </dependency>
</dependencies>

<build>
  <plugins>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-surefire-plugin</artifactId>
      <version>3.2.5</version>
    </plugin>
  </plugins>
</build>
```

Replace `AppTest.java` with a JUnit 5 test:

```java
package com.example.shop.model;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;

class BookTest {

    @Test
    void constructorStoresValues() {
        Book book = new Book("Dune", "Herbert", 1965);

        assertEquals("Dune", book.getTitle());
        assertEquals("Herbert", book.getAuthor());
        assertEquals(1965, book.getYear());
    }
}
```

JUnit 5 allows package-private test classes and methods, so no `public` is needed. The static imports used in tests are already in jdtls' `favoriteStaticMembers` list, so `assertEquals` completes without a manual import.

### 6.9 When the project gets big: multi-module builds

Packages are enough for a course project with dozens of classes. Split into Maven modules when you need separate artifacts, enforceable boundaries, or independent build/deploy units.

```
shop/
├── pom.xml                 # parent: packaging=pom, lists modules
├── domain/
│   ├── pom.xml             # jar, depends on nothing
│   └── src/main/java/...
├── persistence/
│   ├── pom.xml             # jar, depends on domain
│   └── src/main/java/...
└── app/
    ├── pom.xml             # jar, depends on domain + persistence
    └── src/main/java/...
```

Parent POM:

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <groupId>com.example</groupId>
  <artifactId>shop-parent</artifactId>
  <version>1.0-SNAPSHOT</version>
  <packaging>pom</packaging>

  <modules>
    <module>domain</module>
    <module>persistence</module>
    <module>app</module>
  </modules>

  <properties>
    <maven.compiler.release>21</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>
</project>
```

Child POM (`app/pom.xml`):

```xml
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>

  <parent>
    <groupId>com.example</groupId>
    <artifactId>shop-parent</artifactId>
    <version>1.0-SNAPSHOT</version>
    <relativePath>../pom.xml</relativePath>
  </parent>

  <artifactId>shop-app</artifactId>

  <dependencies>
    <dependency>
      <groupId>com.example</groupId>
      <artifactId>shop-domain</artifactId>
      <version>1.0-SNAPSHOT</version>
    </dependency>
    <dependency>
      <groupId>com.example</groupId>
      <artifactId>shop-persistence</artifactId>
      <version>1.0-SNAPSHOT</version>
    </dependency>
  </dependencies>
</project>
```

From the parent directory:

```bash
mvn test                      # build all modules in reactor order
mvn -pl app -am test          # only app and the modules it depends on
mvn -pl domain install        # install one module for other projects
```

Open the **parent** directory in Neovim. jdtls imports the reactor as one workspace; if you open a child directory, cross-module navigation is incomplete. The parent should have `mvnw` or be a Git repository so the root is detected.

### 6.10 Checklist for a new class

1. Correct package directory under `src/main/java`.
2. File name matches the public type.
3. `package` line matches the directory.
4. Fields first, then `;ca` → constructor/accessors.
5. `:Format`, then `:JdtCompile`.
6. Test in the mirrored package under `src/test/java`.
7. `mvn test` before committing.

## 7. Reducing manual writing without AI

| Task                                          | Tool / action                              |
| --------------------------------------------- | ------------------------------------------ |
| Scaffold a project                            | `mvn archetype:generate`                   |
| Make the build reproducible                   | `mvn wrapper:wrapper`                      |
| Create a class from a reference               | `;ca` → `Create class 'X'`                 |
| Create a file/package                         | oil: `-`, add `pkg/Class.java`, `:w`       |
| Generate constructor                          | `;ca` → `Generate Constructors...`         |
| Generate all accessors                        | `;ca` → `Generate Getters and Setters...`  |
| Generate one accessor                         | `;ca` → `Generate Getter for 'field'`      |
| Generate `toString`/`equals`/`hashCode`       | `;ca` → the corresponding `Generate …`     |
| Implement an interface                        | `;ca` → `Override/Implement Methods...`    |
| Create a missing field from its use           | `;ca` → `Create field 'x'`                 |
| Assign a constructor parameter to a new field | `;ca` → `Assign parameter to new field`    |
| Add/sort imports                              | `:lua require('jdtls').organize_imports()` |
| Rename across the project                     | `gr`                                       |
| Format                                        | `:Format`                                  |
| Compile without leaving Neovim                | `:JdtCompile`                              |
| Avoid accessor boilerplate entirely           | use a `record`                             |
| Run one test                                  | `mvn test -Dtest=ClassName#method`         |
| Run the app                                   | `mvn exec:java -Dexec.mainClass=…`         |

## 8. Formatting

`:Format` calls jdtls' formatter. The configuration in `ftplugin/java.lua` requests the Google Java Style profile from:

```
/.local/share/eclipse/eclipse-java-google-style.xml
```

That file is **not present** in this environment, and the leading `/` is not the home directory. Until the file exists at the configured path, `:Format` uses jdtls' default formatting profile, not Google style.

To enable Google style:

```bash
mkdir -p ~/.local/share/eclipse
curl -o ~/.local/share/eclipse/eclipse-java-google-style.xml \
  https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml
```

Then change the `java.format.settings.url` value in `ftplugin/java.lua` to the absolute path of that file and run `make home`. Restart jdtls with `:JdtRestart`.

`:FormatOnSaveToggle` turns formatting on save on or off for the current session; it is disabled by default.

## 9. Testing

- Run everything: `mvn test`.
- Run one class: `mvn test -Dtest=BookTest`.
- Run one method: `mvn test -Dtest=BookTest#constructorStoresValues`.
- Compile only (fast feedback while editing): `:JdtCompile`.
- See the full stack trace: `mvn test -e`.

Test classes live under `src/test/java`, mirror the production package, and are not packaged into the JAR. JUnit 5 assertions complete through jdtls' favourite static members; `assertEquals`, `assertTrue`, `assertThrows`, etc. do not need a manual import.

## 10. Debugging

There is **no Java debugging configuration**. `nvim-dap` is installed and `dap.lua` configures `lldb` for C/C++/Rust only. Java breakpoints will not work out of the box.

For now:

- use `mvn test` and assertion messages;
- run the program with `mvn exec:java` and add temporary logging;
- use `:JdtBytecode`/`:JdtJshell` to inspect behaviour interactively.

Adding Java debugging requires a Java debug adapter (for example `java-debug-adapter` plus a DAP `java` configuration). That is a separate setup task and is not part of this workflow.

## 11. Complete example

```bash
# 1. Project
cd ~/projects
mvn archetype:generate \
  -DgroupId=com.example.shop \
  -DartifactId=shop \
  -DarchetypeArtifactId=maven-archetype-quickstart \
  -DinteractiveMode=false
cd shop
mvn wrapper:wrapper

# 2. Build settings
#    edit pom.xml: compiler release 21, JUnit 5
mvn test
```

```text
# 3. In Neovim
nvim .
```

1. `-` in oil → `src/main/java/com/example/shop/model/` → add `Book.java` → `:w`.
2. Write the package line and the three fields.
3. `;ca` → `Generate Constructors...`
4. `;ca` → `Generate Getters...`
5. `;ca` → `Generate toString()...`
6. `;ca` → `Generate hashCode() and equals()...`
7. `:Format`, `:JdtCompile`.
8. Create `src/test/java/com/example/shop/model/BookTest.java` and run `mvn test`.

## 12. Troubleshooting

### 12.1 LSP does not start

```bash
which jdtls
java -version
```

In Neovim: `:LspLog`, `:JdtShowLogs`, `:JdtRestart`. If the buffer is not recognised as Java, check `:set filetype?`.

### 12.2 Project root is not detected

The nvim-jdtls ftplugin searches for `gradlew`, `mvnw`, or `.git`. A plain Maven project with only `pom.xml` does not match that list, so the project root and jdtls workspace are not set as intended.

Fix the root by creating the wrapper:

```bash
mvn wrapper:wrapper
```

or add `pom.xml` to `root_markers` in `ftplugin/java.lua`. Reopen the project after either change.

### 12.3 Dependencies or generated methods are not resolving

```bash
mvn -U dependency:resolve
mvn clean compile
```

Then `:JdtUpdateConfig!` and `:JdtRestart`. For Lombok, see §5.7 — the javaagent is required for the editor to see generated members.

### 12.4 Code actions are missing

Save the file, wait for diagnostics, and put the cursor inside the class body. If the whole project is unimported, run `:JdtUpdateConfig` or restart Neovim.

### 12.5 Changing the Neovim Java configuration

The Java setup lives in:

- `home-manager/programs/neovim/nvim-lua/ftplugin/java.lua`
- `home-manager/programs/neovim/nvim-lua/plugins/lsp.lua`
- `home-manager/programs/neovim/nvim-lua/plugins/lsp-saga.lua`

Apply changes with `make home` (or preview with `make home-dry`), then restart Neovim. The flake requires `--impure`.

### 12.6 Workspace data

nvim-jdtls stores per-project data under `~/.local/share/eclipse/<project-directory-name>`. If the workspace is corrupted, close Neovim, delete that directory, and reopen the project; jdtls re-imports it from the POM.

## 13. Optional keymaps

These are **not** part of the current configuration. Add them to `ftplugin/java.lua` if you want quicker access:

```lua
local map = function(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { buffer = true, desc = desc })
end

map('<leader>jo', '<cmd>lua require("jdtls").organize_imports()<CR>', 'Organize imports')
map('<leader>jv', '<cmd>lua require("jdtls").extract_variable()<CR>', 'Extract variable')
map('<leader>jc', '<cmd>lua require("jdtls").extract_constant()<CR>', 'Extract constant')
map('<leader>jm', '<cmd>lua require("jdtls").extract_method()<CR>', 'Extract method')
```

The extract actions require a visual selection. After editing, run `make home` and restart Neovim.

## 14. Resources

- [Eclipse JDT Language Server wiki](https://github.com/eclipse/eclipse.jdt.ls/wiki)
- [Maven – Introduction to the Build Lifecycle](https://maven.apache.org/guides/introduction/introduction-to-the-build-lifecycle.html)
- [Maven – Standard Directory Layout](https://maven.apache.org/guides/introduction/introduction-to-the-standard-directory-layout.html)
- [Neovim LSP documentation](https://neovim.io/doc/user/lsp.html)
- [nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls)
- [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html)
- [JUnit 5 User Guide](https://junit.org/junit5/docs/current/user-guide/)

---

_This workflow targets the NixOS + Home Manager + Neovim setup in this repository. Tool versions and editor behaviour were verified against the installed environment; features that require additional configuration are marked as such._
