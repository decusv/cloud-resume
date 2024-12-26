import boto3
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    # Initialize DynamoDB client
    dynamodb = boto3.client('dynamodb')
    
    try:
        # Update the item to remove the stringset attribute entirely
        response = dynamodb.update_item(
            TableName='cloud-resume-visitor-count',
            Key={
                'id': {'S': 'visitorMetadata'}
            },
            UpdateExpression='REMOVE ipHashes'
        )
        
        return {
            'statusCode': 200,
            'body': 'Successfully removed ipHashes attribute'
        }
        
    except ClientError as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': f'Error clearing string set: {str(e)}'
        }
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        return {
            'statusCode': 500,
            'body': f'Unexpected error: {str(e)}'
        }