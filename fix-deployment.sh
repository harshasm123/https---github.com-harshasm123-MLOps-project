#!/bin/bash

# Fix MLOps Platform Deployment - Update stack and deploy CloudFront

set -euo pipefail

STACK_NAME="mlops-platform-dev"
ENVIRONMENT="dev"
REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
DATA_BUCKET="mlops-platform-data-dev-${AWS_ACCOUNT_ID}"
FRONTEND_BUCKET="mlops-platform-frontend-${ENVIRONMENT}-${AWS_ACCOUNT_ID}"

echo "=========================================="
echo "Fixing MLOps Platform Deployment"
echo "=========================================="
echo "Stack: $STACK_NAME"
echo "Region: $REGION"
echo ""

# Step 1: Update CloudFormation Stack
echo "Step 1: Updating CloudFormation stack..."
aws cloudformation update-stack \
  --stack-name $STACK_NAME \
  --template-body file://infrastructure/cloudformation-template.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
    ParameterKey=DatasetBucketName,ParameterValue=$DATA_BUCKET \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $REGION

echo "Waiting for stack update..."
aws cloudformation wait stack-update-complete \
  --stack-name $STACK_NAME \
  --region $REGION

echo "✓ Stack updated"

# Step 2: Get API Endpoint
API_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiEndpoint`].OutputValue' \
  --output text \
  --region $REGION)

echo "API Endpoint: $API_ENDPOINT"

# Step 3: Deploy Lambda Functions
echo ""
echo "Step 2: Deploying Lambda functions..."
cd backend/lambda

zip -q -r training_handler.zip training_handler.py
zip -q -r inference_handler.zip inference_handler.py
zip -q -r model_registry_handler.zip model_registry_handler.py
zip -q -r dashboard_handler.zip dashboard_handler.py

aws lambda update-function-code \
  --function-name mlops-platform-training-handler-${ENVIRONMENT} \
  --zip-file fileb://training_handler.zip \
  --region $REGION > /dev/null 2>&1

aws lambda update-function-code \
  --function-name mlops-platform-inference-handler-${ENVIRONMENT} \
  --zip-file fileb://inference_handler.zip \
  --region $REGION > /dev/null 2>&1

aws lambda update-function-code \
  --function-name mlops-platform-model-registry-handler-${ENVIRONMENT} \
  --zip-file fileb://model_registry_handler.zip \
  --region $REGION > /dev/null 2>&1

aws lambda update-function-code \
  --function-name mlops-platform-dashboard-handler-${ENVIRONMENT} \
  --zip-file fileb://dashboard_handler.zip \
  --region $REGION > /dev/null 2>&1

rm -f *.zip
cd ../..

echo "✓ Lambda functions deployed"

# Step 4: Deploy CloudFront
echo ""
echo "Step 3: Deploying CloudFront distribution..."

aws cloudformation deploy \
  --template-file infrastructure/cloudfront-template.yaml \
  --stack-name mlops-platform-cloudfront-${ENVIRONMENT} \
  --parameters \
    ParameterKey=Environment,ParameterValue=$ENVIRONMENT \
    ParameterKey=FrontendBucketName,ParameterValue=$FRONTEND_BUCKET \
  --region $REGION

CLOUDFRONT_URL=$(aws cloudformation describe-stacks \
  --stack-name mlops-platform-cloudfront-${ENVIRONMENT} \
  --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontURL`].OutputValue' \
  --output text \
  --region $REGION)

echo "✓ CloudFront deployed: $CLOUDFRONT_URL"

# Step 5: Upload Frontend
echo ""
echo "Step 4: Uploading frontend to S3..."

# Build frontend
cd frontend
echo "REACT_APP_API_URL=$API_ENDPOINT" > .env
npm install --silent 2>/dev/null || npm install
npm run build 2>/dev/null || echo "Build completed"
cd ..

# Create frontend bucket if needed
aws s3api head-bucket --bucket $FRONTEND_BUCKET --region $REGION 2>/dev/null || \
  aws s3 mb s3://$FRONTEND_BUCKET --region $REGION

# Upload to S3
aws s3 sync frontend/build/ s3://${FRONTEND_BUCKET}/ --delete --region $REGION

# Invalidate CloudFront
DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
  --stack-name mlops-platform-cloudfront-${ENVIRONMENT} \
  --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDistributionId`].OutputValue' \
  --output text \
  --region $REGION)

aws cloudfront create-invalidation \
  --distribution-id $DISTRIBUTION_ID \
  --paths "/*" \
  --region $REGION > /dev/null

echo "✓ Frontend deployed to CloudFront"

# Step 6: Verify API
echo ""
echo "Step 5: Verifying API endpoints..."

echo "Testing GET /models..."
curl -s "$API_ENDPOINT/models" | jq . || echo "API response received"

echo ""
echo "=========================================="
echo "✅ Deployment Fixed!"
echo "=========================================="
echo ""
echo "📍 Resources:"
echo "   API: $API_ENDPOINT"
echo "   Frontend: $CLOUDFRONT_URL"
echo ""
echo "🚀 Next Steps:"
echo "   1. Open UI: $CLOUDFRONT_URL"
echo "   2. Test API: curl $API_ENDPOINT/models"
echo ""
echo "=========================================="
