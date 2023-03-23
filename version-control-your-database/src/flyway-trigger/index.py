import boto3
import os
import json


awsRegion = os.environ.get("AWS_REGION")
instanceId = os.environ.get("INSTANCE_ID")
cloudwatchLogGroupName = os.environ.get("CLOUDWATCH_LOG_GROUP_NAME")

def lambda_handler(event, context):

    bucketName = event['Records'][0]['s3']['bucket']['name']

    client = boto3.client('ssm')

    parameters = json.loads(client.get_parameter(
            Name="/flyway/s3-mapping/"+bucketName
        )["Parameter"]["Value"])

    schema = parameters["schema"]
    flywayVersion = parameters["flywayVersion"]
    flywayConf = parameters["flywayConf"]

    response = client.send_command(
        InstanceIds=[instanceId],
        DocumentName='AWS-RunShellScript',
        Parameters={
            'executionTimeout':["36000"],
            'commands': [
                f'aws s3 --region {awsRegion} sync s3://{bucketName} /flyway-{flywayVersion}/sql/{bucketName}/',
                f'cd /flyway-{flywayVersion}/',
                f'./flyway -configFiles=/flyway-{flywayVersion}/conf/{flywayConf} -schemas={schema} -locations="filesystem:/flyway-{flywayVersion}/sql/{bucketName}/" migrate'
            ]
        },
        MaxConcurrency='1',
        CloudWatchOutputConfig={
            'CloudWatchLogGroupName': cloudwatchLogGroupName,
            'CloudWatchOutputEnabled': True
        }
    )
