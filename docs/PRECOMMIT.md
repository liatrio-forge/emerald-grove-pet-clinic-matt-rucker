# Pre-commit Hooks Guide

This guide covers the pre-commit hooks configuration for the Emerald Grove Veterinary Clinic application.

## Overview

Pre-commit hooks are automated checks that run before each commit to ensure code quality, consistency, and compliance with project standards. They help catch common issues early and maintain high code quality across the team.

## Installation

### Quick Setup

```bash
# Run the setup script
./scripts/setup-precommit.sh
```

### Manual Installation

```bash
# Install pre-commit (if not already installed)
pipx install pre-commit

# Install the hooks
pre-commit install

# Install commit-msg hook
pre-commit install --hook-type commit-msg
```

## Available Hooks

### Basic File Checks

- **trailing-whitespace**: Removes trailing whitespace
- **end-of-file-fixer**: Ensures files end with newline
- **check-yaml**: Validates YAML syntax
- **check-json**: Validates JSON syntax
- **check-toml**: Validates TOML syntax
- **check-xml**: Validates XML syntax
- **check-merge-conflict**: Detects merge conflict markers
- **check-case-conflict**: Checks for case conflicts
- **check-added-large-files**: Prevents large files (>1MB)
- **mixed-line-ending**: Ensures consistent line endings

### Java Specific

- **Maven-compile-check**: Ensures Maven compilation succeeds
- **Maven-test-check**: Runs the full test suite and ensures all tests pass before committing

### Documentation

- **markdownlint**: Lints Markdown files for style and formatting

### Security & Quality

- **shellcheck**: Lints shell scripts
- **gitlint**: Validates commit messages

### Branch Protection

- **no-direct-commits-to-main**: Prevents direct commits to the main branch, enforcing PR-based workflow

## Configuration Files

### `.pre-commit-config.yaml`

Main configuration file defining all hooks and their settings.

### `.markdownlint.yaml`

Configuration for Markdown linting rules:

- Fenced code blocks required
- Proper heading structure
- HTML elements allowed
- No arbitrary line length limits

### `checkstyle.xml`

Java code style configuration for Checkstyle integration.

## Usage

### Running Hooks Manually

```bash
# Run all hooks on all files
pre-commit run --all-files

# Run specific hooks
pre-commit run trailing-whitespace
pre-commit run end-of-file-fixer

# Run hooks on specific files
pre-commit run --files README.md
```

### Commit Workflow

1. Make changes to your code
2. Stage your changes: `git add .`
3. Commit: `git commit -m "your commit message"`
4. Pre-commit hooks run automatically
5. If hooks fail, fix issues and retry commit

### Skipping Hooks (Not Recommended)

```bash
# Skip all hooks (use with caution)
git commit --no-verify -m "message"

# Skip specific hook
SKIP=markdownlint git commit -m "message"
```

## Hook Details

### TDD Compliance Check

This custom hook enforces the project's strict TDD methodology:

```bash
# Checks if production code changes have corresponding test changes
# Fails if src/main/java/ files are modified without src/test/java/ changes
```

### Maven Compilation Check

Ensures that all changes compile successfully:

```bash
# Runs: ./mvnw compile
# Fails if compilation fails
```

### Markdown Linting

Enforces consistent Markdown formatting:

- Line length: 120 characters
- Fenced code blocks with language specifiers
- Proper heading structure
- No trailing spaces

### No Direct Commits to Main

This hook prevents direct commits to the `main` branch, enforcing a
pull-request-based workflow where all changes reach `main` only through
reviewed PRs.

**When it fires:** The hook runs on every commit (`always_run: true`)
regardless of which files are staged. It checks the current branch name
using `git symbolic-ref --short HEAD`.

**Behavior:**

- On `main` branch: the hook exits with a non-zero status and displays
  an error message:

    ```text
    ERROR: Direct commits to main are not allowed. Please create a feature branch.
    ```

- On any other branch: the hook passes silently
- In detached HEAD states (common in CI): the hook passes gracefully

