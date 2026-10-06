#!/usr/bin/env bash
# Builds a two-module Maven repository: main is origin/main, the branch
# "feature" changes Pricing (core) and OrderController (api). The JaCoCo
# reports of both modules describe HEAD and are newer than every source.
set -euo pipefail

g() { git -c user.name=eval -c user.email=eval@example.com "$@"; }

git init -q -b main .
printf 'target/\n' > .gitignore

cat > pom.xml <<'EOF'
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.acme</groupId>
  <artifactId>shop</artifactId>
  <version>1.0.0</version>
  <packaging>pom</packaging>
  <modules>
    <module>core</module>
    <module>api</module>
  </modules>
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

for m in core api; do
  mkdir -p "$m"
  cat > "$m/pom.xml" <<EOF
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>com.acme</groupId>
    <artifactId>shop</artifactId>
    <version>1.0.0</version>
  </parent>
  <artifactId>$m</artifactId>
</project>
EOF
done

P=core/src/main/java/com/acme/core
A=api/src/main/java/com/acme/api
mkdir -p "$P" "$A"

# ---- base versions (origin/main) ----
cat > "$P/Pricing.java" <<'EOF'
package com.acme.core;

public class Pricing {

    public int legacyTax(int amount, String region) {
        if (region == null) {
            return 0;
        }
        if (region.equals("EU")) {
            return amount * 20 / 100;
        }
        if (region.equals("US")) {
            return amount * 7 / 100;
        }
        if (amount > 10000) {
            return amount / 10;
        }
        if (amount < 0) {
            throw new IllegalArgumentException("negative");
        }
        return amount / 20;
    }

    public int discount(int qty, boolean member, boolean coupon) {
        int pct = 0;
        if (qty > 100) {
            pct += 10;
        }
        if (member) {
            pct += 5;
        }
        if (coupon) {
            pct += 5;
        }
        return pct;
    }

    public int shipping(int weightGrams, boolean express, boolean remote) {
        int cost = 500;
        if (weightGrams > 2000) {
            cost += 300;
        }
        if (express) {
            cost *= 2;
        }
        if (remote) {
            cost += 1000;
        }
        return cost;
    }
}
EOF

cat > "$A/OrderController.java" <<'EOF'
package com.acme.api;

public class OrderController {

    public String create(String sku, int qty) {
        if (qty <= 0) {
            return "rejected";
        }
        return "created:" + sku + ":" + qty;
    }
}
EOF

g add -A
g commit -q -m "Initial shop"
git update-ref refs/remotes/origin/main HEAD
git checkout -q -b feature

# ---- branch versions (HEAD) ----
cat > "$P/Pricing.java" <<'EOF'
package com.acme.core;

public class Pricing {

    public int legacyTax(int amount, String region) {
        if (region == null) {
            return 0;
        }
        if (region.equals("EU")) {
            return amount * 20 / 100;
        }
        if (region.equals("US")) {
            return amount * 7 / 100;
        }
        if (amount > 10000) {
            return amount / 10;
        }
        if (amount < 0) {
            throw new IllegalArgumentException("negative");
        }
        return amount / 20;
    }

    public int discount(int qty, boolean member, boolean coupon) {
        int pct = 0;
        if (qty > 100) {
            pct += 10;
        }
        if (member) {
            pct += 5;
        }
        if (coupon) {
            pct += 5;
        }
        if (pct > 15) {
            pct = 15;
        }
        return pct;
    }

    public int shipping(int weightGrams, boolean express, boolean remote, boolean fragile) {
        int cost = 500;
        if (weightGrams > 2000) {
            cost += 300;
        }
        if (express) {
            cost *= 2;
        }
        if (remote) {
            cost += 1000;
        }
        if (fragile) {
            cost += 250;
        }
        return cost;
    }
}
EOF

cat > "$A/OrderController.java" <<'EOF'
package com.acme.api;

public class OrderController {

    public String create(String sku, int qty) {
        if (!validate(sku, qty)) {
            return "rejected";
        }
        return "created:" + sku + ":" + qty;
    }

    public boolean validate(String sku, int qty) {
        if (sku == null || sku.isEmpty()) {
            return false;
        }
        return qty > 0 && qty <= 1000;
    }
}
EOF

