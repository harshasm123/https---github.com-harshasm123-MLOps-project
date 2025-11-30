#!/bin/bash

# Complete MLOps Platform Deployment Script
# Deploys all three pipelines: Infrastructure, CI/CD, and Data Pipeline

set -e

# Configuration
STACK_NAME_BASE="mlops-platform"
ENVIRONMENT="dev"
REGION="us-east-1"

# Get AWS Account ID for unique bucket naming
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
DATASET_BUCKET_NAME="${STACK_NAME_BASE}-data-${ENVIRONMENT}-${AWS_ACCOUNT_ID}"

echo "========================================="
echo "Complete MLOps Platform Deployment"
echo "AWS Well-Architected Framework Compliant"
echo "========================================="
echo "Environment: $ENVIRONMENT"
echo "Region: $REGION"
echo "Dataset Bucket: $DATASET_BUCKET_NAME"
echo "========================================="
echo ""

# Prompt for GitHub credentials for CI/CD (optional)
echo "CI/CD Pipeline Setup (Optional)"
echo "--------------------------------"
echo "The CI/CD pipeline requires GitHub integration."
echo "If you want to skip CI/CD deployment, just press Enter."
echo ""
read -p "Enter GitHub repository (format: owner/repo) or press Enter to skip: " GITHUB_REPO

if [ -n "$GITHUB_REPO" ]; then
    read -p "Enter GitHub branch [main]: " GITHUB_BRANCH
    GITHUB_BRANCH=${GITHUB_BRANCH:-main}
    
    read -sp "Enter GitHub Personal Access Token: " GITHUB_TOKEN
    echo ""
    echo "✓ GitHub credentials provided"
else
    echo "⚠ Skipping CI/CD pipeline deployment"
fi

echo ""
echo "========================================="

# Step 1: Deploy Main Infrastructure
echo ""
echo "Step 1: Deploying main infrastructure..."
aws cloudformation create-stack \
  --stack-name ${STACK_NAME_BASE}-${ENVIRONMENT} \
  --template-body file://infrastructure/cloudformation-template.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
    ParameterKey=DatasetBucketName,ParameterValue=$DATASET_BUCKET_NAME \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $REGION

echo "Waiting for main infrastructure stack..."
aws cloudformation wait stack-create-complete \
  --stack-name ${STACK_NAME_BASE}-${ENVIRONMENT} \
  --region $REGION

echo "✓ Main infrastructure deployed"

# Get outputs
API_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME_BASE}-${ENVIRONMENT} \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
  --output text \
  --region $REGION)

DATA_BUCKET=$(aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME_BASE}-${ENVIRONMENT} \
  --query 'Stacks[0].Outputs[?OutputKey==`DataBucketName`].OutputValue' \
  --output text \
  --region $REGION)

MODEL_BUCKET=$(aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME_BASE}-${ENVIRONMENT} \
  --query 'Stacks[0].Outputs[?OutputKey==`ModelBucketName`].OutputValue' \
  --output text \
  --region $REGION)

echo "API Endpoint: $API_ENDPOINT"
echo "Data Bucket: $DATA_BUCKET"
echo "Model Bucket: $MODEL_BUCKET"

# Step 2: Deploy CI/CD Pipeline (Optional - requires GitHub token)
echo ""
echo "Step 2: CI/CD Pipeline deployment..."

