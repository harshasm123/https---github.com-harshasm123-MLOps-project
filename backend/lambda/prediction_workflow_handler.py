"""
Prediction Workflow Lambda Handler
Manages batch predictions and scheduling
"""

import json
import boto3
import os
from datetime import datetime, timedelta
from typing import List, Dict, Any
from decimal import Decimal
import uuid

dynamodb = dynamodb.resource('dynamodb')
sagemaker = boto3.client('sagemaker')
events = boto3.client('events')

# Environment variables
PREDICTION_JOBS_TABLE = os.environ.get('PREDICTION_JOBS_TABLE', 'mlops-platform-prediction-jobs-dev')
PREDICTION_SCHEDULES_TABLE = os.environ.get('PREDICTION_SCHEDULES_TABLE', 'mlops-platform-prediction-schedules-dev')
SAGEMAKER_ROLE = os.environ.get('SAGEMAKER_ROLE_ARN')


class DecimalEncoder(json.JSONEncoder):
    """JSON encoder for Decimal types"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)


def lambda_handler(event, context):
    """
    Main Lambda handler for prediction workflow operations
    
    Supported operations:
    - POST /predictions/batch - Start batch prediction
    - GET /predictions/jobs - List prediction jobs
    - GET /predictions/jobs/{id} - Get job status
    - POST /predictions/schedules - Create schedule
    - GET /predictions/schedules - List schedules
    - PUT /predictions/schedules/{id} - Update schedule
    - DELETE /predictions/schedules/{id} - Delete schedule
    """
    
    http_method = event.get('httpMethod', '')
    path = event.get('path', '')
    path_parameters = event.get('pathParameters', {}) or {}
    
    try:
        if http_method == 'POST':
            if '/batch' in path:
                body = json.loads(event.get('body', '{}'))
                return start_batch_prediction(body)
            elif '/schedules' in path and not path_parameters.get('id'):
                body = json.loads(event.get('body', '{}'))
                return create_schedule(body)
                
        elif http_method == 'GET':
            if '/jobs' in path:
                job_id = path_parameters.get('id')
                if job_id:
                    return get_job_status(job_id)
                else:
                    return list_jobs()
            elif '/schedules' in path:
                schedule_id = path_parameters.get('id')
                if schedule_id:
                    return get_schedule(schedule_id)
                else:
                    return list_schedules()
                    
        elif http_method == 'PUT':
            if '/schedules' in path:
                schedule_id = path_parameters.get('id')
                body = json.loads(event.get('body', '{}'))
                return update_schedule(schedule_id, body)
                
        elif http_method == 'DELETE':
            if '/schedules' in path:
                schedule_id = path_parameters.get('id')
                return delete_schedule(schedule_id)
        
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'Endpoint not found'})
        }
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }


def start_batch_prediction(job_config: Dict) -> Dict[str, Any]:
    """
    Start a batch prediction job
    
    Args:
        job_config: Job configuration (cohort, dateRange, etc.)
        
    Returns:
        Response with job details
    """
    jobs_table = dynamodb.Table(PREDICTION_JOBS_TABLE)
    
    job_id = f"job-{uuid.uuid4().hex[:12]}"
    job = {
        'jobId': job_id,
        'status': 'pending',
        'cohort': job_config.get('cohort', 'all'),
        'dateRangeStart': job_config.get('dateRangeStart'),
        'dateRangeEnd': job_config.get('dateRangeEnd'),
        'progress': 0,
        'createdAt': datetime.now().isoformat()
    }
    
    jobs_table.put_item(Item=job)
    
    # Start SageMaker batch transform job
    try:
        start_sagemaker_batch_job(job_id, job_config)
        
        # Update status to running
        jobs_table.update_item(
            Key={'jobId': job_id},
            UpdateExpression='SET #status = :status, startedAt = :started',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':status': 'running',
                ':started': datetime.now().isoformat()
            }
        )
    except Exception as e:
        # Update status to failed
        jobs_table.update_item(
            Key={'jobId': job_id},
            UpdateExpression='SET #status = :status, errorMessage = :error',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={
                ':status': 'failed',
                ':error': str(e)
            }
        )
        raise
    
    return {
        'statusCode': 202,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(job, cls=DecimalEncoder)
    }


def get_job_status(job_id: str) -> Dict[str, Any]:
    """
    Get status of a prediction job
    
    Args:
        job_id: Job ID
        
    Returns:
        Response with job status
    """
    jobs_table = dynamodb.Table(PREDICTION_JOBS_TABLE)
    
    response = jobs_table.get_item(Key={'jobId': job_id})
    job = response.get('Item')
    
    if not job:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'Job not found'})
        }
    
    # Check SageMaker job status if running
    if job.get('status') == 'running':
        try:
            sm_status = check_sagemaker_job_status(job_id)
            if sm_status['status'] != job.get('status'):
                # Update job status
                jobs_table.update_item(
                    Key={'jobId': job_id},
                    UpdateExpression='SET #status = :status, progress = :progress',
                    ExpressionAttributeNames={'#status': 'status'},
                    ExpressionAttributeValues={
                        ':status': sm_status['status'],
                        ':progress': sm_status['progress']
                    }
                )
                job['status'] = sm_status['status']
                job['progress'] = sm_status['progress']
        except Exception as e:
            print(f"Error checking SageMaker status: {str(e)}")
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(job, cls=DecimalEncoder)
    }


def list_jobs() -> Dict[str, Any]:
    """
    List all prediction jobs
    
    Returns:
        Response with job list
    """
    jobs_table = dynamodb.Table(PREDICTION_JOBS_TABLE)
    
    response = jobs_table.scan()
    jobs = response.get('Items', [])
    
    # Sort by creation time descending
    jobs.sort(key=lambda x: x.get('createdAt', ''), reverse=True)
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'jobs': jobs}, cls=DecimalEncoder)
    }


def create_schedule(schedule_config: Dict) -> Dict[str, Any]:
    """
    Create a prediction schedule
    
    Args:
        schedule_config: Schedule configuration
        
    Returns:
        Response with created schedule
    """
    schedules_table = dynamodb.Table(PREDICTION_SCHEDULES_TABLE)
    
    schedule_id = f"schedule-{uuid.uuid4().hex[:12]}"
    
    # Calculate next run time
    frequency = schedule_config.get('frequency', 'daily')
    next_run = calculate_next_run(frequency)
    
    schedule = {
        'scheduleId': schedule_id,
        'name': schedule_config.get('name', f'Schedule {schedule_id}'),
        'frequency': frequency,
        'cohort': schedule_config.get('cohort', 'all'),
        'enabled': schedule_config.get('enabled', True),
        'nextRun': next_run.isoformat(),
        'createdBy': schedule_config.get('createdBy', 'system'),
        'createdAt': datetime.now().isoformat()
    }
    
    schedules_table.put_item(Item=schedule)
    
    # Create EventBridge rule
    try:
        create_eventbridge_rule(schedule_id, frequency)
    except Exception as e:
        print(f"Error creating EventBridge rule: {str(e)}")
    
    return {
        'statusCode': 201,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(schedule, cls=DecimalEncoder)
    }


def get_schedule(schedule_id: str) -> Dict[str, Any]:
    """
    Get a prediction schedule
    
    Args:
        schedule_id: Schedule ID
        
    Returns:
        Response with schedule details
    """
    schedules_table = dynamodb.Table(PREDICTION_SCHEDULES_TABLE)
    
    response = schedules_table.get_item(Key={'scheduleId': schedule_id})
    schedule = response.get('Item')
    
    if not schedule:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'Schedule not found'})
        }
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(schedule, cls=DecimalEncoder)
    }


def list_schedules() -> Dict[str, Any]:
    """
    List all prediction schedules
    
    Returns:
        Response with schedule list
    """
    schedules_table = dynamodb.Table(PREDICTION_SCHEDULES_TABLE)
    
    response = schedules_table.scan()
    schedules = response.get('Items', [])
    
    # Sort by creation time descending
    schedules.sort(key=lambda x: x.get('createdAt', ''), reverse=True)
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'schedules': schedules}, cls=DecimalEncoder)
    }


def update_schedule(schedule_id: str, updates: Dict) -> Dict[str, Any]:
    """
    Update a prediction schedule
    
    Args:
        schedule_id: Schedule ID
        updates: Fields to update
        
    Returns:
        Response with updated schedule
    """
    schedules_table = dynamodb.Table(PREDICTION_SCHEDULES_TABLE)
    
    # Build update expression
    update_expr = []
    expr_values = {}
    expr_names = {}
    
    if 'name' in updates:
        update_expr.append('#name = :name')
        expr_names['#name'] = 'name'
        expr_values[':name'] = updates['name']
    
    if 'frequency' in updates:
        update_expr.append('frequency = :frequency')
        expr_values[':frequency'] = updates['frequency']
        
        # Recalculate next run
        next_run = calculate_next_run(updates['frequency'])
        update_expr.append('nextRun = :nextRun')
        expr_values[':nextRun'] = next_run.isoformat()
    
    if 'enabled' in updates:
        update_expr.append('enabled = :enabled')
        expr_values[':enabled'] = updates['enabled']
    
    if not update_expr:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'No valid updates provided'})
        }
    
    response = schedules_table.update_item(
        Key={'scheduleId': schedule_id},
        UpdateExpression='SET ' + ', '.join(update_expr),
        ExpressionAttributeValues=expr_values,
        ExpressionAttributeNames=expr_names if expr_names else None,
        ReturnValues='ALL_NEW'
    )
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(response.get('Attributes', {}), cls=DecimalEncoder)
    }


def delete_schedule(schedule_id: str) -> Dict[str, Any]:
    """
    Delete a prediction schedule
    
    Args:
        schedule_id: Schedule ID
        
    Returns:
        Response confirming deletion
    """
    schedules_table = dynamodb.Table(PREDICTION_SCHEDULES_TABLE)
    
    # Delete EventBridge rule
    try:
        delete_eventbridge_rule(schedule_id)
    except Exception as e:
        print(f"Error deleting EventBridge rule: {str(e)}")
    
    schedules_table.delete_item(Key={'scheduleId': schedule_id})
    
    return {
        'statusCode': 204,
        'headers': {
            'Access-Control-Allow-Origin': '*'
        }
    }


def start_sagemaker_batch_job(job_id: str, config: Dict):
    """
    Start SageMaker batch transform job
    
    Args:
        job_id: Job ID
        config: Job configuration
    """
    # In production, this would start an actual SageMaker batch transform job
    # For now, we'll simulate it
    print(f"Starting SageMaker batch job: {job_id}")
    print(f"Config: {json.dumps(config)}")


def check_sagemaker_job_status(job_id: str) -> Dict:
    """
    Check SageMaker job status
    
    Args:
        job_id: Job ID
        
    Returns:
        Job status and progress
    """
    # In production, this would check actual SageMaker job status
    # For now, we'll simulate progress
    return {
        'status': 'running',
        'progress': 50
    }


def calculate_next_run(frequency: str) -> datetime:
    """
    Calculate next run time based on frequency
    
    Args:
        frequency: 'daily', 'weekly', or 'monthly'
        
    Returns:
        Next run datetime
    """
    now = datetime.now()
    
    if frequency == 'daily':
        return now + timedelta(days=1)
    elif frequency == 'weekly':
        return now + timedelta(weeks=1)
    elif frequency == 'monthly':
        return now + timedelta(days=30)
    else:
        return now + timedelta(days=1)


def create_eventbridge_rule(schedule_id: str, frequency: str):
    """
    Create EventBridge rule for schedule
    
    Args:
        schedule_id: Schedule ID
        frequency: Schedule frequency
    """
    # Convert frequency to cron expression
    if frequency == 'daily':
        schedule_expression = 'cron(0 0 * * ? *)'  # Daily at midnight
    elif frequency == 'weekly':
        schedule_expression = 'cron(0 0 ? * MON *)'  # Weekly on Monday
    elif frequency == 'monthly':
        schedule_expression = 'cron(0 0 1 * ? *)'  # Monthly on 1st
    else:
        schedule_expression = 'cron(0 0 * * ? *)'
    
    rule_name = f"mlops-prediction-{schedule_id}"
    
    events.put_rule(
        Name=rule_name,
        ScheduleExpression=schedule_expression,
        State='ENABLED',
        Description=f'Prediction schedule {schedule_id}'
    )
    
    print(f"Created EventBridge rule: {rule_name}")


def delete_eventbridge_rule(schedule_id: str):
    """
    Delete EventBridge rule for schedule
    
    Args:
        schedule_id: Schedule ID
    """
    rule_name = f"mlops-prediction-{schedule_id}"
    
    # Remove targets first
    try:
        events.remove_targets(Rule=rule_name, Ids=['1'])
    except:
        pass
    
    # Delete rule
    events.delete_rule(Name=rule_name)
    
    print(f"Deleted EventBridge rule: {rule_name}")
