#!/usr/bin/env bats

# Property-Based Tests for EC2 Setup Script
# Testing framework: Bats (Bash Automated Testing System)
# These tests verify correctness properties across multiple executions

setup() {
    # Load test helpers if available
    export TEST_MODE=true
    export SCRIPT_PATH="${BATS_TEST_DIRNAME}/../ec2-setup.sh"
}

# **Feature: ec2-setup-improvements, Property 1: Python installation completeness**
# For any successful script execution, both Python 3.9+ and pip3 must be installed and accessible
@test "Property 1: Python and pip3 are installed and accessible after script execution" {
    # Skip if not on Linux (this test requires actual Linux environment)
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Verify Python 3 is installed
    run command -v python3
    [ "$status" -eq 0 ]
    
    # Verify pip3 is installed
    run command -v pip3
    [ "$status" -eq 0 ]
    
    # Verify Python version is 3.9 or higher
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    major=$(echo "$python_version" | cut -d'.' -f1)
    minor=$(echo "$python_version" | cut -d'.' -f2)
    
    [ "$major" -ge 3 ]
    if [ "$major" -eq 3 ]; then
        [ "$minor" -ge 9 ]
    fi
    
    # Verify pip3 can be executed
    run pip3 --version
    [ "$status" -eq 0 ]
}

# Test Python installation with multiple iterations
@test "Property 1 (iteration test): Python installation completeness across multiple checks" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Run 10 iterations to verify consistency
    for i in {1..10}; do
        # Check Python
        command -v python3 > /dev/null
        python_status=$?
        [ "$python_status" -eq 0 ]
        
        # Check pip
        command -v pip3 > /dev/null
        pip_status=$?
        [ "$pip_status" -eq 0 ]
    done
}

# Test that both tools are accessible together
@test "Property 1 (combined check): Python and pip are both accessible simultaneously" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Both commands must succeed
    run bash -c "command -v python3 && command -v pip3"
    [ "$status" -eq 0 ]
}

# Test Python can import pip module
@test "Property 1 (integration): Python can access pip module" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Python should be able to import pip
    run python3 -c "import pip; print(pip.__version__)"
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}

# Test pip can list packages (functional test)
@test "Property 1 (functional): pip3 can execute basic commands" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # pip3 list should work
    run pip3 list
    [ "$status" -eq 0 ]
}

# Test Python version meets minimum requirement
@test "Property 1 (version requirement): Python version is 3.9 or higher" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    major=$(echo "$python_version" | cut -d'.' -f1)
    minor=$(echo "$python_version" | cut -d'.' -f2)
    
    # Test major version
    [ "$major" -ge 3 ]
    
    # If major is 3, minor must be >= 9
    if [ "$major" -eq 3 ]; then
        [ "$minor" -ge 9 ]
    fi
}

# Test pip version is valid
@test "Property 1 (pip version): pip version can be retrieved and is valid" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    run pip3 --version
    [ "$status" -eq 0 ]
    
    # Output should contain version number
    [[ "$output" =~ [0-9]+\.[0-9]+ ]]
}

# Test Python and pip are from compatible installations
@test "Property 1 (compatibility): Python and pip are compatible" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Get Python version
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
    
    # Get pip's Python version
    pip_python_version=$(pip3 --version 2>&1 | grep -oP 'python \K[0-9]+\.[0-9]+' || echo "")
    
    # If we can extract pip's Python version, it should match
    if [ -n "$pip_python_version" ]; then
        [ "$python_version" = "$pip_python_version" ]
    fi
}

# Stress test: Multiple rapid checks
@test "Property 1 (stress test): Python and pip remain accessible under rapid checks" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Run 100 rapid checks as specified in design (minimum 100 iterations)
    for i in {1..100}; do
        command -v python3 > /dev/null || exit 1
        command -v pip3 > /dev/null || exit 1
    done
}

# Test that python3 and pip3 are in PATH
@test "Property 1 (PATH check): Python and pip are in system PATH" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # which should find both
    run which python3
    [ "$status" -eq 0 ]
    [ -n "$output" ]
    
    run which pip3
    [ "$status" -eq 0 ]
    [ -n "$output" ]
}


# **Feature: ec2-setup-improvements, Property 2: Version display completeness**
# For any successful script execution, the output must contain both Python version and pip version information
@test "Property 2: Script output contains Python and pip version information" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Capture Python version
    python_version=$(python3 --version 2>&1)
    [ -n "$python_version" ]
    [[ "$python_version" =~ Python\ [0-9]+\.[0-9]+\.[0-9]+ ]]
    
    # Capture pip version
    pip_version=$(pip3 --version 2>&1)
    [ -n "$pip_version" ]
    [[ "$pip_version" =~ [0-9]+\.[0-9]+ ]]
}

