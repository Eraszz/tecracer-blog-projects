import json
import os
import boto3
from boto3.dynamodb.conditions import Key

dynamodbTableName = os.environ.get("DYNAMODB_TABLE_NAME")
indexName = os.environ.get("GLOBAL_SECONDARY_INDEX_NAME")

dynamodb_resource = boto3.resource("dynamodb")
table = dynamodb_resource.Table(dynamodbTableName)

def lambda_handler(event, context):

    orderDate = event["queryStringParameters"].get("orderDate")
    data = table.query(
        IndexName = indexName,
        KeyConditionExpression=Key('orderDate').eq(orderDate)
    )

    print(data)

    response = {
      'statusCode': 200,
      'body': json.dumps(data["Items"]),
      'headers': {
        'Content-Type': 'application/json'
      },
    }
  
    return response