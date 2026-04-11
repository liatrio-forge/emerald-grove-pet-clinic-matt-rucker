# Task 1.0 Proof Artifacts: Mise Configuration and Developer Tasks

## mise install

```bash
$ mise install
mise dagger@0.20.5   ✓ installed
mise node@20.20.2    ✓ installed
mise java@corretto-17.0.18.9.1 ✓ installed
mise maven@3.9.14    ✓ installed
mise ✓ done
```

## mise ls

```bash
$ mise ls
dagger  0.20.5                .mise.toml  latest
java    corretto-17.0.18.9.1  .mise.toml  corretto-17
maven   3.9.14                .mise.toml  3.9
node    20.20.2               .mise.toml  20
```

All four tools at correct versions.

## mise run test

```bash
$ mise run test
[INFO] Tests run: 124, Failures: 0, Errors: 0, Skipped: 5
[INFO] BUILD SUCCESS
```

## mise run format

```bash
$ mise run format
[INFO] BUILD SUCCESS
```

## mise run build

```bash
$ mise run build
[INFO] BUILD SUCCESS
$ ls -lh target/*.jar
-rw-r--r-- 1 matt matt 98M target/spring-petclinic-4.0.0-SNAPSHOT.jar
```

## README.md Updated

README.md now contains a "Development Commands" section with a table documenting
all seven Mise tasks (ci, test, build, format, lint, dev, dev:down). Quick Start
updated to use `mise install` as the first setup step.
