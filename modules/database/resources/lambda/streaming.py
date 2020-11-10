import json
import boto3
import os
import sys
from botocore.exceptions import ClientError
import logging

def handler(event, context):
    print("Received event: " + json.dumps(event, indent=2))
    s3Bucket = os.environ['koffeeMenuBackup']
    backupFileName = os.environ['backupFile']
    print('s3Bucket ' + s3Bucket)
    print('backupFileName ' + backupFileName)

    destRegion = os.environ['destRegion']
    client = boto3.client('sts')
    account_id = client.get_caller_identity()['Account']
    logging.info("account_id = {}".format(account_id))
    
    session = get_subaccount_session(account_id, destRegion)
    backupHelper = S3BackupFileUpdates(s3Bucket, backupFileName)
    backupHelper.backupCsvFile(session, event)

def get_subaccount_session(account_id, region):
    """ Get boto3 session for account
    """
    print("Starting get_subaccount_session for {} {}".format(account_id, region))
    assume_role_response = boto3.Session()
    return assume_role_response

class S3BackupFileUpdates:
    def __init__(self, bucketName, backupFileName):
        self.bucketName = bucketName
        self.backupFileName = backupFileName

    def backupCsvFile(self, session, event):
        s3Client = session.client('s3')
        fileContents = s3Client.get_object(Bucket=self.bucketName, Key=self.backupFileName)
        csvData = fileContents["Body"].read().decode()
        newRecordHandler = NewDynamoDbEventHandler(event)
        newCsvRow = newRecordHandler.new_record_as_csv()
        csvData = csvData + "\n" + newCsvRow
        s3Client.put_object(Body = csvData, Bucket=self.bucketName, Key=self.backupFileName)

class NewDynamoDbEventHandler:
    def __init__(self, event):
        self.event = event

    def new_record_as_csv(self):
        category = self.event['Records'][0]['dynamodb']['NewImage']['Category']['S']
        beverage = self.event['Records'][0]['dynamodb']['NewImage']['Beverage']['S']
        size = self.event['Records'][0]['dynamodb']['NewImage']['Size']['S']
        price = self.event['Records'][0]['dynamodb']['NewImage']['Price']['S']
        new_record = [category, beverage, size, price]

        return ",".join(new_record)
