resource "aws_s3_bucket" "backup-bucket" {
  bucket = "${var.namespace}-backup"
  acl    = "private"
  region = var.destRegion
}

resource "aws_dynamodb_table" "dynamodb-table" {
  name           = "${var.namespace}-table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "ID"

  attribute {
    name = "ID"
    type = "S"
  }

    provisioner "local-exec" {
        command = "python ./resources/populate_db.py ${var.namespace}-table ./resources/koffee_luv_drink_menu.csv ${aws_s3_bucket.backup-bucket.region} ${aws_s3_bucket.backup-bucket.bucket} backup.csv"
    }
}