g add -A
g commit -q -m "Cap discounts, add fragile surcharge, validate orders"

# ---- JaCoCo reports for HEAD, written after the sources ----
mkdir -p core/target/site/jacoco api/target/site/jacoco

cat > core/target/site/jacoco/jacoco.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?><!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"><report name="core"><sessioninfo id="ci-1" start="1790000000000" dump="1790000005000"/><package name="com/acme/core"><class name="com/acme/core/Pricing" sourcefilename="Pricing.java"><method name="&lt;init&gt;" desc="()V" line="3"><counter type="INSTRUCTION" missed="0" covered="3"/><counter type="LINE" missed="0" covered="1"/><counter type="COMPLEXITY" missed="0" covered="1"/><counter type="METHOD" missed="0" covered="1"/></method><method name="legacyTax" desc="(ILjava/lang/String;)I" line="6"><counter type="INSTRUCTION" missed="41" covered="0"/><counter type="BRANCH" missed="10" covered="0"/><counter type="LINE" missed="11" covered="0"/><counter type="COMPLEXITY" missed="6" covered="0"/><counter type="METHOD" missed="1" covered="0"/></method><method name="discount" desc="(IZZ)I" line="25"><counter type="INSTRUCTION" missed="6" covered="20"/><counter type="BRANCH" missed="3" covered="5"/><counter type="LINE" missed="2" covered="9"/><counter type="COMPLEXITY" missed="2" covered="3"/><counter type="METHOD" missed="0" covered="1"/></method><method name="shipping" desc="(IZZZ)I" line="42"><counter type="INSTRUCTION" missed="12" covered="18"/><counter type="BRANCH" missed="4" covered="4"/><counter type="LINE" missed="3" covered="7"/><counter type="COMPLEXITY" missed="3" covered="2"/><counter type="METHOD" missed="0" covered="1"/></method><counter type="INSTRUCTION" missed="59" covered="41"/><counter type="BRANCH" missed="17" covered="9"/><counter type="LINE" missed="16" covered="17"/><counter type="COMPLEXITY" missed="11" covered="6"/><counter type="METHOD" missed="1" covered="3"/><counter type="CLASS" missed="0" covered="1"/></class><sourcefile name="Pricing.java"><counter type="LINE" missed="16" covered="17"/></sourcefile></package></report>
EOF

cat > api/target/site/jacoco/jacoco.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?><!DOCTYPE report PUBLIC "-//JACOCO//DTD Report 1.1//EN" "report.dtd"><report name="api"><sessioninfo id="ci-1" start="1790000000000" dump="1790000005000"/><package name="com/acme/api"><class name="com/acme/api/OrderController" sourcefilename="OrderController.java"><method name="&lt;init&gt;" desc="()V" line="3"><counter type="INSTRUCTION" missed="0" covered="3"/><counter type="LINE" missed="0" covered="1"/><counter type="COMPLEXITY" missed="0" covered="1"/><counter type="METHOD" missed="0" covered="1"/></method><method name="create" desc="(Ljava/lang/String;I)Ljava/lang/String;" line="6"><counter type="INSTRUCTION" missed="0" covered="16"/><counter type="BRANCH" missed="0" covered="2"/><counter type="LINE" missed="0" covered="3"/><counter type="COMPLEXITY" missed="0" covered="2"/><counter type="METHOD" missed="0" covered="1"/></method><method name="validate" desc="(Ljava/lang/String;I)Z" line="13"><counter type="INSTRUCTION" missed="9" covered="8"/><counter type="BRANCH" missed="6" covered="2"/><counter type="LINE" missed="1" covered="2"/><counter type="COMPLEXITY" missed="4" covered="1"/><counter type="METHOD" missed="0" covered="1"/></method><counter type="INSTRUCTION" missed="9" covered="27"/><counter type="BRANCH" missed="6" covered="4"/><counter type="LINE" missed="1" covered="6"/><counter type="COMPLEXITY" missed="4" covered="4"/><counter type="METHOD" missed="0" covered="3"/><counter type="CLASS" missed="0" covered="1"/></class><sourcefile name="OrderController.java"><counter type="LINE" missed="1" covered="6"/></sourcefile></package></report>
EOF
