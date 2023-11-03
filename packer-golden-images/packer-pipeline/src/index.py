import boto3
import os
from datetime import datetime

bucketName = os.environ.get("S3_BUCKET_NAME")
kmsKeyArn = os.environ.get("KMS_KEY_ARN")

def lambda_handler(event, context):

    instanceId = event['instanceId'] 
     
    inspector = boto3.client('inspector2')
    reportFormat = 'JSON'
    current_time = datetime.now()
    formatted_time = current_time.strftime("%Y/%m/%d/%H-%M-%S")

    response = inspector.create_findings_report(
        filterCriteria={
            'resourceId': [
                {
                    'comparison': 'EQUALS',
                    'value': instanceId
                },
            ],
            'resourceTags': [
                {
                    'comparison': 'EQUALS',
                    'key': 'inspect',
                    'value': 'true'
                },
            ]
        },
        reportFormat=reportFormat,
        s3Destination={
            'bucketName': bucketName,
            'keyPrefix': formatted_time+'_'+instanceId,
            'kmsKeyArn': kmsKeyArn
        }
    )
