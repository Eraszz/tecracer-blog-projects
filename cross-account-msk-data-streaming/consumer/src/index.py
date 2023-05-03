import json
import base64
import os
import boto3

from decimal import Decimal
from itertools import groupby
from operator import attrgetter

kafkaTopic = os.environ.get("KAFKA_TOPIC")
dynamodbTableName = os.environ.get("DYNAMODB_TABLE_NAME")

dynamodb_resource = boto3.resource("dynamodb")
table = dynamodb_resource.Table(dynamodbTableName)

def lambda_handler(event, context):
    payloads = []

    record_list = event['records'][kafkaTopic]            
    for record in record_list:

        value_decoded = base64.b64decode(record['value'])
        payload = json.loads(value_decoded)

        device_id = payload['device_id']
        timestamp = payload['timestamp']
        temperature = payload['temperature']
        
        payloads.append(Payload(device_id, timestamp, temperature))

    attribute = attrgetter('device_id')
    ordered_payloads = {k:list(v) for k,v in groupby(sorted(payloads, key=attribute), attribute)}

    for device in ordered_payloads:
        avg_temperature = round(sum(payload.temperature for payload in ordered_payloads[device]) / len(ordered_payloads[device]))
        min_timestamp   = min(payload.timestamp for payload in ordered_payloads[device])
        max_timestamp   = max(payload.timestamp for payload in ordered_payloads[device])

        response = table.put_item(
            Item={
                'device_id': device,
                'window_start': min_timestamp,
                'window_stop': max_timestamp,
                'avg_temp': Decimal(avg_temperature)
            }
        )

class Payload:
 def __init__(self,device_id, timestamp, temperature):
        self.device_id = device_id
        self.timestamp = timestamp
        self.temperature = temperature
