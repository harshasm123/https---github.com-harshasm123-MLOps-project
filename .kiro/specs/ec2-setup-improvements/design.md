# Design Document

## Overview

This design enhances the `ec2-setup.sh` script to provide a complete basic environment setup on fresh EC2 instances. The current implementation installs essential tools (git, unzip, wget, curl, AWS CLI) but lacks Python package management (pip), causing failures in downstream setup scripts. This enhancement adds Python and pip installation, improves error handling, ensures idempotency, and optimizes disk space usage.

The design maintains the script's philosophy of being a minimal, fast bootstrap that prepares an EC2 instance for cloning the repository and running the full prerequisites script.

## Architecture

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    EC2 Setup Script                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Environment Detection                                   │
│     ├─ Detect OS (Amazon Linux, Ubuntu, Debian)           │
│     ├─ Check disk space                                    │
│     └─ Set environment variables                           │
│                                                             │
│  2. System Package Installation                            │
│     ├─ Update package manager                              │
│     ├─ Install: git, unzip, wget, curl                    │
│     ├─ Install: Python 3.9+                                │
│     └─ Install: pip3                                       │
│                                                             │
│  3. AWS CLI Installation                                   │
│     ├─ Check if already installed                          │
│     ├─ Download installer                                  │
│     ├─ Install AWS CLI v2                                  │
│     └─ Clean up temporary files                            │
│                                                             │
│  4. Verification                                           │
│     ├─ Verify each tool is accessible                      │
│     ├─ Check versions meet requirements                    │
│     └─ Display installation summary                        │
│                                                             │
│  5. Cleanup & Summary                                      │
│     ├─ Clean package manager cache                         │
│     ├─ Remove temporary files                              │
│     └─ Display next steps                                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### OS-Specific Handling

The script supports multiple Linux distributions with different package managers:

**Amazon Linux / RHEL / CentOS:**
- Package Manager: `yum`
- Python Package: `python3`, `python3-pip`
- Update Command: `sudo yum update -y`

**Ubuntu / Debian:**
- Package Manager: `apt-get`
- Python Package: `python3`, `python3-pip`
- Update Command: `sudo apt-get update -y`
- Special handling for Ubuntu 24.04 apt_pkg issue

## Components and Interfaces

### 1. OS Detection Module

**Purpose:** Identify the operating system and version to determine appropriate package manager and commands.

**Inputs:**
- `/etc/os-release` file contents

**Outputs:**
- `OS` variable (amzn, ubuntu, debian, rhel, centos)
- `VERSION_ID` variable (OS version number)

**Logic:**
```bash
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    echo "Cannot detect OS. Exiting."
    exit 1
fi
```

### 2. Disk Space Checker

**Purpose:** Verify sufficient disk space before installation to prevent failures.

**Inputs:**
- Current filesystem usage from `df` command

**Outputs:**
- Available space in GB
- Warning message if space < 5GB
- User confirmation prompt if space is low

**Logic:**
```bash
AVAILABLE_SPACE=$(df / | tail -1 | awk '{print $4}')
AVAILABLE_GB=$((AVAILABLE_SPACE / 1024 / 1024))
if [ "$AVAILABLE_GB" -lt 5 ]; then
    # Prompt user
fi
```

### 3. Package Installation Module

**Purpose:** Install system packages using the appropriate package manager.

**Inputs:**
- OS type (from OS Detection)
- List of packages to install

**Outputs:**
- Installed packages
- Installation status messages
- Error messages on failure

**Package Lists:**
- Essential tools: `git unzip wget curl`
- Python: `python3 python3-pip`

### 4. Python Installation Module

**Purpose:** Install Python 3.9+ and pip3 package manager.

**Inputs:**
- OS type
- Package manager type

**Outputs:**
- Python 3.9+ installation
- pip3 installation
- Version information

**OS-Specific Commands:**
- Amazon Linux: `sudo yum install -y python3 python3-pip`
- Ubuntu/Debian: `sudo apt-get install -y python3 python3-pip`

### 5. AWS CLI Installation Module

**Purpose:** Install AWS CLI v2 if not already present.

**Inputs:**
- Current AWS CLI installation status

**Outputs:**
- AWS CLI v2 installation
- Cleaned up temporary files

**Logic:**
```bash
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
else
    # Already installed, skip
fi
```

### 6. Verification Module

**Purpose:** Verify all tools are correctly installed and accessible.

**Inputs:**
- List of tools to verify

**Outputs:**
- Success/failure status for each tool
- Version information
- Exit code (0 for success, non-zero for failure)

**Verification Checks:**
- `command -v <tool>` to check accessibility
- `<tool> --version` to get version information
- Exit immediately on any failure

### 7. Cleanup Module

**Purpose:** Remove temporary files and clean package manager caches to minimize disk usage.

**Actions:**
- Ubuntu/Debian: `sudo apt-get clean && sudo apt-get autoremove -y`
- AWS CLI: `rm -rf aws awscliv2.zip`
- Any other temporary files created during installation