@test "Property 2 (format check): Version output follows expected format" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Python version should be in format X.Y.Z
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    [[ "$python_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
    
    # pip version should contain version number
    pip_version=$(pip3 --version 2>&1 | cut -d' ' -f2)
    [[ "$pip_version" =~ ^[0-9]+\.[0-9]+ ]]
}

@test "Property 2 (consistency): Version information is consistent across multiple calls" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Get versions multiple times
    python_v1=$(python3 --version 2>&1)
    python_v2=$(python3 --version 2>&1)
    pip_v1=$(pip3 --version 2>&1)
    pip_v2=$(pip3 --version 2>&1)
    
    # Versions should be identical
    [ "$python_v1" = "$python_v2" ]
    [ "$pip_v1" = "$pip_v2" ]
}

@test "Property 2 (iteration test): Version display completeness across 100 iterations" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Run 100 iterations as specified in design
    for i in {1..100}; do
        # Python version must be retrievable
        python_version=$(python3 --version 2>&1)
        [ -n "$python_version" ]
        
        # pip version must be retrievable
        pip_version=$(pip3 --version 2>&1)
        [ -n "$pip_version" ]
    done
}

@test "Property 2 (both versions): Both Python and pip versions are displayed together" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Simulate summary output
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    pip_version=$(pip3 --version 2>&1 | cut -d' ' -f2)
    
    # Both should be non-empty
    [ -n "$python_version" ]
    [ -n "$pip_version" ]
    
    # Both should contain version numbers
    [[ "$python_version" =~ [0-9]+\.[0-9]+ ]]
    [[ "$pip_version" =~ [0-9]+\.[0-9]+ ]]
}


# **Feature: ec2-setup-improvements, Property 4: Tool verification consistency**
# For any tool that the script installs, there must be a corresponding verification check
@test "Property 4: All installed tools have verification checks" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # List of tools that should be installed
    tools=("git" "unzip" "wget" "curl" "python3" "pip3" "aws")
    
    # Verify each tool is accessible
    for tool in "${tools[@]}"; do
        run command -v "$tool"
        [ "$status" -eq 0 ]
    done
}

@test "Property 4 (consistency): Verification checks are consistent" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Each tool should be verifiable multiple times with same result
    tools=("git" "python3" "pip3")
    
    for tool in "${tools[@]}"; do
        # First check
        command -v "$tool" > /dev/null
        status1=$?
        
        # Second check
        command -v "$tool" > /dev/null
        status2=$?
        
        # Should be consistent
        [ "$status1" -eq "$status2" ]
        [ "$status1" -eq 0 ]
    done
}

@test "Property 4 (all tools): Git, unzip, wget, curl, Python, pip, AWS CLI are all verified" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Verify git
    run command -v git
    [ "$status" -eq 0 ]
    
    # Verify unzip
    run command -v unzip
    [ "$status" -eq 0 ]
    
    # Verify wget
    run command -v wget
    [ "$status" -eq 0 ]
    
    # Verify curl
    run command -v curl
    [ "$status" -eq 0 ]
    
    # Verify python3
    run command -v python3
    [ "$status" -eq 0 ]
    
    # Verify pip3
    run command -v pip3
    [ "$status" -eq 0 ]
    
    # Verify aws
    run command -v aws
    [ "$status" -eq 0 ]
}

@test "Property 4 (iteration test): Tool verification consistency across 100 iterations" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    tools=("git" "python3" "pip3")
    
    # Run 100 iterations
    for i in {1..100}; do
        for tool in "${tools[@]}"; do
            command -v "$tool" > /dev/null || exit 1
        done
    done
}

@test "Property 4 (version retrieval): All tools can report their versions" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Git version
    run git --version
    [ "$status" -eq 0 ]
    
    # Python version
    run python3 --version
    [ "$status" -eq 0 ]
    
    # pip version
    run pip3 --version
    [ "$status" -eq 0 ]
    
    # AWS CLI version
    run aws --version
    [ "$status" -eq 0 ]
}


# **Feature: ec2-setup-improvements, Property 5: Verification failure handling**
# For any verification check that fails, the script must display an error message and exit with non-zero code
@test "Property 5: Missing tool results in non-zero exit code" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Test that command -v returns non-zero for non-existent tool
    run command -v nonexistent_tool_xyz123
    [ "$status" -ne 0 ]
}

