# Dataset Upload Guide

This guide explains when and how to upload datasets to your MLOps platform.

## When to Upload Datasets

### During Initial Deployment

The deployment script (`deploy-complete.sh`) will prompt you to upload the dataset if `diabetic_data.csv` is found in the project root directory. You can choose to:

- **Upload now (recommended)**: Dataset will be immediately available for training
- **Upload later**: You can upload manually after deployment completes

### After Deployment

You can upload datasets at any time after the platform is deployed:

1. **Before starting training jobs**: Upload datasets you want to train models on
2. **For batch inference**: Upload new patient data for predictions
3. **For data pipeline testing**: Upload raw data to trigger automated processing

## How to Upload Datasets

### Option 1: During Deployment (Interactive)

When running `./deploy-complete.sh`, the script will automatically detect CSV files in your directory:

```
Step 6: Dataset Upload
----------------------
Found CSV file(s) in current directory:
  1. diabetic_data.csv (2.5M)
  2. patient_data_2024.csv (1.8M)
  3. training_set.csv (3.2M)

Most recent: diabetic_data.csv

Select file number to upload [1] or 'n' to skip:
```

- Enter a number (1-3) to select a specific file
- Press Enter to use the most recent file (default)
- Press `n` to skip and upload later

The script automatically:
- Lists up to 5 most recent CSV files
- Shows file sizes
- Defaults to the most recently modified file
- Preserves the original filename in S3

### Option 2: AWS CLI (After Deployment)

Upload to the datasets folder:

```bash
# Get your bucket name from deployment output
DATA_BUCKET="mlops-platform-data-dev-YOUR_ACCOUNT_ID"

# Upload dataset
aws s3 cp diabetic_data.csv s3://${DATA_BUCKET}/datasets/diabetic_data.csv

# Or upload with a custom name
aws s3 cp my_data.csv s3://${DATA_BUCKET}/datasets/my_data.csv
```

### Option 3: AWS Console

