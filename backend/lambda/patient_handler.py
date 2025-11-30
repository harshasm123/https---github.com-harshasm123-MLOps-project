"""
Patient Detail Lambda Handler
Provides patient-specific data including demographics, medications, 
risk predictions, interventions, and care notes
"""

import json
import boto3
import os
from datetime import datetime, timedelta
from typing import List, Dict, Any
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
sagemaker_runtime = boto3.client('sagemaker-runtime')

# Environment variables
PATIENTS_TABLE = os.environ.get('PATIENTS_TABLE', 'mlops-platform-patients-dev')
INTERVENTIONS_TABLE = os.environ.get('INTERVENTIONS_TABLE', 'mlops-platform-interventions-dev')
CARE_NOTES_TABLE = os.environ.get('CARE_NOTES_TABLE', 'mlops-platform-care-notes-dev')
SAGEMAKER_ENDPOINT = os.environ.get('SAGEMAKER_ENDPOINT', 'medication-adherence-endpoint')


class DecimalEncoder(json.JSONEncoder):
    """JSON encoder for Decimal types"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)


def lambda_handler(event, context):
    """
    Main Lambda handler for patient operations
    
    Supported operations:
    - GET /patients/{id} - Get patient details
    - GET /patients/{id}/medications - Get medication timeline
    - GET /patients/{id}/risk - Get risk prediction with SHAP
    - GET /patients/{id}/interventions - Get recommended interventions
    - GET /patients/{id}/notes - Get care notes
    - POST /patients/{id}/notes - Add care note
    - GET /patients - List all patients (with filters)
    """
    
    http_method = event.get('httpMethod', '')
    path = event.get('path', '')
    path_parameters = event.get('pathParameters', {}) or {}
    patient_id = path_parameters.get('id')
    
    try:
        if http_method == 'GET':
            if patient_id:
                if '/medications' in path:
                    return get_patient_medications(patient_id)
                elif '/risk' in path:
                    return get_patient_risk(patient_id)
                elif '/interventions' in path:
                    return get_patient_interventions(patient_id)
                elif '/notes' in path:
                    return get_patient_notes(patient_id)
                else:
                    return get_patient_details(patient_id)
            else:
                query_params = event.get('queryStringParameters', {}) or {}
                return list_patients(query_params)
                
        elif http_method == 'POST':
            if patient_id and '/notes' in path:
                body = json.loads(event.get('body', '{}'))
                return add_care_note(patient_id, body)
            else:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'error': 'Invalid request'})
                }
        else:
            return {
                'statusCode': 405,
                'body': json.dumps({'error': 'Method not allowed'})
            }
            
    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }


def get_patient_details(patient_id: str) -> Dict[str, Any]:
    """
    Get complete patient details
    
    Args:
        patient_id: Patient ID
        
    Returns:
        Response with patient details
    """
    patients_table = dynamodb.Table(PATIENTS_TABLE)
    
    response = patients_table.get_item(Key={'id': patient_id})
    patient = response.get('Item')
    
    if not patient:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'Patient not found'})
        }
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(patient, cls=DecimalEncoder)
    }


def get_patient_medications(patient_id: str) -> Dict[str, Any]:
    """
    Get patient medication timeline with refill history
    
    Args:
        patient_id: Patient ID
        
    Returns:
        Response with medication timeline
    """
    patients_table = dynamodb.Table(PATIENTS_TABLE)
    
    response = patients_table.get_item(Key={'id': patient_id})
    patient = response.get('Item')
    
    if not patient:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'Patient not found'})
        }
    
    medications = patient.get('medications', [])
    
    # Enhance with refill history and gap analysis
    enhanced_medications = []
    for med in medications:
        refill_history = med.get('refillHistory', [])
        
        # Calculate gaps and anomalies
        for i, refill in enumerate(refill_history):
            if i > 0:
                prev_refill = refill_history[i-1]
                expected_date = datetime.fromisoformat(prev_refill['nextExpectedDate'])
                actual_date = datetime.fromisoformat(refill['refillDate'])
                gap_days = (actual_date - expected_date).days
                
                refill['refillGap'] = gap_days
                refill['isAnomaly'] = abs(gap_days) > 7  # More than 7 days gap
            else:
                refill['refillGap'] = 0
                refill['isAnomaly'] = False
        
        enhanced_medications.append({
            'medication': med,
            'refillHistory': refill_history,
            'lastRefill': refill_history[-1] if refill_history else None,
            'nextExpected': refill_history[-1].get('nextExpectedDate') if refill_history else None
        })
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'medications': enhanced_medications}, cls=DecimalEncoder)
    }


def get_patient_risk(patient_id: str) -> Dict[str, Any]:
    """
    Get patient risk prediction with SHAP explanations
    
    Args:
        patient_id: Patient ID
        
    Returns:
        Response with risk prediction and SHAP values
    """
    patients_table = dynamodb.Table(PATIENTS_TABLE)
    
    response = patients_table.get_item(Key={'id': patient_id})
    patient = response.get('Item')
    
    if not patient:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'Patient not found'})
        }
    
    risk_score = float(patient.get('riskScore', 0))
    
    # Categorize risk
    if risk_score >= 0.7:
        risk_category = 'High'
    elif risk_score >= 0.4:
        risk_category = 'Medium'
    else:
        risk_category = 'Low'
    
    # Get SHAP values (in production, these would come from the model)
    shap_values = generate_shap_explanations(patient)
    
    risk_prediction = {
        'id': f"pred-{patient_id}-{datetime.now().strftime('%Y%m%d')}",
        'patientId': patient_id,
        'riskScore': risk_score,
        'riskCategory': risk_category,
        'predictionDate': datetime.now().isoformat(),
        'shapValues': shap_values,
        'confidence': 0.85,
        'modelVersion': 'v1.0.0'
    }
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(risk_prediction, cls=DecimalEncoder)
    }


def generate_shap_explanations(patient: Dict) -> List[Dict]:
    """
    Generate SHAP value explanations for risk prediction
    
    Args:
        patient: Patient record
        
    Returns:
        List of SHAP values with explanations
    """
    # In production, these would come from the actual SHAP analysis
    # For now, we'll generate realistic explanations based on patient data
    
    shap_values = []
    
    # Refill gap contribution
    avg_gap = patient.get('avgRefillGap', 0)
    if avg_gap > 5:
        shap_values.append({
            'feature': 'refill_gap',
            'value': avg_gap,
            'contribution': 0.32,
            'description': f'Long refill gap ({avg_gap} days average)'
        })
    
    # Multiple medications
    med_count = len(patient.get('medications', []))
    if med_count > 3:
        shap_values.append({
            'feature': 'medication_count',
            'value': med_count,
            'contribution': 0.12,
            'description': f'Multiple medications ({med_count} active)'
        })
    
    # MPR trend
    mpr = patient.get('adherenceRate', 0)
    if mpr > 0.8:
        shap_values.append({
            'feature': 'mpr_trend',
            'value': mpr,
            'contribution': -0.15,
            'description': f'Stable MPR trend ({mpr:.2f})'
        })
    
    # Age factor
    age = patient.get('age', 50)
    if age > 65:
        shap_values.append({
            'feature': 'age',
            'value': age,
            'contribution': 0.08,
            'description': f'Age factor ({age} years)'
        })
    
    # Chronic conditions
    conditions = len(patient.get('chronicConditions', []))
    if conditions > 2:
        shap_values.append({
            'feature': 'chronic_conditions',
            'value': conditions,
            'contribution': 0.10,
            'description': f'Multiple chronic conditions ({conditions})'
        })
    
    # Sort by absolute contribution
    shap_values.sort(key=lambda x: abs(x['contribution']), reverse=True)
    
    return shap_values[:5]  # Top 5 contributors


def get_patient_interventions(patient_id: str) -> Dict[str, Any]:
    """
    Get recommended interventions for patient
    
    Args:
        patient_id: Patient ID
        
    Returns:
        Response with interventions
    """
    interventions_table = dynamodb.Table(INTERVENTIONS_TABLE)
    
    # Query interventions for this patient
    response = interventions_table.query(
        IndexName='patientId-createdAt-index',
        KeyConditionExpression='patientId = :pid',
        ExpressionAttributeValues={':pid': patient_id}
    )
    
    interventions = response.get('Items', [])
    
    # Sort by priority and effectiveness
    interventions.sort(key=lambda x: (x.get('priority', 999), -x.get('effectiveness', 0)))
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'interventions': interventions}, cls=DecimalEncoder)
    }


def get_patient_notes(patient_id: str) -> Dict[str, Any]:
    """
    Get care notes for patient
    
    Args:
        patient_id: Patient ID
        
    Returns:
        Response with care notes
    """
    notes_table = dynamodb.Table(CARE_NOTES_TABLE)
    
    # Query notes for this patient
    response = notes_table.query(
        IndexName='patientId-createdAt-index',
        KeyConditionExpression='patientId = :pid',
        ExpressionAttributeValues={':pid': patient_id},
        ScanIndexForward=False  # Most recent first
    )
    
    notes = response.get('Items', [])
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'notes': notes}, cls=DecimalEncoder)
    }


def add_care_note(patient_id: str, note_data: Dict) -> Dict[str, Any]:
    """
    Add a care note for patient
    
    Args:
        patient_id: Patient ID
        note_data: Note data (author, content, type)
        
    Returns:
        Response with created note
    """
    notes_table = dynamodb.Table(CARE_NOTES_TABLE)
    
    note_id = f"note-{datetime.now().strftime('%Y%m%d%H%M%S%f')}"
    note = {
        'id': note_id,
        'patientId': patient_id,
        'author': note_data.get('author', 'Unknown'),
        'authorRole': note_data.get('authorRole', 'clinician'),
        'content': note_data.get('content', ''),
        'type': note_data.get('type', 'clinical_note'),
        'createdAt': datetime.now().isoformat()
    }
    
    notes_table.put_item(Item=note)
    
    return {
        'statusCode': 201,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps(note, cls=DecimalEncoder)
    }


def list_patients(query_params: Dict) -> Dict[str, Any]:
    """
    List patients with optional filters
    
    Args:
        query_params: Query parameters (risk, condition, etc.)
        
    Returns:
        Response with patient list
    """
    patients_table = dynamodb.Table(PATIENTS_TABLE)
    
    # Get all patients
    response = patients_table.scan()
    patients = response.get('Items', [])
    
    # Apply filters
    risk_filter = query_params.get('risk')
    if risk_filter:
        if risk_filter == 'high':
            patients = [p for p in patients if p.get('riskScore', 0) >= 0.7]
        elif risk_filter == 'medium':
            patients = [p for p in patients if 0.4 <= p.get('riskScore', 0) < 0.7]
        elif risk_filter == 'low':
            patients = [p for p in patients if p.get('riskScore', 0) < 0.4]
    
    condition_filter = query_params.get('condition')
    if condition_filter:
        patients = [p for p in patients if condition_filter in p.get('chronicConditions', [])]
    
    # Sort by risk score descending
    patients.sort(key=lambda x: x.get('riskScore', 0), reverse=True)
    
    # Pagination
    limit = int(query_params.get('limit', 50))
    offset = int(query_params.get('offset', 0))
    paginated_patients = patients[offset:offset + limit]
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'patients': paginated_patients,
            'total': len(patients),
            'limit': limit,
            'offset': offset
        }, cls=DecimalEncoder)
    }


def generate_intervention_recommendations(patient: Dict) -> List[Dict]:
    """
    Generate intervention recommendations based on patient risk
    
    Args:
        patient: Patient record
        
    Returns:
        List of recommended interventions
    """
    interventions = []
    risk_score = patient.get('riskScore', 0)
    
    if risk_score >= 0.7:
        # High risk - multiple interventions
        interventions.append({
            'type': 'follow_up_call',
            'priority': 1,
            'effectiveness': 0.85,
            'description': 'Immediate follow-up call to assess barriers'
        })
        interventions.append({
            'type': 'refill_reminder',
            'priority': 2,
            'effectiveness': 0.75,
            'description': 'Set up automated refill reminders'
        })
        interventions.append({
            'type': 'teleconsultation',
            'priority': 3,
            'effectiveness': 0.70,
            'description': 'Schedule teleconsultation with physician'
        })
    elif risk_score >= 0.4:
        # Medium risk - preventive interventions
        interventions.append({
            'type': 'refill_reminder',
            'priority': 1,
            'effectiveness': 0.80,
            'description': 'Enable refill reminder notifications'
        })
        interventions.append({
            'type': 'follow_up_call',
            'priority': 2,
            'effectiveness': 0.65,
            'description': 'Scheduled check-in call'
        })
    
    return interventions
