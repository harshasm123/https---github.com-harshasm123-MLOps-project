# EC2 Setup Guide

## Overview

This guide walks you through setting up a fresh EC2 instance for the MLOps platform using the `ec2-setup.sh` script.

## Prerequisites

- AWS account with EC2 access
- EC2 instance running a supported Linux distribution:
  - Amazon Linux 2023
  - Ubuntu 24.04 / 22.04 / 20.04
  - Debian 11 / 12
  - RHEL 8 / 9
  - CentOS 8 / 9
- SSH access to the EC2 instance
- At least 10GB of free disk space (recommended)

## Quick Start

### Step 1: Connect to EC2 Instance

```bash
# SSH into your EC2 instance
ssh -i your-key.pem ubuntu@<ec2-public-ip>

# Or for Amazon Linux
ssh -i your-key.pem ec2-user@<ec2-public-ip>
```

### Step 2: Download and Run Setup Script

```bash
# Download the setup script
wget https://raw.githubusercontent.com/your-repo/main/ec2-setup.sh

# Make it executable
chmod +x ec2-setup.sh

# Run the script
./ec2-setup.sh
```

### Step 3: Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter default region (e.g., us-east-1)
# Enter default output format (json)
```

### Step 4: Clone Repository and Continue Setup

```bash
# Clone the repository
git clone https://github.com/your-repo/mlops-platform.git
cd mlops-platform

# Run full prerequisites check
chmod +x prereq.sh
./prereq.sh

# Deploy the platform
./deploy-complete.sh
```

## What the Script Does

The `ec2-setup.sh` script performs the following actions:

1. **OS Detection**
   - Detects the operating system and version
   - Validates that the OS is supported
   - Exits with error if OS is unsupported

2. **Disk Space Check**
   - Checks available disk space
   - Warns if less than 5GB available
   - Prompts user to continue or abort

3. **Essential Tools Installation**
   - Installs: git, unzip, wget, curl
   - Uses appropriate package manager (yum or apt-get)
   - Cleans up package cache to save space

4. **Python and pip Installation**
   - Installs Python 3.9 or higher
   - Installs pip3 package manager
   - Verifies both are accessible

5. **AWS CLI Installation**
   - Downloads and installs AWS CLI v2
   - Skips if already installed
   - Removes temporary installation files

6. **Verification**
   - Verifies each tool is accessible
   - Displays version information
   - Exits with error if any verification fails

7. **Summary**
   - Displays all installed tools and versions
   - Provides clear next steps

## Script Features

### Idempotency

The script is idempotent - you can safely run it multiple times:
- Already-installed tools are detected and skipped
- Existing versions are displayed
- No errors from duplicate installations

### Multi-OS Support

Automatically detects and handles:
- **Amazon Linux / RHEL / CentOS**: Uses `yum` package manager
- **Ubuntu / Debian**: Uses `apt-get` package manager
- **Ubuntu 24.04**: Special handling for apt_pkg issues

### Error Handling

- Fail-fast behavior: exits immediately on critical errors
- Clear error messages with troubleshooting guidance
- Non-zero exit codes for all error conditions
- Package manager errors are propagated to output

### Disk Space Optimization

- Cleans apt cache after installation (Ubuntu/Debian)
- Removes unnecessary packages with autoremove
- Removes temporary AWS CLI installation files
- Total disk usage: ~700MB

## Troubleshooting

### "Cannot detect OS"

**Cause:** Missing or invalid `/etc/os-release` file

**Solution:**
```bash
# Check if file exists
cat /etc/os-release

# If missing, you may be on an unsupported distribution
# Install tools manually or use a supported OS
```

### "Unsupported OS: <os-name>"

**Cause:** Running on a Linux distribution that's not supported

**Solution:**
- Use a supported distribution (Amazon Linux, Ubuntu, Debian, RHEL, CentOS)
- Or install tools manually:
  ```bash
  # Install required tools using your package manager
  # git, unzip, wget, curl, python3, python3-pip, AWS CLI
  ```

### "Low disk space" Warning

**Cause:** Less than 5GB of free disk space

**Solution:**
```bash
# Check disk usage
df -h