1. Go to [S3 Console](https://console.aws.amazon.com/s3/)
2. Find your data bucket: `mlops-platform-data-dev-{ACCOUNT_ID}`
3. Navigate to the `datasets/` folder (create if it doesn't exist)
4. Click "Upload" and select your CSV file
5. Click "Upload" to complete

### Option 4: Programmatically (Python)

```python
import boto3

s3 = boto3.client('s3')
bucket_name = 'mlops-platform-data-dev-YOUR_ACCOUNT_ID'

# Upload file
s3.upload_file(
    'diabetic_data.csv',
    bucket_name,
    'datasets/diabetic_data.csv'
)

print(f"Dataset uploaded to s3://{bucket_name}/datasets/diabetic_data.csv")
```

## Dataset Locations and Purposes

Your S3 data bucket has different folders for different purposes:

```
s3://mlops-platform-data-dev-{ACCOUNT_ID}/
├── datasets/              # Training datasets (upload here)
│   └── diabetic_data.csv
├── raw-data/             # Raw data for ETL pipeline
│   └── incoming_data.csv
├── processed-data/       # Output from Glue ETL jobs
│   └── cleaned_data.csv
├── inference-input/      # Data for batch predictions
│   └── patients_to_predict.csv
├── inference-output/     # Prediction results
│   └── predictions.csv
└── glue-scripts/         # ETL scripts (auto-uploaded)
    ├── data_validation.py
    └── data_preprocessing.py
```

### Folder Purposes

- **datasets/**: Upload training datasets here. Used by SageMaker training jobs
- **raw-data/**: Upload raw data here to trigger the automated data pipeline
- **processed-data/**: Cleaned data output from Glue jobs (auto-generated)
- **inference-input/**: Upload patient data for batch predictions
- **inference-output/**: Prediction results are saved here (auto-generated)
- **glue-scripts/**: ETL scripts (auto-uploaded during deployment)

## Dataset Format Requirements

### Training Dataset (diabetic_data.csv)

Your training dataset should be a CSV file with:

- **Headers**: First row should contain column names
- **Target column**: Column indicating medication adherence (e.g., `adherence`, `non_adherence`)
- **Feature columns**: Patient demographics, medical history, medication details, etc.

Example structure:
```csv
patient_id,age,gender,diagnosis,medication,adherence
P001,45,M,Type2Diabetes,Metformin,1
P002,62,F,Type2Diabetes,Insulin,0
...
```

### Inference Dataset

For batch predictions, use the same format but without the target column:

```csv
patient_id,age,gender,diagnosis,medication
P100,50,M,Type2Diabetes,Metformin
P101,58,F,Type2Diabetes,Insulin
...
```

## Verifying Upload

### Check via AWS CLI

```bash
# List files in datasets folder
aws s3 ls s3://mlops-platform-data-dev-YOUR_ACCOUNT_ID/datasets/

# Check file size and metadata
aws s3 ls s3://mlops-platform-data-dev-YOUR_ACCOUNT_ID/datasets/ --human-readable

# Download to verify
aws s3 cp s3://mlops-platform-data-dev-YOUR_ACCOUNT_ID/datasets/diabetic_data.csv ./verify.csv
```

### Check via AWS Console

1. Go to S3 Console
2. Navigate to your bucket → datasets/
3. Verify the file appears with correct size and timestamp

### Check via Python

```python
import boto3

s3 = boto3.client('s3')
bucket = 'mlops-platform-data-dev-YOUR_ACCOUNT_ID'

# List objects
response = s3.list_objects_v2(Bucket=bucket, Prefix='datasets/')

for obj in response.get('Contents', []):
    print(f"File: {obj['Key']}, Size: {obj['Size']} bytes")
```

## Triggering Workflows After Upload

### Training Pipeline

After uploading to `datasets/`, start a training job:

1. **Via UI**: Go to Training Pipeline → Start New Job → Select dataset
2. **Via API**:
   ```bash
   curl -X POST https://YOUR_API_ENDPOINT/training/start \
     -H "Content-Type: application/json" \
     -d '{
       "datasetUri": "s3://mlops-platform-data-dev-YOUR_ACCOUNT_ID/datasets/diabetic_data.csv",
       "modelName": "medication-adherence-model",
       "algorithm": "RandomForest"
     }'
   ```

### Data Pipeline (Automated)

Uploading to `raw-data/` automatically triggers the ETL pipeline via EventBridge:

```bash
# Upload raw data
aws s3 cp incoming_data.csv s3://mlops-platform-data-dev-YOUR_ACCOUNT_ID/raw-data/

# Pipeline automatically:
# 1. Validates data quality
# 2. Cleans and transforms data
# 3. Saves to processed-data/
# 4. Sends notifications
```

### Batch Inference

Upload patient data for predictions:

```bash
# Upload inference input
aws s3 cp patients.csv s3://mlops-platform-data-dev-YOUR_ACCOUNT_ID/inference-input/

# Start batch inference via API
curl -X POST https://YOUR_API_ENDPOINT/inference/batch \
  -H "Content-Type: application/json" \
  -d '{
    "inputUri": "s3://mlops-platform-data-dev-YOUR_ACCOUNT_ID/inference-input/patients.csv",
    "outputUri": "s3://mlops-platform-data-dev-YOUR_ACCOUNT_ID/inference-output/predictions.csv"
  }'
```

## Best Practices

1. **Use descriptive names**: Include date/version in filename (e.g., `diabetic_data_2024_01.csv`)
2. **Validate before upload**: Check CSV format, headers, and data types
3. **Use versioning**: S3 versioning is enabled, so you can recover previous versions
4. **Monitor size**: Large files (>1GB) may take time to upload
5. **Compress if needed**: For very large datasets, consider gzip compression
6. **Tag datasets**: Use S3 tags to organize datasets by project, date, or purpose

## Troubleshooting

### Upload Fails

**Issue**: Permission denied
```
An error occurred (AccessDenied) when calling the PutObject operation
```

**Solution**: Verify IAM permissions include `s3:PutObject` for the bucket

### File Not Found After Upload

**Issue**: File uploaded but not visible in training job

**Solution**: 
- Check the exact S3 path used
- Verify bucket name and folder structure
- Wait a few seconds for S3 consistency

### Large File Upload Timeout

**Issue**: Upload times out for large files

**Solution**: Use multipart upload or AWS CLI with increased timeout:
```bash
aws configure set default.s3.max_concurrent_requests 20
aws configure set default.s3.multipart_threshold 64MB
aws s3 cp large_file.csv s3://bucket/datasets/ --no-progress
```

## Security Considerations

- **Encryption**: All data is encrypted at rest (S3 default encryption)
- **Access Control**: Only authorized IAM users/roles can access
- **Versioning**: Enabled to prevent accidental deletion
- **Audit**: CloudTrail logs all S3 access
- **PII**: Ensure patient data is de-identified before upload

## Next Steps

After uploading your dataset:

1. Verify upload was successful
2. Start a training job via UI or API
3. Monitor training progress in CloudWatch
4. Review model metrics in the Model Registry
5. Deploy approved models for inference

## Support

For issues with dataset upload:
- Check CloudWatch logs for detailed errors
- Review S3 bucket policies and IAM permissions
- Consult AWS S3 documentation for advanced features
