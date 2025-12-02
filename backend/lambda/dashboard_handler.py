"""
Dashboard handler Lambda function.
Provides system statistics and health metrics for the MLOps platform.
"""

import json
import boto3
import os
from datetime import datetime

sagemaker = boto3.client('sagemaker')
dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    """Handle dashboard statistics requests."""
    try:
        stats = {
            'totalModels': 0,
            'activeTrainingJobs': 0,
            'recentPredictions': 0,
            'driftAlerts': 0,
            'lastUpdated': datetime.utcnow().isoformat()
        }
        
        return success_response(stats)
        
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