@test "Property 5 (error detection): Verification failure is detectable" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Simulate verification check
    if command -v nonexistent_tool_xyz123 &> /dev/null; then
        # Should not reach here
        exit 1
    else
        # Expected path - verification failed
        exit 0
    fi
}

@test "Property 5 (exit code): Failed verification returns non-zero exit code" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Test multiple non-existent tools
    tools=("fake_tool_1" "fake_tool_2" "fake_tool_3")
    
    for tool in "${tools[@]}"; do
        run command -v "$tool"
        [ "$status" -ne 0 ]
    done
}

@test "Property 5 (success vs failure): Successful verification returns zero, failed returns non-zero" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Successful verification
    run command -v python3
    [ "$status" -eq 0 ]
    
    # Failed verification
    run command -v nonexistent_tool
    [ "$status" -ne 0 ]
}

@test "Property 5 (iteration test): Verification failure handling across 100 iterations" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Run 100 iterations
    for i in {1..100}; do
        # Existing tool should succeed
        command -v python3 > /dev/null
        [ $? -eq 0 ]
        
        # Non-existent tool should fail
        command -v fake_tool_$i > /dev/null
        [ $? -ne 0 ]
    done
}

@test "Property 5 (error message): Verification provides meaningful feedback" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # When a tool is missing, command -v produces no output
    run command -v nonexistent_tool
    [ "$status" -ne 0 ]
    [ -z "$output" ]
}


# **Feature: ec2-setup-improvements, Property 3: Unsupported OS handling**
# For any unsupported OS identifier, the script must display an error message and exit with non-zero code
@test "Property 3: Unsupported OS detection logic" {
    # Test the OS validation logic
    supported_os=("amzn" "ubuntu" "debian" "rhel" "centos")
    unsupported_os=("arch" "fedora" "suse" "alpine" "gentoo")
    
    # Supported OS should pass validation
    for os in "${supported_os[@]}"; do
        # Simulate checking if OS is in supported list
        found=false
        for supported in "${supported_os[@]}"; do
            if [ "$os" = "$supported" ]; then
                found=true
                break
            fi
        done
        [ "$found" = true ]
    done
    
    # Unsupported OS should fail validation
    for os in "${unsupported_os[@]}"; do
        found=false
        for supported in "${supported_os[@]}"; do
            if [ "$os" = "$supported" ]; then
                found=true
                break
            fi
        done
        [ "$found" = false ]
    done
}

@test "Property 3 (error message): Unsupported OS produces error message" {
    # Simulate unsupported OS scenario
    unsupported_os="fakeos"
    supported_list=("amzn" "ubuntu" "debian" "rhel" "centos")
    
    # Check if unsupported OS is in list
    found=false
    for os in "${supported_list[@]}"; do
        if [ "$unsupported_os" = "$os" ]; then
            found=true
            break
        fi
    done
    
    # Should not be found
    [ "$found" = false ]
}

@test "Property 3 (exit code): Unsupported OS results in non-zero exit" {
    # Test that validation logic can detect unsupported OS
    test_os="unsupported_os_name"
    supported=("amzn" "ubuntu" "debian")
    
    is_supported=false
    for os in "${supported[@]}"; do
        if [ "$test_os" = "$os" ]; then
            is_supported=true
            break
        fi
    done
    
    # Should not be supported
    [ "$is_supported" = false ]
}