**Bypassing the hook:** In exceptional cases, you can skip the hook
using the standard `--no-verify` flag:

```bash
git commit --no-verify -m "message"
```

Use this only when absolutely necessary and document the reason for
bypassing.

## Troubleshooting

### Common Issues

#### Hook Installation Fails

```bash
# Update pre-commit
pipx upgrade pre-commit

# Clean and reinstall
pre-commit clean
pre-commit install
```

#### Hook Fails on Valid Files

```bash
# Check specific hook output
pre-commit run <hook-name> --verbose

# Update hook versions
pre-commit autoupdate
```

#### TDD Compliance False Positives

The TDD compliance hook may trigger false positives when:

- Refactoring existing code without test changes
- Moving files between directories
- Working with generated code

Solutions:

- Use `--no-verify` for legitimate refactoring (document reason)
- Update test files alongside production code
- Use feature branches for complex refactoring

### Performance

#### Slow Hook Execution

```bash
# Run hooks in parallel
pre-commit run --all-files --jobs 4

# Exclude certain files from hooks
# Modify .pre-commit-config.yaml exclude patterns
```

#### Maven Compilation Check Slow

The Maven compilation check ensures code quality but can be slow. Consider:

- Running it only on specific file changes
- Using incremental compilation
- Running less frequently during development

## Customization

### Adding New Hooks

1. Add to `.pre-commit-config.yaml`:

    ```yaml
    - repo: https://github.com/example/repo
      rev: v1.0.0
      hooks:
        - id: hook-name
          args: [--option]
    ```

2. Install updated hooks:

    ```bash
    pre-commit install
    pre-commit run --all-files
    ```

### Modifying Hook Behavior

Edit hook configurations in `.pre-commit-config.yaml`:

```yaml
- id: markdownlint
  args: ["--config", ".markdownlint.yaml", "--fix"]
  files: \.md$
```

### Excluding Files

Add patterns to exclude section:

```yaml
exclude: |
  (?x)^(
    \.git/.*|
    target/.*|
    \.idea/.*
  )$
```

## Best Practices

### Development Workflow

1. **Run hooks frequently**: Don't wait until commit time
2. **Fix issues incrementally**: Address problems as they arise
3. **Use local testing**: Test hooks before committing
4. **Document exceptions**: Note when skipping hooks is necessary

### Team Collaboration

1. **Consistent configuration**: Keep `.pre-commit-config.yaml` in sync
2. **Regular updates**: Update hook versions regularly
3. **Training**: Ensure team understands hook requirements
4. **Gradual adoption**: Start with essential hooks, add others over time

### Performance Optimization

1. **Selective hooks**: Run only relevant hooks for specific changes
2. **Parallel execution**: Use multiple jobs when possible
3. **Caching**: Leverage Maven and tool caching
4. **Exclude patterns**: Avoid unnecessary file processing

## Integration with CI/CD

### GitHub Actions Example

```yaml
- name: Run pre-commit
  run: |
    pipx install pre-commit
    pre-commit run --all-files
```

### Jenkins Pipeline

```groovy
stage('Pre-commit Checks') {
    steps {
        sh 'pipx install pre-commit'
        sh 'pre-commit run --all-files'
    }
}
```

## Maintenance

### Regular Updates

```bash
# Update hook versions
pre-commit autoupdate

# Test updated hooks
pre-commit run --all-files

# Commit updated configuration
git add .pre-commit-config.yaml
git commit -m "chore: update pre-commit hook versions"
```

### Monitoring

- Review hook performance regularly
- Monitor failure rates and patterns
- Gather team feedback on hook effectiveness
- Adjust configuration based on project needs

## Support

### Getting Help

```bash
# Pre-commit help
pre-commit --help

# Specific hook help
pre-commit run --help

# Configuration validation
pre-commit validate-config
```

### Common Resources

- [Pre-commit documentation](https://pre-commit.com/)
- [Available hooks](https://pre-commit.com/hooks.html)
- [Configuration guide](https://pre-commit.com/#configuration)

This guide ensures consistent code quality and development practices across the Emerald Grove Veterinary Clinic project.
