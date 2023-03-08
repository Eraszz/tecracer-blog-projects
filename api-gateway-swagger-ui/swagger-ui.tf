
################################################################################
# Create Lambda Swagger Request Handler
################################################################################

module "lambda_swagger_ui" {
  source = "./modules/lambda"

  function_name = "swagger-ui-handler"
  role          = module.iam_role_lambda_swagger_ui.arn

  filename         = data.archive_file.lambda_swagger_ui.output_path
  handler          = "app.handler"
  source_code_hash = data.archive_file.lambda_swagger_ui.output_base64sha256
  publish          = true
  layers           = [aws_lambda_layer_version.lambda_swagger_ui_nodejs_layer.arn]
  runtime          = "nodejs14.x"

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


data "archive_file" "lambda_swagger_ui" {
  type        = "zip"
  source_file = "${path.module}/src/swagger-ui/app.js"
  output_path = "${path.module}/src/swagger-ui/app.zip"
}

resource "aws_lambda_layer_version" "lambda_swagger_ui_nodejs_layer" {
  layer_name = "swagger-ui-commonLibs"

  filename            = "${path.module}/src/swagger-ui/build/commonLibs.zip"
  compatible_runtimes = ["nodejs14.x"]
}

################################################################################
# OPTIONAL: Perform npm install of dependencies and create zip file
################################################################################

# resource "null_resource" "lambda_swagger_ui_nodejs_layer" {

#   provisioner "local-exec" {
#     working_dir = "${path.module}/swagger-ui/layers/commonLibs/nodejs"
#     command     = "npm install"
#   }
# }

# data "archive_file" "lambda_swagger_ui_common_libs_layer_package" {
#   type = "zip"

#   source_dir  = "${path.module}/swagger-ui/layers/commonLibs"
#   output_path = "${path.module}/swagger-ui/build/commonLibs.zip"

#   depends_on = [null_resource.lambda_swagger_ui_nodejs_layer]
# }


################################################################################
# Create Lambda Swagger IAM Role
################################################################################

data "aws_iam_policy_document" "api_gateway_access" {
  statement {

    actions = [
      "apigateway:*"
    ]

    resources = [
      "*"
    ]
  }
}

data "aws_iam_policy_document" "log_access" {
  statement {

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      module.lambda_swagger_ui.cloudwatch_group_arn
    ]
  }
}

module "iam_role_lambda_swagger_ui" {

  source = "./modules/iam_role"

  name = "swagger-ui-handler"

  principal = { Service = ["lambda.amazonaws.com"] }
  actions   = ["sts:AssumeRole"]

  policy_document = {
    log-access         = data.aws_iam_policy_document.log_access.json,
    api-gateway-access = data.aws_iam_policy_document.api_gateway_access.json
  }
}