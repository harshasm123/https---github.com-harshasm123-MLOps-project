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
if [ -f "diabetic_data.csv" ]; then
    echo "Found diabetic_data.csv in current directory"
    read -p "Upload dataset now? (y/n) [y]: " UPLOAD_DATASET
    UPLOAD_DATASET=${UPLOAD_DATASET:-y}
    
    if [ "$UPLOAD_DATASET" = "y" ] || [ "$UPLOAD_DATASET" = "Y" ]; then
        echo "Uploading dataset to S3..."
        aws s3 cp diabetic_data.csv s3://${DATA_BUCKET}/datasets/diabetic_data.csv --region $REGION
        echo "✓ Dataset uploaded to s3://${DATA_BUCKET}/datasets/diabetic_data.csv"
    else
        echo "⚠ Dataset upload skipped"
        echo "  To upload later, run:"
        echo "  aws s3 cp diabetic_data.csv s3://${DATA_BUCKET}/datasets/diabetic_data.csv"
    fi
else
    echo "⚠ diabetic_data.csv not found in current directory"
    echo ""
    echo "To upload your dataset later:"
    echo "  1. Place your CSV file in the project root"
    echo "  2. Run: aws s3 cp your_dataset.csv s3://${DATA_BUCKET}/datasets/"
    echo ""
    echo "Or upload via AWS Console:"
    echo "  Bucket: ${DATA_BUCKET}"
    echo "  Path: datasets/"
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

NEXT STEPS
----------
1. Access UI: 
   - Amplify: ${AMPLIFY_URL:-"Set GITHUB_TOKEN and redeploy"}
   - Local: open frontend/build/index.html
2. Test API: curl $API_ENDPOINT/models
3. Push code to GitHub to trigger CI/CD
4. Upload data to s3://${DATA_BUCKET}/raw-data/ to trigger data pipeline
5. Monitor in CloudWatch and Amplify Console

DOCUMENTATION
-------------
- AWS_WELL_ARCHITECTED.md - Framework compliance
- DEPLOYMENT.md - Detailed deployment guide
- QUICKSTART.md - Quick start guide

========================================
EOF

echo "✓ Deployment summary created"

# Final Summary
echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="
echo ""
echo "✅ Main Infrastructure (Lambda, API Gateway, S3, DynamoDB)"
echo "✅ CI/CD Pipeline (CodePipeline, CodeBuild, CodeCommit)"
echo "✅ Data Pipeline (Glue, Step Functions, EventBridge)"
echo "✅ Lambda Functions Deployed"
echo "✅ Frontend Built"
echo ""
echo "API Endpoint: $API_ENDPOINT"
echo "Data Bucket: $DATA_BUCKET"
echo "Model Bucket: $MODEL_BUCKET"
echo ""
echo "Repository: $REPO_URL"
echo "Pipeline: $PIPELINE_NAME"
echo ""
echo "📄 Full details saved to: DEPLOYMENT_INFO.txt"
echo ""
echo "Next Steps:"
echo "1. Test API: curl $API_ENDPOINT/models"
echo "2. Access UI: open frontend/build/index.html"
echo "3. View pipelines in AWS Console"
echo "4. Check AWS_WELL_ARCHITECTED.md for compliance details"
echo ""
echo "========================================="
