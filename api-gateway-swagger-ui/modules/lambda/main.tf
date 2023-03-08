################################################################################
# Lambda Function
################################################################################

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = var.role

  filename         = var.filename
  handler          = var.handler
  source_code_hash = var.source_code_hash
  publish          = var.publish 
  layers           = var.layers
  runtime          = var.runtime 

  timeout     = var.timeout
  memory_size = var.memory_size 
}

################################################################################
# Lambda Alias
################################################################################

resource "aws_lambda_alias" "this" {
  function_name    = aws_lambda_function.this.function_name
  
  name             = var.alias.name
  function_version = var.alias.function_version
}

################################################################################
# Lambda Permission
################################################################################

resource "aws_lambda_permission" "this" {
  function_name = aws_lambda_function.this.function_name

  action        = var.permission.action
  principal     = var.permission.principal
  qualifier     = var.permission.qualifier
  source_arn    = var.permission.source_arn
}

################################################################################
# Cloudwatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.function_name}"
}
