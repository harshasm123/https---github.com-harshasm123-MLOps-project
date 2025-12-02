#!/bin/bash

# Upload dataset and create S3 folder structure

set -euo pipefail

REGION="us-east-1"
ENVIRONMENT="dev"
STACK_NAME_BASE="mlops-platform"

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Get bucket names from CloudFormation
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

echo "=========================================="
echo "MLOps Platform - Dataset Upload"
echo "=========================================="
echo "Data Bucket: $DATA_BUCKET"
echo "Model Bucket: $MODEL_BUCKET"
echo ""

# Create folder structure in S3
echo "Creating S3 folder structure..."

# Data bucket folders
aws s3api put-object --bucket $DATA_BUCKET --key "datasets/" --region $REGION
aws s3api put-object --bucket $DATA_BUCKET --key "glue-scripts/" --region $REGION
aws s3api put-object --bucket $DATA_BUCKET --key "inference-results/" --region $REGION
aws s3api put-object --bucket $DATA_BUCKET --key "validation-reports/" --region $REGION

# Model bucket folders
aws s3api put-object --bucket $MODEL_BUCKET --key "models/" --region $REGION
aws s3api put-object --bucket $MODEL_BUCKET --key "endpoints/" --region $REGION

echo "✓ S3 folder structure created"
echo ""

# Find and upload CSV files
echo "Looking for CSV files to upload..."
CSV_FILES=($(ls -t *.csv 2>/dev/null | head -5 || true))

if [ ${#CSV_FILES[@]} -gt 0 ]; then
    echo "Found CSV file(s):"
    for i in "${!CSV_FILES[@]}"; do
        FILE_SIZE=$(du -h "${CSV_FILES[$i]}" 2>/dev/null | cut -f1)
        echo "  $((i+1)). ${CSV_FILES[$i]} (${FILE_SIZE})"
    done
    echo ""
    
    read -p "Select file number [1] or 'n' to skip: " FILE_CHOICE || true
    
    if [ "$FILE_CHOICE" != "n" ] && [ "$FILE_CHOICE" != "N" ]; then
        FILE_CHOICE=${FILE_CHOICE:-1}
        
        if [ "$FILE_CHOICE" -ge 1 ] && [ "$FILE_CHOICE" -le ${#CSV_FILES[@]} ]; then
            DATASET_FILE="${CSV_FILES[$((FILE_CHOICE-1))]}"
            echo "Uploading $DATASET_FILE..."
            
            aws s3 cp "$DATASET_FILE" "s3://${DATA_BUCKET}/datasets/$DATASET_FILE" --region $REGION
            
            echo "✓ Dataset uploaded to s3://${DATA_BUCKET}/datasets/$DATASET_FILE"
        fi
    else
        echo "⚠ Dataset upload skipped"
    fi
else
    echo "⚠ No CSV files found in current directory"
    echo "Usage: Place CSV files in current directory and run this script"
fi

echo ""
echo "=========================================="
echo "✓ Upload Complete!"
echo "=========================================="
echo ""
echo "S3 Structure:"
echo "  $DATA_BUCKET/"
echo "    ├── datasets/          (training data)"
echo "    ├── glue-scripts/      (ETL scripts)"
echo "    ├── inference-results/ (predictions)"
echo "    └── validation-reports/ (data quality)"
echo ""
echo "  $MODEL_BUCKET/"
echo "    ├── models/            (trained models)"
echo "    └── endpoints/         (deployed endpoints)"
echo ""
echo "=========================================="