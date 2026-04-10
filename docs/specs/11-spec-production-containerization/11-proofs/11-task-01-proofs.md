# Task 1.0 Proof Artifacts: Build Context Optimization

## .containerignore Created

File: `.containerignore` — excludes `.git/`, `target/`, `node_modules/`, `e2e-tests/`, IDE files, docs, CI/CD config, and other non-build files.

## .dockerignore Symlink

```bash
$ ls -la .dockerignore
lrwxrwxrwx 1 matt matt 16 Apr 10 17:01 .dockerignore -> .containerignore
```

## Build Context Size Verification

Files included in build context (what Podman sends):

```text
.mvn/          4.0K   (Maven wrapper config)
src/           5.1M   (application source)
pom.xml        18K    (Maven build definition)
mvnw           12K    (Maven wrapper script)
---
Total: ~5.2MB
```

Files excluded (major savings):

- `.git/` — repository history
- `target/` — build output
- `node_modules/` — npm dependencies
- `e2e-tests/` — Playwright tests
- `docs/` — documentation
- `.github/` — CI workflows
- IDE files, logs, dev environment config

The build context contains only what's needed to build the application: source code, Maven config, and the wrapper.
