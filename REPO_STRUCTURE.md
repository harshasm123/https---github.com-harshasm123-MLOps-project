# Repository Structure

This document describes the organization of the MLOps Platform repository.

## Root Directory

### Deployment Scripts
- **deploy-complete.sh** - Full platform deployment (infrastructure + CI/CD + data pipeline)
- **deploy.sh** - Infrastructure-only deployment (simpler, no CI/CD)
- **deploy.sh** - Unified deployment script (use `--full` flag for complete deployment)
- **setup-iam.sh** - IAM permissions setup (use `--quick` flag for fast setup)
- **prereq.sh** - Prerequisites checker (verifies AWS CLI, Python, Node.js, etc.)
- **ec2-setup.sh** - EC2-specific setup script

### Configuration Files
- **requirements.txt** - Python dependencies
- **pytest.ini** - Python test configuration
- **.gitignore** - Git ignore rules

### Data Files
- **diabetic_data.csv** - Original sample training dataset
- **medication_adherence_sample.csv** - New sample dataset (50 patients)
- **DEMO20Q4.txt**, **INDI20Q4.txt**, **OUTC20Q4.txt** - Additional data files
- **DEMO20Q4.txt** - Demo data file
- **INDI20Q4.txt** - Indicator data file
- **OUTC20Q4.txt** - Outcome data file

### Documentation
- **README.md** - Main project documentation
- **REPO_STRUCTURE.md** - This file - repository organization guide
- **REPOSITORY_CLEANUP_FINAL.md** - Cleanup summary and migration guide
- **DEPLOYMENT_QUICK_REFERENCE.md** - Quick deployment commands reference

## Directory Structure

```
.
├── backend/                    # Backend Lambda functions
│   └── lambda/
│       ├── training_handler.py
│       ├── inference_handler.py
│       ├── model_registry_handler.py
│       ├── patient_handler.py
│       ├── medication_handler.py
│       ├── dashboard_handler.py
│       ├── genai_handler.py
│       └── prediction_workflow_handler.py
│
├── config/                     # Configuration modules
│   ├── aws_config.py
│   └── __init__.py
│
├── docs/                       # Documentation
│   ├── QUICKSTART.md          # Getting started guide
│   ├── DEPLOYMENT.md          # Comprehensive deployment guide
│   ├── IAM_SETUP_GUIDE.md     # IAM permissions setup
│   ├── DATASET_UPLOAD_GUIDE.md # Dataset management
│   ├── AWS_WELL_ARCHITECTED.md # Architecture documentation
│   ├── GITOPS_GUIDE.md        # CI/CD with GitHub
│   ├── GITOPS_VS_CODECOMMIT.md # Comparison guide
│   ├── EC2_SETUP_GUIDE.md     # EC2 deployment
│   ├── SAGEMAKER_EXECUTION_GUIDE.md # ML operations
│   ├── BACKEND_ENHANCEMENTS.md # Backend details
│   ├── PROJECT_SUMMARY.md     # Project overview
│   ├── QUICK_REFERENCE.md     # Command reference
│   ├── AMPLIFY_DEPLOYMENT_GUIDE.md # Frontend hosting
│   └── SETUP_SCRIPTS.md       # Script documentation
│
├── frontend/                   # React frontend application
│   ├── public/
│   ├── src/
│   │   ├── components/        # React components
│   │   ├── App.js
│   │   └── index.js
│   ├── package.json
│   └── .env.example
│
├── glue-scripts/              # AWS Glue ETL scripts
│   ├── data_validation.py
│   └── data_preprocessing.py
│
├── infrastructure/            # CloudFormation templates
│   ├── cloudformation-template.yaml  # Main infrastructure
│   ├── cicd-pipeline.yaml           # CI/CD pipeline
│   ├── data-pipeline.yaml           # Data processing pipeline
│   ├── frontend-hosting.yaml        # Amplify hosting
│   ├── gitops-config.yaml           # GitOps configuration
│   └── deployment-iam-policy.json   # IAM policy document
│
├── src/                       # Python source code
│   ├── models/                # Data models
│   │   └── ui_data_models.py
│   ├── pipelines/             # ML pipelines
│   └── monitoring/            # Monitoring and drift detection
│
├── templates/                 # Additional templates
│
├── tests/                     # Test files
│
└── .kiro/                     # Kiro IDE specifications
    └── specs/
        └── medication-adherence-ui/
            ├── requirements.md
            ├── design.md
            └── tasks.md
```

