# Requirements Document

## Introduction

This specification defines improvements to the EC2 setup script (`ec2-setup.sh`) to ensure a complete and reliable basic environment setup on fresh EC2 instances. The current script installs essential tools (git, unzip, wget, curl, AWS CLI) but fails to install Python package management tools (pip), causing downstream failures when running `prereq.sh`. This enhancement will ensure the EC2 setup script provides a complete foundation for subsequent development environment setup.

## Glossary

- **EC2 Setup Script**: The `ec2-setup.sh` bash script that installs essential tools on a fresh EC2 instance
- **Prerequisites Script**: The `prereq.sh` bash script that checks and installs full development dependencies
- **System**: The EC2 setup script and its execution environment
- **Package Manager**: Operating system-specific tool for installing software (yum, apt-get)
- **Python Package Manager**: pip or pip3, used for installing Python packages
- **Essential Tools**: Minimum required software for cloning repositories and running setup scripts (git, unzip, wget, curl, AWS CLI, Python, pip)

## Requirements

### Requirement 1

**User Story:** As a cloud engineer, I want the EC2 setup script to install Python and pip, so that the prerequisites script can run successfully without manual intervention.

#### Acceptance Criteria

1. WHEN the EC2 setup script executes on a fresh EC2 instance THEN the System SHALL install Python 3.9 or higher
2. WHEN the EC2 setup script installs Python THEN the System SHALL install pip3 package manager
3. WHEN pip installation completes THEN the System SHALL verify pip3 is accessible via command line
4. WHEN the EC2 setup script completes THEN the System SHALL display the installed Python version
5. WHEN the EC2 setup script completes THEN the System SHALL display the installed pip version

### Requirement 2

**User Story:** As a cloud engineer, I want the EC2 setup script to handle different Linux distributions correctly, so that the script works reliably across Amazon Linux, Ubuntu, and other supported platforms.

#### Acceptance Criteria

1. WHEN the script runs on Amazon Linux THEN the System SHALL use yum package manager to install Python and pip
2. WHEN the script runs on Ubuntu or Debian THEN the System SHALL use apt-get package manager to install Python and pip
3. WHEN the script runs on Ubuntu 24.04 THEN the System SHALL handle the apt_pkg issue before installing Python packages
4. WHEN the script detects an unsupported OS THEN the System SHALL display an error message and exit gracefully
5. WHEN installing packages on Ubuntu/Debian THEN the System SHALL use python3-pip package for pip installation

### Requirement 3

**User Story:** As a cloud engineer, I want the EC2 setup script to verify all installations, so that I can identify failures immediately rather than discovering them later.

#### Acceptance Criteria

1. WHEN each tool installation completes THEN the System SHALL verify the tool is accessible via command line
2. WHEN a verification check fails THEN the System SHALL display an error message indicating which tool failed
3. WHEN a verification check fails THEN the System SHALL exit with a non-zero status code
4. WHEN all verifications pass THEN the System SHALL display a success message for each tool
5. WHEN the script completes successfully THEN the System SHALL display a summary of all installed tool versions

### Requirement 4

**User Story:** As a cloud engineer, I want the EC2 setup script to provide clear next steps, so that I know exactly what to do after the basic setup completes.

#### Acceptance Criteria

1. WHEN the EC2 setup script completes successfully THEN the System SHALL display instructions for configuring AWS credentials
2. WHEN the EC2 setup script completes successfully THEN the System SHALL display instructions for cloning the repository
3. WHEN the EC2 setup script completes successfully THEN the System SHALL display instructions for running the prerequisites script
4. WHEN the EC2 setup script completes successfully THEN the System SHALL display instructions for deploying the platform
5. WHEN displaying next steps THEN the System SHALL include exact commands that can be copied and executed

### Requirement 5

**User Story:** As a cloud engineer, I want the EC2 setup script to handle errors gracefully, so that I can troubleshoot issues without the script leaving the system in an inconsistent state.

#### Acceptance Criteria

1. WHEN a package installation fails THEN the System SHALL display the specific error message from the package manager
2. WHEN a critical installation fails THEN the System SHALL exit immediately without attempting subsequent installations
3. WHEN the script exits due to an error THEN the System SHALL return a non-zero exit code
4. WHEN disk space is insufficient THEN the System SHALL warn the user before proceeding with installations
5. WHEN the script encounters an error THEN the System SHALL provide troubleshooting guidance in the error message

### Requirement 6

**User Story:** As a cloud engineer, I want the EC2 setup script to be idempotent, so that I can safely re-run it without causing conflicts or duplicate installations.

#### Acceptance Criteria

1. WHEN a tool is already installed THEN the System SHALL skip installation and display the existing version
2. WHEN AWS CLI is already installed THEN the System SHALL not attempt to reinstall it
3. WHEN Python is already installed THEN the System SHALL verify the version meets minimum requirements
4. WHEN pip is already installed THEN the System SHALL skip pip installation
5. WHEN re-running the script THEN the System SHALL complete successfully without errors from existing installations

### Requirement 7

**User Story:** As a cloud engineer, I want the EC2 setup script to optimize for minimal disk space usage, so that it works on small EC2 instances with limited storage.

#### Acceptance Criteria

1. WHEN installing packages on Ubuntu/Debian THEN the System SHALL clean apt cache after installation
2. WHEN installing packages on Ubuntu/Debian THEN the System SHALL remove unnecessary packages using autoremove
3. WHEN installing AWS CLI THEN the System SHALL remove temporary installation files after completion
4. WHEN the script checks disk space THEN the System SHALL display available space in gigabytes
5. WHEN available disk space is below 5GB THEN the System SHALL prompt the user before continuing
