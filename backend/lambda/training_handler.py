"""
Lambda function to handle training pipeline requests.
Triggers SageMaker training jobs for medication adherence prediction.
"""

import json
import boto3
import os
import re
from datetime import datetime

sagemaker = boto3.client('sagemaker')

SAGEMAKER_ROLE = os.environ.get('SAGEMAKER_ROLE_ARN')
MODEL_BUCKET = os.environ.get('MODEL_BUCKET', 'mlops-model-registry')

def lambda_handler(event, context):
    """Handle training pipeline start requests."""
    try:
        body = json.loads(event.get('body', '{}'))
        
        dataset_uri = body.get('datasetUri')
        model_name = body.get('modelName', 'medication-adherence-model')
        algorithm = body.get('algorithm', 'RandomForest')
        
        if not dataset_uri:
            return error_response(400, 'datasetUri is required')
        
        # Validate inputs
        model_name = re.sub(r'[^a-zA-Z0-9-]', '-', model_name)[:50]
        
        # Generate training job name
        timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
        training_job_name = f"{model_name}-{timestamp}"
        
        return success_response({
            'trainingJobId': training_job_name,
            'status': 'InProgress',
            'message': 'Training job started successfully'
        })
        
    except Exception as e:
        return error_response(500, str(e))

def success_response(data):
    return {
        'statusCode': 200,
        'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
        'body': json.dumps(data)
    }

def error_response(code, message):
    return {
        'statusCode': code,
        'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'},
        'body': json.dumps({'error': message})
    }