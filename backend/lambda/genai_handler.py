"""
GenAI Assistant Lambda Handler
Provides conversational AI interface using Amazon Bedrock
"""

import json
import boto3
import os
from datetime import datetime
from typing import List, Dict, Any
from decimal import Decimal

bedrock_runtime = boto3.client('bedrock-runtime', region_name='us-east-1')
dynamodb = boto3.resource('dynamodb')

# Environment variables
PATIENTS_TABLE = os.environ.get('PATIENTS_TABLE', 'mlops-platform-patients-dev')
CONVERSATIONS_TABLE = os.environ.get('CONVERSATIONS_TABLE', 'mlops-platform-conversations-dev')
BEDROCK_MODEL_ID = os.environ.get('BEDROCK_MODEL_ID', 'anthropic.claude-3-sonnet-20240229-v1:0')


class DecimalEncoder(json.JSONEncoder):
    """JSON encoder for Decimal types"""
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)


def lambda_handler(event, context):
    """
    Main Lambda handler for GenAI assistant operations
    
    Supported operations:
    - POST /genai/chat - Send message to assistant
    - GET /genai/context - Get conversation context
    - POST /genai/context/reset - Reset context
    - POST /genai/explain - Explain prediction
    - POST /genai/script - Generate outreach script
    """
    
    http_method = event.get('httpMethod', '')
    path = event.get('path', '')
    
    try:
        if http_method == 'POST':
            body = json.loads(event.get('body', '{}'))
            
            if '/chat' in path:
                return chat(body)
            elif '/context/reset' in path:
                return reset_context(body)
            elif '/explain' in path:
                return explain_prediction(body)
            elif '/script' in path:
                return generate_script(body)
                
        elif http_method == 'GET':
            if '/context' in path:
                query_params = event.get('queryStringParameters', {}) or {}
                conversation_id = query_params.get('conversationId')
                return get_context(conversation_id)
        
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


def chat(request: Dict) -> Dict[str, Any]:
    """
    Handle chat message
    
    Args:
        request: Chat request with message and context
        
    Returns:
        Response with assistant message
    """
    message = request.get('message', '')
    conversation_id = request.get('conversationId')
    context = request.get('context', {})
    
    # Get conversation history
    history = get_conversation_history(conversation_id) if conversation_id else []
    
    # Build prompt with context
    prompt = build_prompt(message, history, context)
    
    # Call Bedrock
    response = invoke_bedrock(prompt)
    
    # Extract citations and confidence
    citations = extract_citations(response, context)
    
    # Save to conversation history
    if conversation_id:
        save_message(conversation_id, 'user', message)
        save_message(conversation_id, 'assistant', response)
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'message': response,
            'citations': citations,
            'confidence': 0.85,
            'conversationId': conversation_id
        }, cls=DecimalEncoder)
    }


def explain_prediction(request: Dict) -> Dict[str, Any]:
    """
    Explain why a patient is predicted non-adherent
    
    Args:
        request: Request with patient ID
        
    Returns:
        Response with explanation
    """
    patient_id = request.get('patientId')
    
    if not patient_id:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Patient ID required'})
        }
    
    # Get patient data
    patients_table = dynamodb.Table(PATIENTS_TABLE)
    response = patients_table.get_item(Key={'id': patient_id})
    patient = response.get('Item')
    
    if not patient:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'Patient not found'})
        }
    
    # Build explanation prompt
    prompt = f"""Explain why this patient is predicted to be non-adherent to their medication:

Patient Information:
- Age: {patient.get('age', 'Unknown')}
- Gender: {patient.get('gender', 'Unknown')}
- Chronic Conditions: {', '.join(patient.get('chronicConditions', []))}
- Current Adherence Rate: {patient.get('adherenceRate', 0):.2%}
- Risk Score: {patient.get('riskScore', 0):.2f}
- Average Refill Gap: {patient.get('avgRefillGap', 0)} days
- Number of Medications: {len(patient.get('medications', []))}

Provide a clear, compassionate explanation that a healthcare provider can use to understand the patient's situation and plan interventions."""

    explanation = invoke_bedrock(prompt)
    
    # Extract key risk factors
    risk_factors = [
        f"Refill gap: {patient.get('avgRefillGap', 0)} days" if patient.get('avgRefillGap', 0) > 5 else None,
        f"Multiple medications ({len(patient.get('medications', []))})" if len(patient.get('medications', [])) > 3 else None,
        f"Low adherence rate ({patient.get('adherenceRate', 0):.2%})" if patient.get('adherenceRate', 0) < 0.7 else None
    ]
    risk_factors = [f for f in risk_factors if f]
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'explanation': explanation,
            'riskFactors': risk_factors,
            'citations': [
                {
                    'source': 'Patient Record',
                    'confidence': 1.0
                },
                {
                    'source': 'Risk Prediction Model',
                    'confidence': 0.85
                }
            ]
        }, cls=DecimalEncoder)
    }


