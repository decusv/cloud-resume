import json
import boto3
import hashlib

# Initialize DynamoDB client
dynamo = boto3.client('dynamodb')


def hash_source_ip(source_ip):
    source_ip_bytes = source_ip.encode('utf-8')
    hashed_ip = hashlib.sha256(source_ip_bytes).hexdigest()
    return hashed_ip


# This is the main Lambda function handler that processes API Gateway requests
# It takes two parameters:
# - event: Contains information about the incoming request
# - context: Contains runtime information about the Lambda environment
def lambda_handler(event, context):
    
    # Get the HTTP method (GET or PUT) from the request
    operation = event['requestContext']['http']['method']
    source_ip = event['requestContext']['http']['sourceIp']
    hashed_ip = hash_source_ip(source_ip)
    
    # Create a boto3 client to interact with DynamoDB
    dynamo = boto3.client('dynamodb')
    
    # Handle GET requests - retrieves current visitor count
    if operation == 'PUT':
        try:
            # First, try to add the hashed IP to the metadata set
            metadata_response = dynamo.update_item(
                TableName='cloud-resume-visitor-count',
                Key={
                    'id': {'S': 'visitorMetadata'}
                },
                UpdateExpression='ADD ipHashes :ip',
                ExpressionAttributeValues={
                    ':ip': {'SS': [hashed_ip]}
                },
                ReturnValues='UPDATED_OLD'
            )
            
            # Check if the IP was already in the set
            is_new_visitor = 'Attributes' not in metadata_response or 'ipHashes' not in metadata_response['Attributes'] or hashed_ip not in metadata_response['Attributes']['ipHashes']['SS']
            
            if is_new_visitor:
                # If it's a new visitor, increment the count
                count_response = dynamo.update_item(
                    TableName='cloud-resume-visitor-count',
                    Key={
                        'id': {'S': 'visitorCount'}
                    },
                    UpdateExpression='SET #count = #count + :incr',
                    ExpressionAttributeNames={
                        '#count': 'count'
                    },
                    ExpressionAttributeValues={
                        ':incr': {'N': '1'}
                    },
                    ReturnValues='UPDATED_NEW'
                )
                new_count = int(count_response['Attributes']['count']['N'])
            else:
                # If not a new visitor, just get the current count
                count_response = dynamo.get_item(
                    TableName='cloud-resume-visitor-count',
                    Key={
                        'id': {'S': 'visitorCount'}
                    }
                )
                new_count = int(count_response['Item']['count']['N'])
            
            # Return successful response with the count
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'visitorCount': new_count})
            }
            
        except Exception as e:
            # If there's an error, return a 500 status code with the error message
            return {
                'statusCode': 500,
                'body': json.dumps({'error': str(e)})
            }
            
    # Handle any other HTTP methods
    else:
        # Return error for unsupported HTTP methods
        return {
            'statusCode': 400,
            'body': json.dumps({'error': f'Unsupported method: {operation}'})
        }