# Clean up if needed
sudo apt-get clean
sudo apt-get autoremove -y

# Or increase EBS volume size in AWS Console
```

### "Python installation failed"

**Cause:** Python package not available or installation error

**Solution:**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y python3 python3-pip

# Amazon Linux/RHEL
sudo yum install -y python3 python3-pip

# Verify installation
python3 --version
pip3 --version
```

### "pip installation failed"

**Cause:** pip package not available or installation error

**Solution:**
```bash
# Try installing pip separately
sudo apt-get install -y python3-pip  # Ubuntu/Debian
sudo yum install -y python3-pip      # Amazon Linux/RHEL

# Or use ensurepip
python3 -m ensurepip

# Verify installation
pip3 --version
```

### "AWS CLI installation failed"

**Cause:** Network issues or download failure

**Solution:**
```bash
# Check internet connectivity
ping google.com

# Try manual installation
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# Verify installation
aws --version
```

### Permission Errors

**Cause:** Insufficient privileges for sudo commands

**Solution:**
```bash
# Ensure you're using a user with sudo access
sudo -v

# If not, switch to a user with sudo privileges
# Or run commands as root (not recommended)
```

## EC2 Instance Recommendations

### Instance Type

- **Minimum**: t2.micro (1 vCPU, 1GB RAM) - for testing only
- **Recommended**: t3.small (2 vCPU, 2GB RAM) - for development
- **Production**: t3.medium or larger (2 vCPU, 4GB RAM+)

### Storage

- **Minimum**: 10GB EBS volume
- **Recommended**: 20GB EBS volume
- **Type**: gp3 (better performance/cost than gp2)

### AMI Selection

Recommended AMIs:
- **Amazon Linux 2023** (ami-0c55b159cbfafe1f0)
- **Ubuntu 24.04 LTS** (ami-0c7217cdde317cfec)
- **Ubuntu 22.04 LTS** (ami-0c7217cdde317cfec)

### Security Group

Ensure your security group allows:
- SSH (port 22) from your IP
- HTTPS (port 443) for AWS API calls
- Any application-specific ports

### IAM Role

Attach an IAM role with permissions for:
- SageMaker (full access or specific permissions)
- S3 (read/write access)
- Lambda (if using Lambda functions)
- CloudFormation (for infrastructure deployment)

## Performance

### Execution Time

- **t2.micro**: ~5-7 minutes
- **t3.small**: ~3-5 minutes
- **t3.medium**: ~2-3 minutes

### Network Usage

- Total download: ~100MB
- AWS CLI installer: ~50MB
- Package updates: ~50MB

### Disk Space Usage

- Essential tools: ~100MB
- Python + pip: ~200MB
- AWS CLI: ~150MB
- Temporary files: ~50MB (cleaned up)
- **Total**: ~700MB

## Next Steps

After running `ec2-setup.sh`:

1. **Configure AWS credentials** (required)
   ```bash
   aws configure
   ```

2. **Clone the repository** (required)
   ```bash
   git clone https://github.com/your-repo/mlops-platform.git
   cd mlops-platform
   ```

3. **Run prerequisites check** (required)
   ```bash
   chmod +x prereq.sh
   ./prereq.sh
   ```

4. **Deploy the platform** (optional)
   ```bash
   ./deploy-complete.sh
   ```

## Additional Resources

- [Setup Scripts Guide](SETUP_SCRIPTS.md) - Detailed comparison of setup scripts
- [Prerequisites Guide](QUICKSTART.md) - Full prerequisites documentation
- [Deployment Guide](DEPLOYMENT.md) - Platform deployment instructions
- [AWS Well-Architected](AWS_WELL_ARCHITECTED.md) - Architecture best practices

## Support

If you encounter issues:

1. Check the error message carefully
2. Review the troubleshooting section above
3. Verify disk space: `df -h`
4. Check internet connectivity: `ping google.com`
5. Verify AWS credentials: `aws sts get-caller-identity`
6. Review logs in `/var/log/` (on Linux)

For deployment issues, see:
- [Deployment Guide](DEPLOYMENT.md)
- [Quick Start Guide](QUICKSTART.md)
- [Backend Enhancements](BACKEND_ENHANCEMENTS.md)
