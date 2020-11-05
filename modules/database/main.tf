resource "aws_dynamodb_table" "dynamodb-table" {
  name           = "${var.namespace}-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "ID"

  attribute {
    name = "ID"
    type = "S"
  }
}