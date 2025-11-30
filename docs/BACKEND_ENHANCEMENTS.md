# Backend Enhancements for Medication Adherence UI

## Overview

This document describes the backend enhancements made to support the comprehensive Medication Adherence Prediction UI.

## Components Implemented

### 1. Python Data Models (`src/models/ui_data_models.py`)

Complete data models matching the UI design specifications:

**Core Models:**
- `Patient` - Patient demographics and information
- `Medication` - Medication details
- `Refill` - Medication refill records
- `RiskPrediction` - ML risk predictions with SHAP values
- `Alert` - System alerts and notifications
- `Intervention` - Care interventions and recommendations
- `CareNote` - Clinical notes and care history

**Analytics Models:**
- `DashboardMetrics` - Dashboard summary data
- `MedicationAnalytics` - Medication-level analytics
- `TrendPoint` - Time series data points
- `MPRDataPoint` - Medication Possession Ratio data
- `DemographicData` - Demographic distributions
- `ForecastPoint` - Adherence forecasts

**Workflow Models:**
- `BatchPredictionJob` - Batch prediction job tracking
- `PredictionSchedule` - Scheduled prediction configuration

**GenAI Models:**
- `Message` - Chat messages
- `Citation` - Response citations
- `GenAIResponse` - AI assistant responses
- `AssistantContext` - Conversation context

**Utility Functions:**
- `categorize_risk_score()` - Risk categorization (High/Medium/Low)
- `validate_risk_score()` - Risk score validation
- `calculate_refill_gap()` - Refill gap calculation
- `is_refill_overdue()` - Overdue detection
- `calculate_mpr()` - MPR calculation
- `format_shap_explanation()` - SHAP value formatting

### 2. Dashboard Lambda Handler (`backend/lambda/dashboard_handler.py`)

**Endpoints:**
- `GET /dashboard/metrics` - Dashboard summary metrics
  - Total patients monitored
  - High/medium risk counts
  - Overall adherence rate
  - Adherence trends (6-12 months)
  - Top medications with highest risk

- `GET /dashboard/alerts` - Active alerts
  - Refill overdue alerts
  - High-risk prediction alerts
  - Drift detection alerts
  - Sorted by severity and time

- `GET /dashboard/trends?range=6months|12months` - Adherence trends
  - Historical adherence rates
  - Patient counts over time

- `GET /dashboard/top-medications` - Medication risks
  - Medications ranked by non-adherence rate
  - Patient counts per medication
  - Risk level categorization

**Functions:**
- `get_dashboard_metrics()` - Calculate and return dashboard metrics
- `get_active_alerts()` - Retrieve unacknowledged alerts
- `get_adherence_trends()` - Calculate adherence trends
- `get_top_medications()` - Rank medications by risk
- `calculate_adherence_trend()` - Time series calculation
- `get_medication_risks()` - Medication risk analysis
- `create_alert()` - Create new alerts
- `acknowledge_alert()` - Mark alerts as acknowledged

## Next Steps

### Immediate Tasks

1. **Create Patient Detail Handler** (`backend/lambda/patient_handler.py`)
   - GET /patients/{id} - Patient details
   - GET /patients/{id}/medications - Medication timeline
   - GET /patients/{id}/risk - Risk prediction with SHAP
   - GET /patients/{id}/interventions - Recommended interventions
   - GET /patients/{id}/notes - Care notes
   - POST /patients/{id}/notes - Add care note

2. **Create Medication Analytics Handler** (`backend/lambda/medication_handler.py`)
   - GET /medications - List all medications
   - GET /medications/{id}/analytics - Medication analytics
   - GET /medications/{id}/trends - MPR trends
   - GET /medications/{id}/demographics - Demographic distribution
   - GET /medications/{id}/forecast - Adherence forecast

3. **Create Prediction Workflow Handler** (`backend/lambda/prediction_workflow_handler.py`)
   - POST /predictions/batch - Start batch prediction
   - GET /predictions/jobs - List prediction jobs
   - GET /predictions/jobs/{id} - Job status
   - POST /predictions/schedules - Create schedule
   - GET /predictions/schedules - List schedules
   - PUT /predictions/schedules/{id} - Update schedule
   - DELETE /predictions/schedules/{id} - Delete schedule

4. **Create GenAI Assistant Handler** (`backend/lambda/genai_handler.py`)
   - POST /genai/chat - Send message to assistant
   - GET /genai/context - Get conversation context
   - POST /genai/context/reset - Reset context
   - POST /genai/explain - Explain prediction
   - POST /genai/script - Generate outreach script

5. **Update CloudFormation Template** (`infrastructure/cloudformation-template.yaml`)
   - Add new DynamoDB tables (Patients, Alerts, Interventions, CareNotes)
   - Add new Lambda functions
   - Add new API Gateway routes
   - Add Bedrock permissions for GenAI
   - Update IAM roles

6. **Create API Gateway Configuration**
   - Define all REST API endpoints
   - Configure CORS
   - Add request/response models
   - Set up API keys and usage plans

