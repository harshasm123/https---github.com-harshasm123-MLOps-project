# MLOps Platform - Deployment Quick Reference

## 🚀 Deployment Steps

### 1. Setup IAM Permissions
```bash
./setup-iam-quick.sh
# Or for PowerShell on Windows:
# .\setup-iam-quick.ps1
```

### 2. Verify Prerequisites
```bash
./prereq.sh
```

### 3. Deploy Platform
```bash
./deploy-complete.sh
```

**During deployment, you'll be prompted for:**
- **GitHub Repository** (optional): `owner/repo` format
- **GitHub Branch** (optional): Default is `main`
- **GitHub Token** (optional): Personal access token for CI/CD
- **Dataset Upload** (optional): Upload `diabetic_data.csv` if present

## 📦 What Gets Deployed

| Component | Description | Status |
|-----------|-------------|--------|
| **Main Infrastructure** | Lambda, API Gateway, S3, DynamoDB | ✅ Always |
| **CI/CD Pipeline** | GitHub integration, automated builds | ⚠️ Optional (needs GitHub token) |
| **Data Pipeline** | Glue ETL, Step Functions | ✅ Always |
| **Lambda Functions** | Training, Inference, Registry handlers | ✅ Always |
| **Frontend** | React app (local build) | ✅ Always |
| **Amplify Hosting** | Cloud-hosted frontend | ⚠️ Optional (needs GitHub token) |

## 📊 Dataset Upload

### When to Upload

| Timing | Method | Purpose |
|--------|--------|---------|
| **During Deployment** | Interactive prompt | Immediate availability for training |
| **After Deployment** | AWS CLI or Console | Upload additional datasets |
| **Before Training** | Any method | Required for starting training jobs |

### How to Upload

```bash
# Get your bucket name from DEPLOYMENT_INFO.txt
DATA_BUCKET="mlops-platform-data-dev-YOUR_ACCOUNT_ID"

# Upload training dataset
aws s3 cp diabetic_data.csv s3://${DATA_BUCKET}/datasets/

# Upload for batch inference
aws s3 cp patients.csv s3://${DATA_BUCKET}/inference-input/

# Upload raw data (triggers ETL pipeline)
aws s3 cp raw_data.csv s3://${DATA_BUCKET}/raw-data/
```

### Dataset Locations

```
s3://mlops-platform-data-dev-{ACCOUNT_ID}/
├── datasets/          ← Upload training data here
├── raw-data/          ← Upload to trigger ETL pipeline
├── processed-data/    ← ETL output (auto-generated)
├── inference-input/   ← Upload for batch predictions
├── inference-output/  ← Prediction results (auto-generated)
└── glue-scripts/      ← ETL scripts (auto-uploaded)
```

## 🔗 GitHub Integration (Optional)

### Why Use GitHub Integration?

- **Automated CI/CD**: Code changes trigger automatic builds and deployments
- **Frontend Hosting**: Amplify hosts your React app with custom domain
- **Version Control**: Track all infrastructure and code changes
- **Collaboration**: Team members can contribute via pull requests

### Setup GitHub Integration

#### Option 1: During Deployment
When prompted, provide:
```
Enter GitHub repository: your-username/mlops-platform
Enter GitHub branch: main
Enter GitHub Personal Access Token: ghp_xxxxxxxxxxxxx
```

#### Option 2: After Deployment
```bash
# Set environment variables
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxx"
export GITHUB_REPO="your-username/mlops-platform"
export GITHUB_BRANCH="main"

# Deploy CI/CD stack
aws cloudformation create-stack \
  --stack-name mlops-platform-cicd-dev \
  --template-body file://infrastructure/cicd-pipeline.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=dev \
    ParameterKey=GitHubToken,ParameterValue=$GITHUB_TOKEN \
    ParameterKey=GitHubRepo,ParameterValue=$GITHUB_REPO \
    ParameterKey=GitHubBranch,ParameterValue=$GITHUB_BRANCH \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

### Creating a GitHub Personal Access Token

1. Go to GitHub → Settings → Developer settings → Personal access tokens
2. Click "Generate new token (classic)"
3. Select scopes:
   - `repo` (Full control of private repositories)
   - `admin:repo_hook` (Full control of repository hooks)
4. Generate and copy the token
5. **Save it securely** - you won't see it again!

### What Happens Without GitHub?

- ✅ Platform still works fully
- ✅ Can deploy manually
- ✅ Frontend builds locally
- ❌ No automated CI/CD
- ❌ No Amplify hosting
- ❌ Manual deployments required

## 🎯 Post-Deployment Checklist

### Immediate Actions
- [ ] Verify deployment: Check `DEPLOYMENT_INFO.txt`
- [ ] Upload dataset: `aws s3 cp diabetic_data.csv s3://${DATA_BUCKET}/datasets/`
- [ ] Test API: `curl $API_ENDPOINT/models`
- [ ] Open UI: `open frontend/build/index.html`

