#!/bin/bash

# IAM Permissions Setup Script for MLOps Platform
# This script creates an IAM policy and attaches it to your user or role
# Usage: ./setup-iam.sh [--quick]

set -e

# Parse arguments
QUICK_MODE=false
if [ "$1" = "--quick" ]; then
    QUICK_MODE=true
fi

echo "========================================="
echo "MLOps Platform - IAM Permissions Setup"
echo "========================================="
echo ""

# Get current IAM identity
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "Error: Unable to get AWS identity. Please configure AWS CLI first."
    echo "Run: aws configure"
    exit 1
fi

USER_ARN=$(aws sts get-caller-identity --query Arn --output text)
USER_TYPE=$(echo $USER_ARN | cut -d':' -f6 | cut -d'/' -f1)

if [ "$QUICK_MODE" = false ]; then
    echo "Current Identity:"
    echo "  Account: $ACCOUNT_ID"
    echo "  ARN: $USER_ARN"
    echo "  Type: $USER_TYPE"
    echo ""
fi

# Policy configuration
POLICY_NAME="MLOpsPlatformDeploymentPolicy"
POLICY_FILE="infrastructure/deployment-iam-policy.json"

# Check if policy file exists
if [ ! -f "$POLICY_FILE" ]; then
    echo "Error: Policy file not found at $POLICY_FILE"
    exit 1
fi

echo "Step 1: Creating/updating IAM policy..."

# Check if policy already exists
EXISTING_POLICY=$(aws iam list-policies --scope Local --query "Policies[?PolicyName=='$POLICY_NAME'].Arn" --output text 2>/dev/null)

if [ -z "$EXISTING_POLICY" ]; then
    # Create new policy
    POLICY_ARN=$(aws iam create-policy \
        --policy-name $POLICY_NAME \
        --policy-document file://$POLICY_FILE \
        --description "Deployment permissions for MLOps Platform" \
        --query 'Policy.Arn' \
        --output text 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo "✓ Policy created: $POLICY_ARN"
    else
        echo "✗ Failed to create policy"
        exit 1
    fi
else
    POLICY_ARN=$EXISTING_POLICY
    echo "✓ Policy already exists: $POLICY_ARN"
    
    if [ "$QUICK_MODE" = false ]; then
        # Update policy with new version
        echo "  Updating policy to latest version..."
        aws iam create-policy-version \
            --policy-arn $POLICY_ARN \
            --policy-document file://$POLICY_FILE \
            --set-as-default > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo "✓ Policy updated to latest version"
        fi
    fi
fi

echo ""
echo "Step 2: Attaching policy to your identity..."

if [ "$USER_TYPE" = "user" ]; then
    # Extract username from ARN
    USERNAME=$(echo $USER_ARN | cut -d'/' -f2)
    
    # Attach policy to user
    aws iam attach-user-policy \
        --user-name $USERNAME \
        --policy-arn $POLICY_ARN 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✓ Policy attached to user: $USERNAME"
    else
        echo "✓ Policy already attached to user: $USERNAME"
    fi
    
elif [ "$USER_TYPE" = "assumed-role" ]; then
    # Extract role name from ARN
    ROLE_NAME=$(echo $USER_ARN | cut -d'/' -f2)
    
    echo "⚠ You are using an assumed role: $ROLE_NAME"
    echo ""
    echo "To attach the policy to the role, run:"
    echo "  aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn $POLICY_ARN"
    echo ""
    echo "Or ask your administrator to attach the policy."
    
else
    echo "⚠ Unknown identity type. Please attach the policy manually:"
    echo "  Policy ARN: $POLICY_ARN"
fi

echo ""
echo "Step 3: Verifying permissions..."

if [ "$QUICK_MODE" = true ]; then
    echo "Waiting 10 seconds for permissions to propagate..."
    sleep 10
fi

# Test CloudFormation access
if aws cloudformation list-stacks --max-results 1 >/dev/null 2>&1; then
    echo "✓ CloudFormation access verified"
else
    echo "✗ CloudFormation access failed"
    echo "  Note: It may take 10-30 seconds for permissions to propagate"
fi

echo ""
echo "========================================="
echo "IAM Setup Complete!"
echo "========================================="
echo ""
echo "Policy ARN: $POLICY_ARN"
echo ""
echo "Next Steps:"
echo "1. Wait 10-30 seconds for permissions to propagate (if needed)"
echo "2. Run: ./prereq.sh (to verify all prerequisites)"
echo "3. Run: ./deploy-complete.sh (to deploy the platform)"
echo ""
if [ "$USER_TYPE" = "user" ]; then
    echo "Troubleshooting:"
    echo "- Verify policy: aws iam list-attached-user-policies --user-name $USERNAME"
    echo "- Check logs: CloudWatch Logs for detailed errors"
fi
echo "- Full guide: docs/IAM_SETUP_GUIDE.md"
echo ""
echo "========================================="
