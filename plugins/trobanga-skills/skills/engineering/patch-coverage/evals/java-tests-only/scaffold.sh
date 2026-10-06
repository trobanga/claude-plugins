#!/usr/bin/env bash
# Builds a one-module Maven repository: main is origin/main, the branch
# "feature" changes only a test class and the README, no production source.
set -euo pipefail

g() { git -c user.name=eval -c user.email=eval@example.com "$@"; }

git init -q -b main .
printf 'target/\n' > .gitignore

cat > pom.xml <<'EOF'
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.acme</groupId>
  <artifactId>greeter</artifactId>
  <version>1.0.0</version>
  <properties>
    <maven.compiler.release>21</maven.compiler.release>
  </properties>
  <dependencies>
    <dependency>
      <groupId>org.junit.jupiter</groupId>
      <artifactId>junit-jupiter</artifactId>
      <version>5.11.3</version>
      <scope>test</scope>
    </dependency>
  </dependencies>
  <build>
    <plugins>
      <plugin>
        <groupId>org.jacoco</groupId>
        <artifactId>jacoco-maven-plugin</artifactId>
        <version>0.8.15</version>
        <executions>
          <execution><goals><goal>prepare-agent</goal></goals></execution>
        </executions>
      </plugin>
    </plugins>
  </build>
</project>
EOF

mkdir -p src/main/java/com/acme src/test/java/com/acme

cat > src/main/java/com/acme/Greeter.java <<'EOF'
package com.acme;

public class Greeter {

    public String greet(String name, boolean formal) {
        if (name == null || name.isBlank()) {
            return formal ? "Good day." : "Hi!";
        }
        if (formal) {
            return "Good day, " + name + ".";
        }
        return "Hi, " + name + "!";
    }
}
EOF

cat > src/test/java/com/acme/GreeterTest.java <<'EOF'
package com.acme;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class GreeterTest {

    @Test
    void greetsByName() {
        assertEquals("Hi, Ada!", new Greeter().greet("Ada", false));
    }
}
EOF

printf '# greeter\n\nGreets people.\n' > README.md

g add -A
g commit -q -m "Greeter"
git update-ref refs/remotes/origin/main HEAD
git checkout -q -b feature

# ---- branch: tests and docs only ----
cat > src/test/java/com/acme/GreeterTest.java <<'EOF'
package com.acme;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

class GreeterTest {

    @Test
    void greetsByName() {
        assertEquals("Hi, Ada!", new Greeter().greet("Ada", false));
    }

    @Test
    void greetsFormally() {
        assertEquals("Good day, Ada.", new Greeter().greet("Ada", true));
    }
}
EOF

printf '# greeter\n\nGreets people, formally or not.\n' > README.md

g add -A
g commit -q -m "Test the formal greeting"