### 8. Output Module

**Purpose:** Provide clear, actionable information to the user.

**Outputs:**
- Installation progress messages
- Success/failure indicators (✓/✗)
- Version information for installed tools
- Next steps with exact commands
- Error messages with troubleshooting guidance

## Data Models

### Installation Status

```bash
# Tool status tracking
TOOL_NAME="git"
TOOL_INSTALLED=true/false
TOOL_VERSION="2.34.1"
VERIFICATION_PASSED=true/false
```

### System Information

```bash
# OS information
OS="ubuntu"
VERSION_ID="24.04"
PACKAGE_MANAGER="apt-get"

# Disk space
AVAILABLE_SPACE_KB=10485760
AVAILABLE_GB=10
```

### Exit Codes

```bash
0   # Success
1   # General error (OS detection failed, tool installation failed)
2   # Verification failed
3   # Insufficient disk space (user declined to continue)
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Python installation completeness
*For any* successful script execution, both Python 3.9+ and pip3 must be installed and accessible via command line.
**Validates: Requirements 1.1, 1.2, 1.3**

### Property 2: Version display completeness
*For any* successful script execution, the output must contain both Python version and pip version information.
**Validates: Requirements 1.4, 1.5**

### Property 3: Unsupported OS handling
*For any* unsupported OS identifier, the script must display an error message and exit with a non-zero status code.
**Validates: Requirements 2.4**

### Property 4: Tool verification consistency
*For any* tool that the script installs, there must be a corresponding verification check that confirms the tool is accessible.
**Validates: Requirements 3.1**

### Property 5: Verification failure handling
*For any* verification check that fails, the script must display an error message identifying the failed tool and exit with a non-zero status code.
**Validates: Requirements 3.2, 3.3**

### Property 6: Success message completeness
*For any* successful script execution, the output must contain success messages for all installed tools.
**Validates: Requirements 3.4**

### Property 7: Version summary completeness
*For any* successful script execution, the output must display a summary containing version information for all installed tools.
**Validates: Requirements 3.5**

### Property 8: Command format validity
*For any* command displayed in the next steps section, the command must be properly formatted and executable (no syntax errors).
**Validates: Requirements 4.5**

### Property 9: Error message propagation
*For any* package installation failure, the script output must contain the error message from the package manager.
**Validates: Requirements 5.1**

### Property 10: Fail-fast behavior
*For any* critical installation failure, the script must exit immediately without executing subsequent installation steps.
**Validates: Requirements 5.2**

### Property 11: Error exit codes
*For any* error condition that causes script termination, the exit code must be non-zero.
**Validates: Requirements 5.3**

### Property 12: Error guidance inclusion
*For any* error message displayed, the output must include troubleshooting guidance or suggested actions.
**Validates: Requirements 5.5**

### Property 13: Idempotent tool installation
*For any* tool that is already installed, re-running the script must skip installation and display the existing version without errors.
**Validates: Requirements 6.1**

### Property 14: Python version validation
*For any* existing Python installation, the script must verify the version meets the minimum requirement (3.9+) before skipping installation.
**Validates: Requirements 6.3**

### Property 15: Script re-execution success
*For any* system state, running the script twice in succession must result in successful completion both times.
**Validates: Requirements 6.5**

### Property 16: Temporary file cleanup
*For any* successful AWS CLI installation, all temporary installation files must be removed from the filesystem.
**Validates: Requirements 7.3**

### Property 17: Disk space display format
*For any* disk space check, the output must display available space in gigabytes with the "GB" unit.
**Validates: Requirements 7.4**

## Error Handling

### Error Categories

**1. Environment Errors**
- OS detection failure
- Insufficient disk space
- Missing /etc/os-release file

**Handling:** Display clear error message, provide troubleshooting steps, exit with code 1

**2. Installation Errors**
- Package manager update failure
- Package installation failure
- Network connectivity issues (AWS CLI download)

**Handling:** Display package manager error output, suggest checking internet connectivity and permissions, exit with code 1

**3. Verification Errors**
- Tool not found after installation
- Version check failure
- Command execution failure

**Handling:** Display which tool failed verification, suggest manual installation steps, exit with code 2

**4. Permission Errors**
- Insufficient privileges for sudo commands
- File system permission issues

**Handling:** Display permission error, suggest running with appropriate privileges, exit with code 1

### Error Recovery

The script follows a fail-fast approach:
- Critical errors (OS detection, essential tool installation) cause immediate exit
- Each installation step is verified before proceeding
- No automatic retry logic (user must re-run script after fixing issues)
- Idempotent design allows safe re-execution after fixing problems

### Error Messages Format

```bash
echo "✗ <Tool> installation failed"
echo "   Error: <specific error message>"
echo "   Troubleshooting:"
echo "   - <suggestion 1>"
echo "   - <suggestion 2>"
exit <error_code>
```

## Testing Strategy

### Unit Testing Approach

Unit tests will verify specific behaviors and edge cases:

**Test Categories:**
1. **OS Detection Tests**
   - Test with various /etc/os-release formats
   - Test with missing /etc/os-release file
   - Test with unsupported OS identifiers

2. **Disk Space Tests**
   - Test with sufficient disk space (>5GB)
   - Test with low disk space (<5GB)
   - Test user response handling (y/n prompts)

3. **Installation Logic Tests**
   - Test package manager command generation for each OS
   - Test idempotency (skip already-installed tools)
   - Test version checking logic

4. **Verification Tests**
   - Test successful verification flow
   - Test verification failure handling
   - Test version extraction from command output

5. **Output Format Tests**
   - Test success message formatting
   - Test error message formatting
   - Test next steps display

### Property-Based Testing Approach

Property-based tests will verify universal behaviors across many inputs using **Bats (Bash Automated Testing System)** as the testing framework.

**Property Test Configuration:**
- Minimum iterations: 100 runs per property
- Test framework: Bats with bats-support and bats-assert libraries
- Test environment: Docker containers with different OS images

**Property Test Categories:**

1. **Installation Completeness Properties**
   - Generate random combinations of pre-installed tools
   - Verify all required tools are present after script execution
   - Verify version requirements are met

2. **Idempotency Properties**
   - Run script multiple times with various initial states
   - Verify consistent successful outcomes
   - Verify no duplicate installations or errors

3. **Error Handling Properties**
   - Simulate various failure conditions
   - Verify appropriate error messages and exit codes
   - Verify fail-fast behavior

4. **Output Format Properties**
   - Verify output always contains required information
   - Verify command syntax in next steps
   - Verify version information format

**Property Test Tagging:**
Each property-based test must include a comment tag in this format:
```bash
# **Feature: ec2-setup-improvements, Property {number}: {property_text}**
```

Example:
```bash
# **Feature: ec2-setup-improvements, Property 1: Python installation completeness**
@test "Python and pip3 are installed after script execution" {
  # Test implementation
}
```

### Integration Testing

Integration tests will verify the script works correctly in real environments:

1. **EC2 Instance Testing**
   - Test on fresh Amazon Linux 2023 instance
   - Test on fresh Ubuntu 24.04 instance
   - Test on fresh Ubuntu 22.04 instance
   - Verify prereq.sh runs successfully after ec2-setup.sh

2. **End-to-End Flow Testing**
   - Run ec2-setup.sh → configure AWS → clone repo → run prereq.sh
   - Verify complete deployment pipeline works

### Test Execution Strategy

1. **Local Development:** Run Bats tests in Docker containers
2. **CI/CD Pipeline:** Run tests on actual EC2 instances in AWS
3. **Manual Testing:** Test on various EC2 instance types and sizes

### Success Criteria

- All unit tests pass
- All property-based tests pass (100 iterations each)
- Integration tests pass on all supported OS versions
- Script completes in < 5 minutes on t2.micro instance
- Disk space usage < 1GB for basic setup

## Implementation Notes

### Ubuntu 24.04 Special Handling

Ubuntu 24.04 has an apt_pkg issue that must be handled before package installation:

```bash
if [ "$OS" = "ubuntu" ] && [ "$VERSION_ID" = "24.04" ]; then
    sudo rm -f /var/lib/command-not-found/commands.db.metadata 2>/dev/null || true
    export APT_LISTCHANGES_FRONTEND=none
    export DEBIAN_FRONTEND=noninteractive