## Database Schema

### DynamoDB Tables

**Patients Table:**
```
Primary Key: id (String)
Attributes:
  - name, dateOfBirth, gender
  - chronicConditions (List)
  - assignedPhysician
  - contactInfo (Map)
  - insuranceInfo (Map)
  - riskScore, adherenceRate
  - medications (List)
  - createdAt, updatedAt
```

**Alerts Table:**
```
Primary Key: id (String)
GSI: patientId-createdAt-index
Attributes:
  - type, severity
  - patientId (optional)
  - message
  - createdAt
  - acknowledgedAt, acknowledgedBy (optional)
```

**Interventions Table:**
```
Primary Key: id (String)
GSI: patientId-createdAt-index
Attributes:
  - type, status
  - patientId
  - recommendedBy
  - priority, effectiveness
  - script (optional)
  - createdAt, completedAt
```

**CareNotes Table:**
```
Primary Key: id (String)
GSI: patientId-createdAt-index
Attributes:
  - patientId
  - author, authorRole
  - content, type
  - createdAt, updatedAt
```

**PredictionJobs Table:**
```
Primary Key: jobId (String)
Attributes:
  - status, progress
  - cohort
  - dateRangeStart, dateRangeEnd
  - createdAt, startedAt, completedAt
  - errorMessage (optional)
```

**PredictionSchedules Table:**
```
Primary Key: scheduleId (String)
Attributes:
  - name, frequency
  - cohort, enabled
  - lastRun, nextRun
  - createdBy, createdAt
```

## Testing

### Unit Tests
- Test data model validation
- Test utility functions
- Test Lambda handler logic
- Test error handling

### Integration Tests
- Test API endpoints
- Test DynamoDB operations
- Test cross-service communication

### Property-Based Tests
- Test risk categorization consistency
- Test MPR calculations
- Test alert generation logic
- Test trend calculations

## Deployment

### Prerequisites
- AWS CLI configured
- Python 3.12+ installed
- boto3 library installed

### Deployment Steps

1. **Package Lambda functions:**
```bash
cd backend/lambda
zip -r dashboard_handler.zip dashboard_handler.py
zip -r patient_handler.zip patient_handler.py
zip -r medication_handler.zip medication_handler.py
zip -r prediction_workflow_handler.zip prediction_workflow_handler.py
zip -r genai_handler.zip genai_handler.py
```

2. **Deploy CloudFormation stack:**
```bash
aws cloudformation create-stack \
  --stack-name mlops-platform-ui-backend \
  --template-body file://infrastructure/cloudformation-template-ui.yaml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=Environment,ParameterValue=dev
```

3. **Upload Lambda code:**
```bash
aws lambda update-function-code \
  --function-name mlops-platform-dashboard-handler-dev \
  --zip-file fileb://dashboard_handler.zip
```

4. **Test endpoints:**
```bash
# Get dashboard metrics
curl https://api-id.execute-api.us-east-1.amazonaws.com/prod/dashboard/metrics

# Get active alerts
curl https://api-id.execute-api.us-east-1.amazonaws.com/prod/dashboard/alerts
```

## Monitoring

### CloudWatch Metrics
- Lambda invocation count
- Lambda error rate
- Lambda duration
- API Gateway 4xx/5xx errors
- DynamoDB read/write capacity

### CloudWatch Logs
- Lambda execution logs
- API Gateway access logs
- Error traces

### Alarms
- High error rate (> 5%)
- High latency (> 3s)
- DynamoDB throttling
- Lambda concurrent executions

## Security

### Authentication
- AWS Cognito user pools
- JWT token validation
- Role-based access control

### Authorization
- IAM roles for Lambda
- Resource-based policies
- API Gateway authorizers

### Data Protection
- Encryption at rest (DynamoDB, S3)
- Encryption in transit (TLS)
- HIPAA compliance
- PHI handling

## Performance Optimization

### Caching
- API Gateway caching
- Lambda response caching
- DynamoDB DAX (optional)

### Optimization
- Lambda memory tuning
- DynamoDB on-demand billing
- API Gateway throttling
- Connection pooling

## Cost Optimization

### Estimated Monthly Costs (1000 patients)
- Lambda: $10-20
- DynamoDB: $25-50
- API Gateway: $3-5
- CloudWatch: $5-10
- **Total: ~$50-100/month**

### Cost Reduction Strategies
- Use Lambda reserved concurrency
- Enable DynamoDB auto-scaling
- Implement API caching
- Archive old data to S3

## Future Enhancements

1. **Real-time Updates**
   - WebSocket API for live updates
   - EventBridge for event-driven architecture

2. **Advanced Analytics**
   - QuickSight dashboards
   - Athena for ad-hoc queries
   - Redshift for data warehousing

3. **ML Enhancements**
   - Online learning
   - A/B testing framework
   - Model versioning

4. **Integration**
   - EHR system integration
   - Pharmacy system integration
   - SMS/Email notifications

5. **Mobile Support**
   - Mobile-optimized APIs
   - Push notifications
   - Offline support