if [ -n "$GITHUB_TOKEN" ] && [ -n "$GITHUB_REPO" ]; then
    echo "GitHub credentials found, deploying CI/CD pipeline..."
    aws cloudformation create-stack \
      --stack-name ${STACK_NAME_BASE}-cicd-${ENVIRONMENT} \
      --template-body file://infrastructure/cicd-pipeline.yaml \
      --parameters \
        ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
        ParameterKey=GitHubToken,ParameterValue=$GITHUB_TOKEN \
        ParameterKey=GitHubRepo,ParameterValue=${GITHUB_REPO} \
        ParameterKey=GitHubBranch,ParameterValue=${GITHUB_BRANCH:-main} \
      --capabilities CAPABILITY_NAMED_IAM \
      --region $REGION

    echo "Waiting for CI/CD pipeline stack..."
    aws cloudformation wait stack-create-complete \
      --stack-name ${STACK_NAME_BASE}-cicd-${ENVIRONMENT} \
      --region $REGION

    echo "✓ CI/CD pipeline deployed"

    # Get CI/CD outputs
    REPO_URL=$(aws cloudformation describe-stacks \
      --stack-name ${STACK_NAME_BASE}-cicd-${ENVIRONMENT} \
      --query 'Stacks[0].Outputs[?OutputKey==`MLCodeRepositoryCloneUrl`].OutputValue' \
      --output text \
      --region $REGION)

    PIPELINE_NAME=$(aws cloudformation describe-stacks \
      --stack-name ${STACK_NAME_BASE}-cicd-${ENVIRONMENT} \
      --query 'Stacks[0].Outputs[?OutputKey==`PipelineName`].OutputValue' \
      --output text \
      --region $REGION)

    echo "Repository URL: $REPO_URL"
    echo "Pipeline Name: $PIPELINE_NAME"
else
    echo "⚠ Skipping CI/CD pipeline (GitHub credentials not provided)"
    echo "  To deploy CI/CD later, set environment variables:"
    echo "    export GITHUB_TOKEN=your_token"
    echo "    export GITHUB_REPO=owner/repo"
    echo "  Then run: aws cloudformation create-stack --stack-name ${STACK_NAME_BASE}-cicd-${ENVIRONMENT} ..."
    REPO_URL="Not deployed"
    PIPELINE_NAME="Not deployed"
fi

# Step 3: Upload Glue Scripts (if they exist)
echo ""
echo "Step 3: Uploading Glue scripts..."
if [ -d "glue-scripts" ]; then
    if [ -f "glue-scripts/data_validation.py" ]; then
        aws s3 cp glue-scripts/data_validation.py s3://${DATA_BUCKET}/glue-scripts/ --region $REGION
    fi
    if [ -f "glue-scripts/data_preprocessing.py" ]; then
        aws s3 cp glue-scripts/data_preprocessing.py s3://${DATA_BUCKET}/glue-scripts/ --region $REGION
    fi
    echo "✓ Glue scripts uploaded"
else
    echo "⚠ Glue scripts directory not found, skipping"
fi

# Step 4: Deploy Data Pipeline
echo ""
echo "Step 4: Deploying data pipeline..."
aws cloudformation create-stack \
  --stack-name ${STACK_NAME_BASE}-data-pipeline-${ENVIRONMENT} \
  --template-body file://infrastructure/data-pipeline.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
    ParameterKey=DataBucket,ParameterValue=$DATA_BUCKET \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $REGION

echo "Waiting for data pipeline stack..."
aws cloudformation wait stack-create-complete \
  --stack-name ${STACK_NAME_BASE}-data-pipeline-${ENVIRONMENT} \
  --region $REGION

echo "✓ Data pipeline deployed"

# Get data pipeline outputs
STATE_MACHINE_ARN=$(aws cloudformation describe-stacks \
  --stack-name ${STACK_NAME_BASE}-data-pipeline-${ENVIRONMENT} \
  --query 'Stacks[0].Outputs[?OutputKey==`DataPipelineStateMachineArn`].OutputValue' \
  --output text \
  --region $REGION)

echo "State Machine ARN: $STATE_MACHINE_ARN"

# Step 5: Deploy Lambda Functions
echo ""
echo "Step 5: Deploying Lambda functions..."
cd backend/lambda

zip -q -r training_handler.zip training_handler.py
zip -q -r inference_handler.zip inference_handler.py
zip -q -r model_registry_handler.zip model_registry_handler.py

