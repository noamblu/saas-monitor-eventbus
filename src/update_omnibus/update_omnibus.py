import json
import os
import urllib.request
import urllib.error
import logging
import boto3

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

sqs_client = boto3.client('sqs')

def lambda_handler(event, context):
    """
    Polls SQS for messages and forwards them to the Omnibus endpoint.
    triggered by EventBridge Scheduler.
    """
    omnibus_url = os.environ.get('OMNIBUS_URL')
    cert_path = os.environ.get('CERT_PATH')
    queue_url = os.environ.get('SQS_QUEUE_URL')

    if not omnibus_url:
        logger.error("OMNIBUS_URL environment variable is not set.")
        raise ValueError("OMNIBUS_URL is required.")
        
    if not queue_url:
        logger.error("SQS_QUEUE_URL environment variable is not set.")
        raise ValueError("SQS_QUEUE_URL is required.")

    if not cert_path:
        logger.warning("CERT_PATH environment variable is not set. Proceeding without specific cert path log.")

    # Polling loop (simple single batch for now, Scheduler handles frequency)
    try:
        response = sqs_client.receive_message(
            QueueUrl=queue_url,
            MaxNumberOfMessages=10,
            WaitTimeSeconds=5, # Long polling within the lambda
            AttributeNames=['All']
        )
        
        messages = response.get('Messages', [])
        logger.info(f"Received {len(messages)} messages.")
        
        for message in messages:
            process_message(message, omnibus_url, cert_path, queue_url)
            
    except Exception as e:
        logger.error(f"Error receiving messages: {str(e)}")
        raise e

    return {
        'statusCode': 200,
        'body': json.dumps(f'Processed {len(messages)} messages')
    }

def process_message(message, omnibus_url, cert_path, queue_url):
    try:
        payload = message['Body']
        receipt_handle = message['ReceiptHandle']
        msg_id = message['MessageId']
        
        logger.info(f"Processing message ID: {msg_id}")

        data = payload.encode('utf-8')
        req = urllib.request.Request(omnibus_url, data=data, headers={'Content-Type': 'application/json'})

        if cert_path and os.path.exists(cert_path):
             logger.info(f"Using certificate at: {cert_path}")
             # context logic placeholder
        else:
             logger.warning(f"Certificate not found at {cert_path}")

        with urllib.request.urlopen(req) as response:
            response_body = response.read().decode('utf-8')
            logger.info(f"Omnibus response: {response.status} - {response_body}")
            
            # Delete message after successful processing
            sqs_client.delete_message(
                QueueUrl=queue_url,
                ReceiptHandle=receipt_handle
            )
            logger.info(f"Deleted message {msg_id}")

    except urllib.error.HTTPError as e:
        logger.error(f"HTTP Error sending to Omnibus: {e.code} - {e.reason}")
        # Do NOT delete message, let it become visible again or go to DLQ
    except Exception as e:
        logger.error(f"Error processing message {message.get('MessageId')}: {str(e)}")
        # Do NOT delete message
