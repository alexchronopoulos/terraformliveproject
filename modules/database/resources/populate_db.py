#!/usr/bin/python
import csv , json
import boto3
import sys

class CsvConverter:
    def __init__(self, pageSize):

        self.pageSize = pageSize
        
        tableName = sys.argv[1]
        print("Table Name is {}".format(tableName))
        self.tableName = tableName
        
        csvFilePath = sys.argv[2]
        self.csvFilePath = csvFilePath

    def backupCsvFile(self):
        client = boto3.client('sts')
        account_id = client.get_caller_identity()['Account']
        region = sys.argv[3]
        sessionHandler = DestRegionSession(account_id, region)
        session = sessionHandler.get_subaccount_session()

        bucketName = sys.argv[4]
        backupFileName = sys.argv[5]
        backupHandler = S3InitialBackup(bucketName, backupFileName)
        csvFilePath = sys.argv[2]
        csvData = self.read_data(csvFilePath)
        backupHandler.backup(session, csvData)

    def read_data(self, csvFilePath):
        csvData = ""
        newLine = "\n"
        with open(csvFilePath, 'r') as file:
            reader = csv.reader(file)
            for row in reader:
                csvData = csvData + newLine + ",".join(row)
        
        return csvData[len(newLine):]

    def convertCsvToJson(self):
        #read the csv and add the arr to a array
        records = 0
        paginatedDataCollector = []
        
        arr = []
        allRows = []
        pages = 0
        with open (self.csvFilePath) as csvFile:
            csvReader = csv.DictReader(csvFile)

            for csvRow in csvReader:
                records = records + 1
                rowData = {}
                rowData["ID"] = {"N" : str(records)}
            
                for column in csvRow.keys():
                    colData = {"S" : csvRow[column]}
                    rowData[column] = colData
                
                item = {"PutRequest" : {"Item": rowData}}
                arr.append(item)
                allRows.append({self.tableName : arr})

                if records % self.pageSize == 0:
                    pages = pages + 1
                    jsonOutput = {self.tableName : arr}
                    arr = []
                    paginatedDataCollector.append(jsonOutput)
                    continue
            
            if len (arr) > 0:
                pages = pages + 1
                jsonOutput = {self.tableName : arr}
                arr = []
                paginatedDataCollector.append(jsonOutput)

        return paginatedDataCollector
    
class DynamoDbWriter:
    def writeToTable(self, paginatedDataCollector):
        print('************')
        print('{count} pages identified'.format(count = len(paginatedDataCollector)))
        print('************')
        dynamodb  = boto3.client('dynamodb')
        
        for jsonOutput in paginatedDataCollector:
            dynamodb.batch_write_item(RequestItems=jsonOutput)

class S3InitialBackup:
    def __init__(self, bucketName, backupFileName):
        self.bucketName = bucketName
        self.backupFileName = backupFileName
    
    def backup(self, session, csvData):
        s3Client = session.client('s3')
        s3Client.put_object(Body = csvData, Bucket=self.bucketName, Key=self.backupFileName)

class DestRegionSession:
    def __init__(self, account_id, region):
        self.account_id = account_id
        self.region = region

    def get_subaccount_session(self):
        """ Get boto3 session for account
        """
        print("Starting get_subaccount_session for {} {}".format(self.account_id, self.region))
        assume_role_response = boto3.Session()
        return assume_role_response

csvConverter = CsvConverter(25)
csvConverter.backupCsvFile()
paginatedData = csvConverter.convertCsvToJson()

dynamoDbWriter = DynamoDbWriter()
dynamoDbWriter.writeToTable(paginatedData)