### First Training Job
- [ ] Navigate to Training Pipeline in UI
- [ ] Click "Start New Job"
- [ ] Select dataset: `s3://${DATA_BUCKET}/datasets/diabetic_data.csv`
- [ ] Choose algorithm: RandomForest or XGBoost
- [ ] Monitor in CloudWatch

### Optional Setup
- [ ] Setup GitHub integration (if skipped)
- [ ] Configure custom domain for Amplify
- [ ] Setup CloudWatch alarms
- [ ] Configure SNS notifications
- [ ] Add team members to IAM

## 🔍 Verification Commands

```bash
# Check CloudFormation stacks
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE

# List Lambda functions
aws lambda list-functions --query 'Functions[?contains(FunctionName, `mlops-platform`)].FunctionName'

# Check S3 buckets
aws s3 ls | grep mlops-platform

# Test API endpoint
curl https://YOUR_API_ENDPOINT/models

# Check dataset upload
aws s3 ls s3://mlops-platform-data-dev-YOUR_ACCOUNT_ID/datasets/

# View CloudWatch logs
aws logs tail /aws/lambda/mlops-platform-training-handler-dev --follow
```

## 🆘 Troubleshooting

### Deployment Fails

| Error | Solution |
|-------|----------|
| `CloudFormation not accessible` | Run `./setup-iam-quick.sh` |
| `Parameters: [DatasetBucketName] must have values` | Fixed in latest version |
| `Parameters: [GitHubToken] must have values` | Provide token or skip CI/CD |
| `Bucket already exists` | Use unique bucket name or delete existing |

### Dataset Upload Fails

| Error | Solution |
|-------|----------|
| `Access Denied` | Check IAM permissions for S3 |
| `No such bucket` | Verify bucket name from `DEPLOYMENT_INFO.txt` |
| `File not found` | Check file path and name |

### Training Job Fails

| Error | Solution |
|-------|----------|
| `Dataset not found` | Verify S3 path is correct |
| `Insufficient permissions` | Check SageMaker execution role |
| `Instance type not available` | Try different instance type |

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| `DEPLOYMENT_INFO.txt` | Your deployment details |
| `docs/DATASET_UPLOAD_GUIDE.md` | Dataset management |
| `docs/IAM_SETUP_GUIDE.md` | Permissions setup |
| `docs/DEPLOYMENT.md` | Detailed deployment guide |
| `docs/QUICKSTART.md` | Getting started |
| `docs/AWS_WELL_ARCHITECTED.md` | Architecture details |

## 🔗 Useful Links

- **AWS Console**: https://console.aws.amazon.com/
- **S3 Console**: https://console.aws.amazon.com/s3/
- **Lambda Console**: https://console.aws.amazon.com/lambda/
- **CloudWatch Console**: https://console.aws.amazon.com/cloudwatch/
- **SageMaker Console**: https://console.aws.amazon.com/sagemaker/
- **API Gateway Console**: https://console.aws.amazon.com/apigateway/

## 💡 Pro Tips

1. **Save your deployment info**: Keep `DEPLOYMENT_INFO.txt` in a safe place
2. **Use environment variables**: Export commonly used values
   ```bash
   export DATA_BUCKET="mlops-platform-data-dev-YOUR_ACCOUNT_ID"
   export API_ENDPOINT="https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod"
   ```
3. **Tag your resources**: Use AWS tags for cost tracking and organization
4. **Monitor costs**: Check AWS Cost Explorer regularly
5. **Backup important data**: S3 versioning is enabled, but export critical datasets
6. **Test in dev first**: Always test changes in dev environment before prod

## 🎓 Next Steps

1. **Complete the tutorial**: Follow `docs/QUICKSTART.md`
2. **Train your first model**: Use the UI or API
3. **Run batch inference**: Upload patient data and get predictions
4. **Setup monitoring**: Configure CloudWatch dashboards
5. **Customize the platform**: Modify Lambda functions and frontend
6. **Deploy to production**: Create prod environment with separate stacks

---

**Need Help?** Check the documentation in the `docs/` folder or review CloudWatch logs for detailed error messages.
