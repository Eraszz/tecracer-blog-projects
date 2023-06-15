import json
import os
import boto3

dynamodbTableName = os.environ.get("DYNAMODB_TABLE_NAME")

dynamodb_resource = boto3.resource("dynamodb")
table = dynamodb_resource.Table(dynamodbTableName)

def lambda_handler(event, context):

    orderId = event["pathParameters"].get("orderId")
    data = table.get_item(
        Key = {
            'orderId':orderId
        }
    )

    response = {
      'statusCode': 200,
      'body': json.dumps(data["Item"]),
      'headers': {
        'Content-Type': 'application/json'
      },
    }
  
    return response