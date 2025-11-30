# EC2 Setup Script Tests

## Overview

This directory contains property-based tests for the `ec2-setup.sh` script using Bats (Bash Automated Testing System).

## Test Framework

- **Framework**: Bats (Bash Automated Testing System)
- **Test File**: `test_ec2_setup.bats`
- **Properties Tested**: 17 correctness properties
- **Minimum Iterations**: 100 per property (as specified in design)

## Prerequisites

### Install Bats

**On Ubuntu/Debian:**
```bash
sudo apt-get install -y bats
```

**On Amazon Linux/RHEL:**
```bash
sudo yum install -y bats
```

**Using npm:**
```bash
npm install -g bats
```

**From source:**
```bash
git clone https://github.com/bats-core/bats-core.git
cd bats-core
sudo ./install.sh /usr/local
```

## Running Tests

### Run All Tests

```bash
# From project root
bats tests/test_ec2_setup.bats

# Or from tests directory
cd tests
bats test_ec2_setup.bats
```

### Run Specific Test

```bash
# Run a specific test by name
bats tests/test_ec2_setup.bats -f "Property 1"

# Run tests matching a pattern
bats tests/test_ec2_setup.bats -f "Python"
```

### Verbose Output

```bash
# Show all test output
bats tests/test_ec2_setup.bats --verbose

# Show timing information
bats tests/test_ec2_setup.bats --timing
```

## Test Coverage

### Properties Tested

1. **Property 1**: Python installation completeness (10 tests)
2. **Property 2**: Version display completeness (5 tests)
3. **Property 3**: Unsupported OS handling (6 tests)
4. **Property 4**: Tool verification consistency (5 tests)
5. **Property 5**: Verification failure handling (6 tests)
6. **Property 6**: Success message completeness (3 tests)
7. **Property 7**: Version summary completeness (3 tests)
8. **Property 8**: Command format validity (1 test)
9. **Property 9**: Error message propagation (1 test)
10. **Property 10**: Fail-fast behavior (1 test)
11. **Property 11**: Error exit codes (1 test)
12. **Property 12**: Error guidance inclusion (1 test)
13. **Property 13**: Idempotent tool installation (2 tests)
14. **Property 14**: Python version validation (2 tests)
15. **Property 15**: Script re-execution success (1 test)
16. **Property 16**: Temporary file cleanup (2 tests)
17. **Property 17**: Disk space display format (3 tests)

**Total**: 53 test cases covering 17 correctness properties

### Requirements Coverage

All tests map back to specific requirements in `.kiro/specs/ec2-setup-improvements/requirements.md`:

- Requirements 1.1-1.5: Python and pip installation
- Requirements 2.1-2.5: Multi-OS support
- Requirements 3.1-3.5: Installation verification
- Requirements 4.1-4.5: Next steps instructions
- Requirements 5.1-5.5: Error handling
- Requirements 6.1-6.5: Idempotency
- Requirements 7.1-7.5: Disk space optimization

## Test Environment

### Supported Platforms

Tests are designed to run on:
- Amazon Linux 2023
- Ubuntu 24.04 / 22.04 / 20.04
- Debian 11 / 12
- RHEL 8 / 9
- CentOS 8 / 9

### Windows/macOS

Most tests will be skipped on Windows/macOS with message:
```
skipped: Test requires Linux environment
```

To run tests on Windows/macOS, use Docker:

```bash
# Run tests in Ubuntu container
docker run -it --rm -v $(pwd):/workspace ubuntu:24.04 bash
cd /workspace
apt-get update && apt-get install -y bats
bats tests/test_ec2_setup.bats
```

## Test Results

### Expected Output

```
✓ Property 1: Python and pip3 are installed and accessible after script execution
✓ Property 1 (iteration test): Python installation completeness across multiple checks
✓ Property 1 (combined check): Python and pip are both accessible simultaneously
...
✓ Property 17 (calculation): Disk space calculation is correct

53 tests, 0 failures
```

### Interpreting Failures

If tests fail, check:

1. **Tool not installed**: Run `ec2-setup.sh` first
2. **Version too old**: Ensure Python 3.9+ is installed
3. **Permission issues**: Run with appropriate privileges
4. **OS not supported**: Use a supported Linux distribution

## Continuous Integration

### GitHub Actions

Add to `.github/workflows/test.yml`:

```yaml
name: EC2 Setup Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Bats
        run: sudo apt-get install -y bats
      - name: Run EC2 setup script
        run: |
          chmod +x ec2-setup.sh
          sudo ./ec2-setup.sh
      - name: Run tests
        run: bats tests/test_ec2_setup.bats
```

### AWS CodeBuild

Add to `buildspec-test.yml`:

```yaml
version: 0.2

phases:
  install:
    commands:
      - yum install -y bats
  pre_build:
    commands:
      - chmod +x ec2-setup.sh
      - ./ec2-setup.sh
  build:
    commands:
      - bats tests/test_ec2_setup.bats
```

## Troubleshooting

### "bats: command not found"

Install Bats using one of the methods in Prerequisites section.

### "Test requires Linux environment"

Tests are skipped on non-Linux platforms. Use Docker to run tests.

### "Python installation failed"

Ensure `ec2-setup.sh` has been run successfully before running tests.

### "Permission denied"

Some tests may require sudo privileges. Run with:
```bash
sudo bats tests/test_ec2_setup.bats
```

## Contributing

When adding new tests:

1. Follow the property-based testing approach
2. Include the property tag comment:
   ```bash
   # **Feature: ec2-setup-improvements, Property X: Description**
   ```
3. Run at least 100 iterations for property tests
4. Map tests to specific requirements
5. Add test documentation to this README

## Additional Resources

- [Bats Documentation](https://bats-core.readthedocs.io/)
- [EC2 Setup Guide](../docs/EC2_SETUP_GUIDE.md)
- [Setup Scripts Guide](../docs/SETUP_SCRIPTS.md)
- [Design Document](../.kiro/specs/ec2-setup-improvements/design.md)
- [Requirements Document](../.kiro/specs/ec2-setup-improvements/requirements.md)
