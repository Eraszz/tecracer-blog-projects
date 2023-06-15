import json
import os
import boto3
import uuid
from datetime import datetime

dynamodbTableName = os.environ.get("DYNAMODB_TABLE_NAME")
microserviceTopic = os.environ.get("MICROSERVICE_TOPIC")

dynamodb_resource = boto3.resource("dynamodb")
table = dynamodb_resource.Table(dynamodbTableName)

def lambda_handler(event, context):

    payload = json.loads(event["body"])

    order = payload[microserviceTopic]
    fullName = payload["fullName"]
    item = {
            'orderId': uuid.uuid4().hex,
            'orderDate': datetime.today().strftime('%Y-%m-%d'),
            'fullName': fullName,
            microserviceTopic: order
        }

    data = table.put_item(
        Item = item
    )

    response = {
      'statusCode': 200,
      'body': json.dumps({
          'message': 'successfully placed order!',
          'order': item

        }),
      'headers': {
        'Content-Type': 'application/json'
      },
    }
  
    return response