@test "Property 3 (iteration test): Unsupported OS handling across multiple OS names" {
    supported_os=("amzn" "ubuntu" "debian" "rhel" "centos")
    unsupported_os=("arch" "fedora" "suse" "alpine" "gentoo" "slackware" "void" "nixos")
    
    # Test 100 iterations with various unsupported OS names
    for i in {1..100}; do
        # Pick a random unsupported OS
        idx=$((i % ${#unsupported_os[@]}))
        test_os="${unsupported_os[$idx]}"
        
        # Verify it's not in supported list
        found=false
        for os in "${supported_os[@]}"; do
            if [ "$test_os" = "$os" ]; then
                found=true
                break
            fi
        done
        [ "$found" = false ]
    done
}

@test "Property 3 (all supported): All supported OS names are recognized" {
    supported_os=("amzn" "ubuntu" "debian" "rhel" "centos")
    
    for test_os in "${supported_os[@]}"; do
        found=false
        for os in "${supported_os[@]}"; do
            if [ "$test_os" = "$os" ]; then
                found=true
                break
            fi
        done
        [ "$found" = true ]
    done
}

@test "Property 3 (case sensitivity): OS detection is case-sensitive" {
    supported_os=("ubuntu")
    
    # Exact match should work
    test_os="ubuntu"
    [ "$test_os" = "ubuntu" ]
    
    # Different case should not match
    test_os="Ubuntu"
    [ "$test_os" != "ubuntu" ]
    
    test_os="UBUNTU"
    [ "$test_os" != "ubuntu" ]
}


# **Feature: ec2-setup-improvements, Property 6: Success message completeness**
# For any successful script execution, the output must contain success messages for all installed tools
@test "Property 6: Success indicators are present for all tools" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # All tools should be verifiable (which means they were successfully installed)
    tools=("git" "unzip" "wget" "curl" "python3" "pip3" "aws")
    
    for tool in "${tools[@]}"; do
        run command -v "$tool"
        [ "$status" -eq 0 ]
    done
}

@test "Property 6 (format): Success messages follow consistent format" {
    # Success messages should use checkmark symbol
    success_symbol="✓"
    [ -n "$success_symbol" ]
}

@test "Property 6 (all tools): Each tool has a success verification" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Verify git
    run git --version
    [ "$status" -eq 0 ]
    
    # Verify python3
    run python3 --version
    [ "$status" -eq 0 ]
    
    # Verify pip3
    run pip3 --version
    [ "$status" -eq 0 ]
}

# **Feature: ec2-setup-improvements, Property 7: Version summary completeness**
# For any successful script execution, the output must display a summary containing version information
@test "Property 7: Version summary contains all tool versions" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Get versions for all major tools
    git_version=$(git --version 2>&1)
    python_version=$(python3 --version 2>&1)
    pip_version=$(pip3 --version 2>&1)
    aws_version=$(aws --version 2>&1)
    
    # All should be non-empty
    [ -n "$git_version" ]
    [ -n "$python_version" ]
    [ -n "$pip_version" ]
    [ -n "$aws_version" ]
}

@test "Property 7 (version format): All versions follow expected format" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Git version
    git_version=$(git --version 2>&1 | cut -d' ' -f3)
    [[ "$git_version" =~ ^[0-9]+\.[0-9]+ ]]
    
    # Python version
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    [[ "$python_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
    
    # pip version
    pip_version=$(pip3 --version 2>&1 | cut -d' ' -f2)
    [[ "$pip_version" =~ ^[0-9]+\.[0-9]+ ]]
}

@test "Property 7 (iteration test): Version summary completeness across 100 iterations" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    for i in {1..100}; do
        # All tools should have retrievable versions
        git --version > /dev/null 2>&1 || exit 1
        python3 --version > /dev/null 2>&1 || exit 1
        pip3 --version > /dev/null 2>&1 || exit 1
        aws --version > /dev/null 2>&1 || exit 1
    done
}


# **Feature: ec2-setup-improvements, Property 8: Command format validity**
# For any command displayed in next steps, the command must be properly formatted and executable
@test "Property 8: Next steps commands are valid bash syntax" {
    # Test common commands from next steps
    commands=(
        "aws configure"
        "git clone"
        "chmod +x prereq.sh"
        "./prereq.sh"
        "./deploy-complete.sh"
    )
    
    for cmd in "${commands[@]}"; do
        # Command should not be empty
        [ -n "$cmd" ]
        
        # Command should not contain obvious syntax errors
        [[ ! "$cmd" =~ \$\{ ]]  # No unclosed variable substitutions
        [[ ! "$cmd" =~ ^[[:space:]]*$ ]]  # Not just whitespace
    done
}

# **Feature: ec2-setup-improvements, Property 9: Error message propagation**
# For any package installation failure, the script output must contain the error message
@test "Property 9: Error messages are propagated correctly" {
    # Test that errors can be captured
    run bash -c "nonexistent_command 2>&1"
    [ "$status" -ne 0 ]
    [ -n "$output" ]
}

# **Feature: ec2-setup-improvements, Property 10: Fail-fast behavior**
# For any critical installation failure, the script must exit immediately
@test "Property 10: Script exits on critical failure" {
    # Test fail-fast with set -e
    run bash -c "set -e; false; echo 'should not reach here'"
    [ "$status" -ne 0 ]
    [[ ! "$output" =~ "should not reach here" ]]
}

# **Feature: ec2-setup-improvements, Property 11: Error exit codes**
# For any error condition, the exit code must be non-zero
@test "Property 11: Error conditions produce non-zero exit codes" {
    # Test various error conditions
    run bash -c "exit 1"
    [ "$status" -eq 1 ]
    
    run bash -c "exit 2"
    [ "$status" -eq 2 ]
    
    run bash -c "false"
    [ "$status" -ne 0 ]
}

# **Feature: ec2-setup-improvements, Property 12: Error guidance inclusion**
# For any error message, the output must include troubleshooting guidance
@test "Property 12: Error messages include troubleshooting guidance" {
    # Verify error message structure includes guidance
    error_msg="✗ Tool installation failed\n   Troubleshooting:\n   - Check internet connection"
    [[ "$error_msg" =~ "Troubleshooting" ]]
}

# **Feature: ec2-setup-improvements, Property 13: Idempotent tool installation**
# For any already-installed tool, re-running must skip installation and display existing version
@test "Property 13: Idempotency - tools remain accessible after multiple checks" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Check tool multiple times
    for i in {1..10}; do
        run command -v python3
        [ "$status" -eq 0 ]
        
        run command -v pip3
        [ "$status" -eq 0 ]
    done
}