fi
```

### Python Version Requirements

- Minimum version: Python 3.9
- Preferred version: Python 3.11+ (better performance)
- Amazon Linux 2023: Comes with Python 3.11
- Ubuntu 24.04: Comes with Python 3.12
- Ubuntu 22.04: Comes with Python 3.10 (acceptable)

### Disk Space Optimization

Target disk usage for basic setup: ~500MB
- Essential tools: ~100MB
- Python + pip: ~200MB
- AWS CLI: ~150MB
- Temporary files during installation: ~50MB (cleaned up)

### Performance Targets

- Total execution time: < 5 minutes on t2.micro
- Network bandwidth: < 100MB download
- CPU usage: Minimal (package installation only)

## Security Considerations

1. **Sudo Usage:** Script requires sudo for package installation
2. **Download Verification:** AWS CLI downloaded from official AWS URL
3. **Package Sources:** Use official OS package repositories
4. **No Credential Storage:** Script does not handle AWS credentials
5. **Minimal Attack Surface:** Only installs essential tools

## Future Enhancements

Potential improvements for future iterations:

1. **Parallel Installation:** Install tools concurrently to reduce execution time
2. **Progress Indicators:** Add progress bars for long-running operations
3. **Logging:** Write detailed logs to /var/log/ec2-setup.log
4. **Rollback:** Add ability to undo installations on failure
5. **Configuration File:** Support custom tool versions via config file
6. **Offline Mode:** Support installation from local package cache