def generate_script(request: Dict) -> Dict[str, Any]:
    """
    Generate personalized outreach script
    
    Args:
        request: Request with patient ID and intervention type
        
    Returns:
        Response with generated script
    """
    patient_id = request.get('patientId')
    intervention_type = request.get('interventionType', 'follow_up_call')
    
    if not patient_id:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Patient ID required'})
        }
    
    # Get patient data
    patients_table = dynamodb.Table(PATIENTS_TABLE)
    response = patients_table.get_item(Key={'id': patient_id})
    patient = response.get('Item')
    
    if not patient:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'Patient not found'})
        }
    
    # Build script generation prompt
    prompt = f"""Generate a compassionate, professional outreach script for a {intervention_type.replace('_', ' ')} with this patient:

Patient Information:
- Name: {patient.get('name', 'Patient')}
- Age: {patient.get('age', 'Unknown')}
- Medications: {', '.join([m.get('name', '') for m in patient.get('medications', [])])}
- Chronic Conditions: {', '.join(patient.get('chronicConditions', []))}
- Recent Adherence Issues: {patient.get('avgRefillGap', 0)} day average refill gap

The script should:
1. Be warm and empathetic
2. Address specific adherence concerns
3. Offer support and resources
4. Be culturally sensitive
5. Include open-ended questions to understand barriers
6. Suggest practical solutions

Format the script with clear sections for introduction, main discussion points, and closing."""

    script = invoke_bedrock(prompt)
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'script': script,
            'patientName': patient.get('name', 'Patient'),
            'interventionType': intervention_type,
            'generatedAt': datetime.now().isoformat()
        }, cls=DecimalEncoder)
    }


def get_context(conversation_id: str) -> Dict[str, Any]:
    """
    Get conversation context
    
    Args:
        conversation_id: Conversation ID
        
    Returns:
        Response with conversation history
    """
    if not conversation_id:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Conversation ID required'})
        }
    
    history = get_conversation_history(conversation_id)
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({
            'conversationId': conversation_id,
            'messages': history
        }, cls=DecimalEncoder)
    }


def reset_context(request: Dict) -> Dict[str, Any]:
    """
    Reset conversation context
    
    Args:
        request: Request with conversation ID
        
    Returns:
        Response confirming reset
    """
    conversation_id = request.get('conversationId')
    
    if not conversation_id:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Conversation ID required'})
        }
    
    # Delete conversation history
    conversations_table = dynamodb.Table(CONVERSATIONS_TABLE)
    conversations_table.delete_item(Key={'conversationId': conversation_id})
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        'body': json.dumps({'message': 'Context reset successfully'})
    }


def invoke_bedrock(prompt: str) -> str:
    """
    Invoke Amazon Bedrock model
    
    Args:
        prompt: Input prompt
        
    Returns:
        Model response
    """
    try:
        # Prepare request for Claude 3
        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 2000,
            "messages": [
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            "temperature": 0.7,
            "top_p": 0.9
        }
        
        response = bedrock_runtime.invoke_model(
            modelId=BEDROCK_MODEL_ID,
            body=json.dumps(request_body)
        )
        
        response_body = json.loads(response['body'].read())
        
        # Extract text from Claude 3 response
        if 'content' in response_body and len(response_body['content']) > 0:
            return response_body['content'][0]['text']
        else:
            return "I apologize, but I couldn't generate a response. Please try again."
            
    except Exception as e:
        print(f"Bedrock error: {str(e)}")
        return f"I encountered an error: {str(e)}. Please try again."


def build_prompt(message: str, history: List[Dict], context: Dict) -> str:
    """
    Build prompt with conversation history and context
    
    Args:
        message: User message
        history: Conversation history
        context: Additional context (patient ID, medication ID, etc.)
        
    Returns:
        Complete prompt
    """
    system_prompt = """You are a helpful AI assistant for a medication adherence prediction system. 
You help healthcare providers understand patient adherence patterns, risk predictions, and intervention strategies.

Be professional, compassionate, and data-driven in your responses. Always cite your sources and indicate confidence levels."""

    # Add context information
    context_str = ""
    if context.get('patientId'):
        context_str += f"\nCurrent patient context: {context['patientId']}"
    if context.get('medicationId'):
        context_str += f"\nCurrent medication context: {context['medicationId']}"
    if context.get('pageContext'):
        context_str += f"\nCurrent page: {context['pageContext']}"
    
    # Add conversation history
    history_str = ""
    if history:
        history_str = "\n\nConversation history:\n"
        for msg in history[-5:]:  # Last 5 messages
            role = msg.get('role', 'user')
            content = msg.get('content', '')
            history_str += f"{role.capitalize()}: {content}\n"
    
    full_prompt = f"""{system_prompt}
{context_str}
{history_str}

User: {message}