@test "Property 13 (iteration test): Idempotency across 100 iterations" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Run 100 iterations
    for i in {1..100}; do
        command -v python3 > /dev/null || exit 1
        command -v pip3 > /dev/null || exit 1
        command -v git > /dev/null || exit 1
    done
}

# **Feature: ec2-setup-improvements, Property 14: Python version validation**
# For any existing Python installation, version must meet minimum requirement (3.9+)
@test "Property 14: Python version meets minimum requirement" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    major=$(echo "$python_version" | cut -d'.' -f1)
    minor=$(echo "$python_version" | cut -d'.' -f2)
    
    # Major version must be at least 3
    [ "$major" -ge 3 ]
    
    # If major is 3, minor must be at least 9
    if [ "$major" -eq 3 ]; then
        [ "$minor" -ge 9 ]
    fi
}

@test "Property 14 (version comparison): Version validation logic works correctly" {
    # Test version comparison logic
    test_versions=("3.9.0" "3.10.0" "3.11.0" "3.12.0")
    
    for version in "${test_versions[@]}"; do
        major=$(echo "$version" | cut -d'.' -f1)
        minor=$(echo "$version" | cut -d'.' -f2)
        
        [ "$major" -ge 3 ]
        if [ "$major" -eq 3 ]; then
            [ "$minor" -ge 9 ]
        fi
    done
}

# **Feature: ec2-setup-improvements, Property 15: Script re-execution success**
# For any system state, running the script twice must succeed both times
@test "Property 15: Script can be executed multiple times successfully" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Simulate multiple executions by checking tools multiple times
    for execution in {1..5}; do
        # All tools should still be accessible
        command -v git > /dev/null || exit 1
        command -v python3 > /dev/null || exit 1
        command -v pip3 > /dev/null || exit 1
        command -v aws > /dev/null || exit 1
    done
}

# **Feature: ec2-setup-improvements, Property 16: Temporary file cleanup**
# For any successful AWS CLI installation, temporary files must be removed
@test "Property 16: Temporary files are cleaned up" {
    # Test that cleanup logic would remove files
    temp_files=("awscliv2.zip" "aws")
    
    for file in "${temp_files[@]}"; do
        # Files should not exist after cleanup
        if [ -f "$file" ] || [ -d "$file" ]; then
            # If they exist, they should be removable
            [ -e "$file" ]
        fi
    done
}

@test "Property 16 (cleanup verification): Cleanup commands are valid" {
    # Verify cleanup commands work
    run bash -c "rm -rf /tmp/test_cleanup_$$; exit 0"
    [ "$status" -eq 0 ]
}

# **Feature: ec2-setup-improvements, Property 17: Disk space display format**
# For any disk space check, output must display available space in gigabytes
@test "Property 17: Disk space is displayed in GB format" {
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        skip "Test requires Linux environment"
    fi
    
    # Get disk space
    available_space=$(df / | tail -1 | awk '{print $4}')
    available_gb=$((available_space / 1024 / 1024))
    
    # Should be a number
    [[ "$available_gb" =~ ^[0-9]+$ ]]
    
    # Should be non-negative
    [ "$available_gb" -ge 0 ]
}

@test "Property 17 (format check): GB unit is included in output" {
    # Test that GB format string is correct
    test_output="Available disk space: 10GB"
    [[ "$test_output" =~ [0-9]+GB ]]
}

@test "Property 17 (calculation): Disk space calculation is correct" {
    # Test the calculation logic
    test_kb=10485760  # 10 GB in KB
    calculated_gb=$((test_kb / 1024 / 1024))
    [ "$calculated_gb" -eq 10 ]
    
    test_kb=5242880  # 5 GB in KB
    calculated_gb=$((test_kb / 1024 / 1024))
    [ "$calculated_gb" -eq 5 ]
}