aws lambda update-function-code \
  --function-name ${STACK_NAME_BASE}-training-handler-${ENVIRONMENT} \
  --zip-file fileb://training_handler.zip \
  --region $REGION > /dev/null

aws lambda update-function-code \
  --function-name ${STACK_NAME_BASE}-inference-handler-${ENVIRONMENT} \
  --zip-file fileb://inference_handler.zip \
  --region $REGION > /dev/null

aws lambda update-function-code \
  --function-name ${STACK_NAME_BASE}-model-registry-handler-${ENVIRONMENT} \
  --zip-file fileb://model_registry_handler.zip \
  --region $REGION > /dev/null

rm -f *.zip
cd ../..

echo "✓ Lambda functions deployed"

# Step 6: Upload Dataset
echo ""
echo "Step 6: Dataset Upload"
echo "----------------------"

# Find CSV files in current directory (excluding hidden files)
CSV_FILES=($(ls -t *.csv 2>/dev/null | head -5))

if [ ${#CSV_FILES[@]} -gt 0 ]; then
    echo "Found CSV file(s) in current directory:"
    for i in "${!CSV_FILES[@]}"; do
        FILE_SIZE=$(du -h "${CSV_FILES[$i]}" | cut -f1)
        echo "  $((i+1)). ${CSV_FILES[$i]} (${FILE_SIZE})"
    done
    echo ""
    
    # Default to the most recent file
    DEFAULT_FILE="${CSV_FILES[0]}"
    echo "Most recent: $DEFAULT_FILE"
    echo ""
    
    read -p "Select file number to upload [1] or 'n' to skip: " FILE_CHOICE
    
    if [ "$FILE_CHOICE" = "n" ] || [ "$FILE_CHOICE" = "N" ]; then
        echo "⚠ Dataset upload skipped"
        DATASET_FILE=""
    else
        # Default to 1 if empty
        FILE_CHOICE=${FILE_CHOICE:-1}
        
        # Validate choice
        if [ "$FILE_CHOICE" -ge 1 ] && [ "$FILE_CHOICE" -le ${#CSV_FILES[@]} ]; then
            DATASET_FILE="${CSV_FILES[$((FILE_CHOICE-1))]}"
            echo "Selected: $DATASET_FILE"
            echo "Uploading dataset to S3..."
            
            aws s3 cp "$DATASET_FILE" "s3://${DATA_BUCKET}/datasets/$DATASET_FILE" --region $REGION
            
            if [ $? -eq 0 ]; then
                echo "✓ Dataset uploaded to s3://${DATA_BUCKET}/datasets/$DATASET_FILE"
                UPLOADED_DATASET="s3://${DATA_BUCKET}/datasets/$DATASET_FILE"
            else
                echo "✗ Upload failed"
                DATASET_FILE=""
            fi
        else
            echo "Invalid selection. Skipping upload."
            DATASET_FILE=""
        fi
    fi
    
    if [ -z "$DATASET_FILE" ]; then
        echo ""
        echo "To upload later, run:"
        echo "  aws s3 cp your_dataset.csv s3://${DATA_BUCKET}/datasets/"
    fi
else
    echo "⚠ No CSV files found in current directory"
    echo ""
    echo "To upload your dataset later:"
    echo "  1. Place your CSV file in the project root"
    echo "  2. Run: aws s3 cp your_dataset.csv s3://${DATA_BUCKET}/datasets/"
    echo ""
    echo "Or upload via AWS Console:"
    echo "  Bucket: ${DATA_BUCKET}"
    echo "  Path: datasets/"
    DATASET_FILE=""
fi

# Step 7: Deploy Frontend with Amplify
echo ""
echo "Step 7: Deploying React frontend with AWS Amplify..."

# Check if GitHub token is provided
if [ -z "$GITHUB_TOKEN" ]; then
    echo "⚠ GITHUB_TOKEN not set. Skipping Amplify deployment."
    echo "To deploy frontend, set GITHUB_TOKEN and run:"
    echo "export GITHUB_TOKEN=<your-token>"
    echo "aws cloudformation deploy --template-file infrastructure/frontend-hosting.yaml --stack-name mlops-frontend-${ENVIRONMENT} --parameter-overrides GitHubRepo=<your-repo> GitHubToken=\$GITHUB_TOKEN ApiEndpoint=$API_ENDPOINT --capabilities CAPABILITY_NAMED_IAM"
else
    # Deploy Amplify
    aws cloudformation deploy \
      --template-file infrastructure/frontend-hosting.yaml \
      --stack-name ${STACK_NAME_BASE}-frontend-${ENVIRONMENT} \
      --parameter-overrides \
        Environment=$ENVIRONMENT \
        GitHubRepo=${GITHUB_REPO:-"your-org/mlops-platform"} \
        GitHubBranch=${GITHUB_BRANCH:-"main"} \
        GitHubToken=$GITHUB_TOKEN \
        ApiEndpoint=$API_ENDPOINT \
      --capabilities CAPABILITY_NAMED_IAM \
      --region $REGION
    
    # Get Amplify URL
    AMPLIFY_URL=$(aws cloudformation describe-stacks \
      --stack-name ${STACK_NAME_BASE}-frontend-${ENVIRONMENT} \
      --query 'Stacks[0].Outputs[?OutputKey==`AmplifyDefaultDomain`].OutputValue' \
      --output text \
      --region $REGION)
    
    echo "✓ Frontend deployed to Amplify"
    echo "Amplify URL: $AMPLIFY_URL"
fi

# Also build locally for testing
cd frontend
echo "REACT_APP_API_URL=$API_ENDPOINT" > .env
npm install --silent
npm run build
cd ..
echo "✓ Frontend also built locally (frontend/build/)"

# Step 8: Create Summary Document
echo ""
echo "Step 8: Creating deployment summary..."

cat > DEPLOYMENT_INFO.txt << EOF
========================================
MLOps Platform Deployment Summary
========================================
Deployment Date: $(date)
Environment: $ENVIRONMENT
Region: $REGION

INFRASTRUCTURE
--------------
Main Stack: ${STACK_NAME_BASE}-${ENVIRONMENT}
CI/CD Stack: ${STACK_NAME_BASE}-cicd-${ENVIRONMENT}
Data Pipeline Stack: ${STACK_NAME_BASE}-data-pipeline-${ENVIRONMENT}

ENDPOINTS
---------
API Gateway: $API_ENDPOINT
CodeCommit Repository: $REPO_URL

STORAGE
-------
Data Bucket: $DATA_BUCKET
Model Bucket: $MODEL_BUCKET

PIPELINES
---------
CI/CD Pipeline: $PIPELINE_NAME
Data Pipeline State Machine: $STATE_MACHINE_ARN

FRONTEND
--------
Amplify URL: ${AMPLIFY_URL:-"Not deployed (set GITHUB_TOKEN to deploy)"}
Local Build: frontend/build/index.html

GITHUB INTEGRATION
------------------
CI/CD Pipeline: ${PIPELINE_NAME}
Repository: ${REPO_URL}
Status: $([ -n "$GITHUB_TOKEN" ] && echo "Deployed" || echo "Not deployed - GitHub token not provided")

DATASET UPLOAD
--------------
Data Bucket: s3://${DATA_BUCKET}
Upload Location: s3://${DATA_BUCKET}/datasets/
Uploaded Dataset: ${UPLOADED_DATASET:-"None - upload manually"}

To upload dataset:
  aws s3 cp your_dataset.csv s3://${DATA_BUCKET}/datasets/

NEXT STEPS
----------
1. Upload Dataset (if not done):
   - aws s3 cp diabetic_data.csv s3://${DATA_BUCKET}/datasets/
   - See docs/DATASET_UPLOAD_GUIDE.md for details

2. Access UI: 
   - Amplify: ${AMPLIFY_URL:-"Not deployed - requires GitHub token"}
   - Local: open frontend/build/index.html

3. Test API: 
   - curl $API_ENDPOINT/models

4. Start Training Job:
   - Via UI: Training Pipeline → Start New Job
   - Via API: POST $API_ENDPOINT/training/start

5. Setup CI/CD (if skipped):
   - Set: export GITHUB_TOKEN=your_token
   - Set: export GITHUB_REPO=owner/repo
   - Redeploy CI/CD stack

6. Monitor:
   - CloudWatch Logs: /aws/lambda/mlops-platform-*
   - CloudWatch Metrics: Custom/MLOps namespace

DOCUMENTATION
-------------
- docs/DATASET_UPLOAD_GUIDE.md - When and how to upload datasets
- docs/IAM_SETUP_GUIDE.md - IAM permissions setup
- docs/AWS_WELL_ARCHITECTED.md - Framework compliance
- docs/DEPLOYMENT.md - Detailed deployment guide
- docs/QUICKSTART.md - Quick start guide

========================================
EOF

echo "✓ Deployment summary created"

# Final Summary
echo ""
echo "========================================="
echo "🎉 Deployment Complete!"
echo "========================================="
echo ""
echo "✅ Main Infrastructure (Lambda, API Gateway, S3, DynamoDB)"
if [ -n "$GITHUB_TOKEN" ]; then
    echo "✅ CI/CD Pipeline (GitHub Integration)"
else
    echo "⚠️  CI/CD Pipeline (Skipped - no GitHub token)"
fi
echo "✅ Data Pipeline (Glue, Step Functions, EventBridge)"
echo "✅ Lambda Functions Deployed"
echo "✅ Frontend Built Locally"
echo ""
echo "📍 Key Resources:"
echo "   API Endpoint: $API_ENDPOINT"
echo "   Data Bucket: $DATA_BUCKET"
echo "   Model Bucket: $MODEL_BUCKET"
echo ""
if [ -n "$GITHUB_TOKEN" ]; then
    echo "🔗 GitHub Integration:"
    echo "   Repository: $REPO_URL"
    echo "   Pipeline: $PIPELINE_NAME"
    echo ""
fi
echo "📄 Full details saved to: DEPLOYMENT_INFO.txt"
echo ""
echo "🚀 Quick Start:"
echo ""
if [ -n "$UPLOADED_DATASET" ]; then
    echo "1. ✅ Dataset Uploaded:"
    echo "   $UPLOADED_DATASET"
    echo ""
else
    echo "1. Upload Dataset (Required for training):"
    echo "   aws s3 cp your_dataset.csv s3://${DATA_BUCKET}/datasets/"
    echo "   📖 See: docs/DATASET_UPLOAD_GUIDE.md"
    echo ""
fi
echo "2. Access the UI:"
echo "   open frontend/build/index.html"
echo ""
echo "3. Test the API:"
echo "   curl $API_ENDPOINT/models"
echo ""
echo "4. Start a Training Job:"
echo "   - Via UI: Training Pipeline → Start New Job"
echo "   - Via API: POST $API_ENDPOINT/training/start"
echo ""
if [ -z "$GITHUB_TOKEN" ]; then
    echo "💡 To enable CI/CD later:"
    echo "   export GITHUB_TOKEN=your_token"
    echo "   export GITHUB_REPO=owner/repo"
    echo "   Then redeploy the CI/CD stack"
    echo ""
fi
echo "📚 Documentation:"
echo "   - docs/DATASET_UPLOAD_GUIDE.md - Dataset management"
echo "   - docs/IAM_SETUP_GUIDE.md - Permissions"
echo "   - docs/QUICKSTART.md - Getting started"
echo ""
echo "========================================="
