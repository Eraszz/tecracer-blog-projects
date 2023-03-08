################################################################################
# Set Locals
################################################################################

locals {
  lambda_proxies = {
    orders = "${path.module}/src/orders/",
    users  = "${path.module}/src/users/",
  }
}


################################################################################
# Create REST API
################################################################################

resource "aws_api_gateway_rest_api" "this" {
  name        = var.api_name
  description = "This is a test API Gateway to demonstrate the use of Swagger UI"

  body = templatefile("${path.module}/api-gateway-definition.yaml",
    {
      title              = var.api_name
      orders_handler     = module.lambda_proxy["orders"].alias_arn
      users_handler      = module.lambda_proxy["users"].alias_arn
      swagger_ui_handler = module.lambda_swagger_ui.alias_arn
    }
  )

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}


################################################################################
# Create Deployment and API Gateway Stage
################################################################################

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = "v1"
}


################################################################################
# Create Lambda Orders and Users Request Handlers
################################################################################

module "lambda_proxy" {
  for_each = local.lambda_proxies

  source = "./modules/lambda"

  function_name = "handler-${each.key}"
  role          = module.iam_role_lambda_proxy[each.key].arn

  filename         = data.archive_file.lambda_proxy[each.key].output_path
  handler          = "index.lambda_handler"
  source_code_hash = data.archive_file.lambda_proxy[each.key].output_base64sha256
  publish          = true
  layers           = ["arn:aws:lambda:eu-central-1:336392948345:layer:AWSSDKPandas-Python39:1"]
  runtime          = "python3.9"

  timeout     = 30
  memory_size = 128

  alias = {
    name             = "v1"
    function_version = "$LATEST"
  }

  permission = {
    action     = "lambda:InvokeFunction"
    principal  = "apigateway.amazonaws.com"
    qualifier  = "v1"
    source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*"
  }
}


data "archive_file" "lambda_proxy" {
  for_each = local.lambda_proxies

  type        = "zip"
  output_path = "${each.value}/python.zip"

  dynamic "source" {
    for_each = fileset("${each.value}/", "*.py")

    content {
      content  = file("${each.value}/${source.value}")
      filename = basename(source.value)
    }
  }
}


################################################################################
# Create Lambda Orders and Users IAM Roles
################################################################################

data "aws_iam_policy_document" "log_access_handler" {
  statement {

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "*"
    ]
  }
}


module "iam_role_lambda_proxy" {
  for_each = local.lambda_proxies

  source = "./modules/iam_role"

  name = "handler-${each.key}"

  principal = { Service = ["lambda.amazonaws.com"] }
  actions   = ["sts:AssumeRole"]

  policy_document = {
  log-access = data.aws_iam_policy_document.log_access_handler.json }
}