## Key Files by Purpose

### Getting Started
1. **README.md** - Start here for project overview
2. **docs/QUICKSTART.md** - Quick start guide
3. **setup-iam.sh** - Setup AWS permissions
4. **prereq.sh** - Check prerequisites
5. **deploy-complete.sh** - Deploy everything

### Deployment
- **deploy-complete.sh** - Full deployment with all pipelines
- **deploy.sh** - Infrastructure only
- **docs/DEPLOYMENT.md** - Detailed deployment guide
- **DEPLOYMENT_QUICK_REFERENCE.md** - Quick command reference

### Configuration
- **infrastructure/** - All CloudFormation templates
- **infrastructure/deployment-iam-policy.json** - Required IAM permissions
- **requirements.txt** - Python dependencies
- **frontend/package.json** - Node.js dependencies

### Development
- **backend/lambda/** - Lambda function code
- **frontend/src/** - React application code
- **src/** - Python ML code
- **glue-scripts/** - ETL scripts
- **tests/** - Test files

### Documentation
- **docs/IAM_SETUP_GUIDE.md** - IAM setup
- **docs/DATASET_UPLOAD_GUIDE.md** - Dataset management
- **docs/AWS_WELL_ARCHITECTED.md** - Architecture
- **docs/GITOPS_GUIDE.md** - CI/CD setup
- **docs/SAGEMAKER_EXECUTION_GUIDE.md** - ML operations

## Workflow

### Initial Setup
```bash
1. setup-iam.sh --quick          # Setup permissions
2. prereq.sh                     # Verify prerequisites
3. deploy-complete.sh            # Deploy platform
```

### Daily Development
```bash
# Update Lambda functions
cd backend/lambda
# Edit code
zip function.zip handler.py
aws lambda update-function-code --function-name NAME --zip-file fileb://function.zip

# Update frontend
cd frontend
npm start                        # Development
npm run build                    # Production build
```

### Dataset Management
```bash
# Upload training data
aws s3 cp dataset.csv s3://BUCKET/datasets/

# Upload inference data
aws s3 cp patients.csv s3://BUCKET/inference-input/
```

### Monitoring
```bash
# View logs
aws logs tail /aws/lambda/mlops-platform-training-handler-dev --follow

# Check CloudFormation stacks
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE
```

## File Naming Conventions

### Scripts
- `*.sh` - Bash scripts (deployment, setup)
- `deploy-*.sh` - Deployment scripts
- `setup-*.sh` - Setup/configuration scripts

### Documentation
- `*.md` - Markdown documentation
- `*_GUIDE.md` - Comprehensive guides
- `*_SUMMARY.md` - Summary documents
- `QUICKSTART.md` - Getting started guide

### Infrastructure
- `*.yaml` - CloudFormation templates
- `*-pipeline.yaml` - Pipeline definitions
- `*.json` - Configuration files

### Code
- `*_handler.py` - Lambda function handlers
- `*_models.py` - Data models
- `*_test.py` - Test files

## Maintenance

### Adding New Features
1. Update CloudFormation templates in `infrastructure/`
2. Add Lambda functions in `backend/lambda/`
3. Update frontend in `frontend/src/`
4. Document in `docs/`
5. Update README.md

### Updating Documentation
- Keep README.md as the main entry point
- Use docs/ for detailed guides
- Update REPO_STRUCTURE.md when adding directories
- Keep DEPLOYMENT_QUICK_REFERENCE.md for quick commands

### Version Control
- Use `.gitignore` to exclude sensitive files
- Never commit AWS credentials or tokens
- Keep PEM files out of the repository
- Use environment variables for secrets

## Security Notes

### Files to Never Commit
- `*.pem` - SSH keys
- `*.key` - Private keys
- `.env` - Environment variables with secrets
- `credentials` - AWS credentials
- `*_token` - API tokens

### Sensitive Data
- Use AWS Secrets Manager for tokens
- Use environment variables for configuration
- Use IAM roles instead of access keys when possible
- Enable S3 encryption for data buckets

## Support

For questions about:
- **Repository structure**: This file
- **Deployment**: docs/DEPLOYMENT.md
- **IAM setup**: docs/IAM_SETUP_GUIDE.md
- **Datasets**: docs/DATASET_UPLOAD_GUIDE.md
- **Architecture**: docs/AWS_WELL_ARCHITECTED.md
