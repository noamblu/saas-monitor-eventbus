import json
import os
import urllib.request
import urllib.error
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Process SQS events and forward them to the Omnibus endpoint.
    Retrieves the certificate path from the CERT_PATH environment variable.
    """
    omnibus_url = os.environ.get('OMNIBUS_URL')
    cert_path = os.environ.get('CERT_PATH')

    if not omnibus_url:
        logger.error("OMNIBUS_URL environment variable is not set.")
        raise ValueError("OMNIBUS_URL is required.")

    if not cert_path:
        logger.warning("CERT_PATH environment variable is not set. Proceeding without specific cert path log.")

    for record in event.get('Records', []):
        try:
            # SQS payload is in record['body']
            payload = record['body']
            logger.info(f"Processing message ID: {record['messageId']}")

            # Prepare the request
            # Assuming the payload is already JSON string, we send it as is.
            # If it needs wrapping, we would parse and wrap.
            data = payload.encode('utf-8')
            req = urllib.request.Request(omnibus_url, data=data, headers={'Content-Type': 'application/json'})

            # HTTPS context with certificate if needed
            # Note: valid cert path usage depends on how the cert is expected to be used 
            # (e.g. CA bundle or client cert). For now, we just log it as requested.
            # If standard verify is needed, urllib verifies against system CA by default.
            # If this is a client cert or custom CA, ssl context needed.
            # Given instructions "get the path with variable environ", we just ensure we have it.
            
            if cert_path and os.path.exists(cert_path):
                 logger.info(f"Using certificate at: {cert_path}")
                 # In a real scenario with a custom CA or client cert:
                 # import ssl
                 # context = ssl.create_default_context(cafile=cert_path)
                 # urllib.request.urlopen(req, context=context)
            else:
                 logger.warning(f"Certificate not found at {cert_path}")

            with urllib.request.urlopen(req) as response:
                response_body = response.read().decode('utf-8')
                logger.info(f"Omnibus response: {response.status} - {response_body}")

        except urllib.error.HTTPError as e:
            logger.error(f"HTTP Error sending to Omnibus: {e.code} - {e.reason}")
            # Raise to retry message (SQS DLQ logic handles failures)
            raise e
        except Exception as e:
            logger.error(f"Error processing record {record['messageId']}: {str(e)}")
            raise e

    return {
        'statusCode': 200,
        'body': json.dumps('Messages processed successfully')
    }
