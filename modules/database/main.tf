resource "aws_dynamodb_table" "dynamodb-table" {
  name           = "${var.namespace}-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "Category"

  attribute {
    name = "Category"
    type = "S"
  }

  attribute {
    name = "Beverage"
    type = "S"
  }

  attribute {
    name = "Size"
    type = "S"
  }

  attribute {
    name = "Price"
    type = "S"
  }
  
}