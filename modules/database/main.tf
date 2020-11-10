provider "aws" {
    region = var.region
}

provider "aws" {
  alias = "oregon"
  region = var.destRegion
}

# S3
resource "aws_s3_bucket" "primary-bucket" {
  bucket = "${var.namespace}-primary"
  acl    = "private"
  provider = aws

  versioning {
    enabled = true
  }

  replication_configuration {
    role = aws_iam_role.replication.arn

    rules {
      id     = "1"
      status = "Enabled"

      destination {
        bucket        = aws_s3_bucket.backup-bucket.arn
        storage_class = "STANDARD"
      }
    }
  }
}

resource "aws_s3_bucket" "backup-bucket" {
  bucket = "${var.namespace}-backup"
  acl    = "private"
  provider = aws.oregon

  versioning {
    enabled = true
  }
}

resource "aws_iam_role" "replication" {
  name = "s3-replication-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "replication" {
  name = "s3-replication-role-policy"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetReplicationConfiguration",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.primary-bucket.arn}"
      ]
    },
    {
      "Action": [
        "s3:GetObjectVersion",
        "s3:GetObjectVersionAcl"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.primary-bucket.arn}/*"
      ]
    },
    {
      "Action": [
        "s3:ReplicateObject",
        "s3:ReplicateDelete"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.backup-bucket.arn}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}


# DYNAMO DB
resource "aws_dynamodb_table" "dynamodb-table" {
    name           = "${var.namespace}-table"
    billing_mode   = "PAY_PER_REQUEST"
    hash_key       = "ID"

    stream_enabled = true
    stream_view_type = "NEW_IMAGE"

    attribute {
      name = "ID"
      type = "N"
    }

    provisioner "local-exec" {
        command = "python ./resources/populate_db.py ${var.namespace}-table ./resources/${var.sourceFileName} ${aws_s3_bucket.backup-bucket.region} ${aws_s3_bucket.backup-bucket.bucket} ${var.backupFileName}"
    }
}

# LAMBDA
resource "aws_cloudwatch_log_group" "lambda" {
  name = "lambda"
}

resource "aws_cloudwatch_log_stream" "streaming" {
  name           = "${var.namespace}-streaming"
  log_group_name = aws_cloudwatch_log_group.lambda.name
}

resource "aws_iam_role" "lambda" {
  name = "${var.namespace}-lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda" {
  name = "${var.namespace}-lambda"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "lambda:InvokeFunction",
            "Resource": "${aws_lambda_function.streaming_lambda.arn}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:DescribeStream",
                "dynamodb:GetRecords",
                "dynamodb:GetShardIterator",
                "dynamodb:ListStreams"
            ],
            "Resource": "${aws_dynamodb_table.dynamodb-table.stream_arn}"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
                "${aws_s3_bucket.backup-bucket.arn}/*"
            ]
        },
        {
          "Action": [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource": "arn:aws:logs:*:*:*",
          "Effect": "Allow"
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

data "archive_file" "streaming_lambda_zip" {
    type          = "zip"
    source_file   = "./resources/lambda/streaming.py"
    output_path   = "./resources/lambda/streaming_lambda_function.zip"
}

resource "aws_lambda_function" "streaming_lambda" {
  filename      = data.archive_file.streaming_lambda_zip.output_path
  function_name = "${var.namespace}-DynamoDB-Streaming"
  role          = aws_iam_role.lambda.arn
  handler       = "streaming.handler"

  source_code_hash = filebase64sha256(data.archive_file.streaming_lambda_zip.output_path)

  runtime = "python3.8"

  environment {
    variables = {
      koffeeMenuBackup = aws_s3_bucket.backup-bucket.bucket
      backupFile = var.backupFileName
      destRegion = var.destRegion
    }
  }
}

resource "aws_lambda_event_source_mapping" "dynamodb" {
  event_source_arn  = aws_dynamodb_table.dynamodb-table.stream_arn
  function_name     = aws_lambda_function.streaming_lambda.arn
  starting_position = "LATEST"
}