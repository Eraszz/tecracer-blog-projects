################################################################################
# REST API
################################################################################

resource "aws_api_gateway_rest_api" "this" {
  name        = "serverless-swagger-ui"
  description = "This is a test API Gateway to demonstrate the use of Swagger UI"

  body = templatefile("${path.module}/api-gateway-definition.yaml",
    {
      orders_handler_arn     = aws_lambda_function.orders_handler.arn
      swagger_ui_handler_arn = aws_lambda_function.swagger_ui_handler.arn
    }
  )

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}


################################################################################
# Orders Handler
################################################################################

resource "aws_lambda_function" "orders_handler" {
  function_name = "orders-handler"
  role          = aws_iam_role.orders_handler.arn

  filename         = data.archive_file.orders_handler.output_path
  source_code_hash = data.archive_file.orders_handler.output_base64sha256
  handler          = "orders.handler"
  runtime          = "nodejs18.x"

}

resource "aws_lambda_permission" "orders_handler" {
  function_name = aws_lambda_function.orders_handler.function_name

  action     = "lambda:InvokeFunction"
  principal  = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*"
}

data "archive_file" "orders_handler" {
  type        = "zip"
  source_file = "${path.module}/src/orders/orders.js"
  output_path = "${path.module}/src/orders/orders.zip"
}

resource "aws_iam_role" "orders_handler" {
  name = "orders-handler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "orders_handler" {
  role       = aws_iam_role.orders_handler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


################################################################################
# Swagger UI Handler
################################################################################

resource "aws_lambda_function" "swagger_ui_handler" {
  function_name = "swagger-ui-handler"
  role          = aws_iam_role.swagger_ui_handler.arn

  filename         = data.archive_file.swagger_ui_handler.output_path
  source_code_hash = data.archive_file.swagger_ui_handler.output_base64sha256
  handler          = "app.handler"
  layers           = [aws_lambda_layer_version.swagger_ui_handler.arn]
  runtime          = "nodejs14.x"

}

resource "aws_lambda_permission" "swagger_ui_handler" {
  function_name = aws_lambda_function.swagger_ui_handler.function_name

  action     = "lambda:InvokeFunction"
  principal  = "apigateway.amazonaws.com"
  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*"
}

data "archive_file" "swagger_ui_handler" {
  type        = "zip"
  source_file = "${path.module}/src/swagger-ui/app.js"
  output_path = "${path.module}/src/swagger-ui/app.zip"
}

resource "aws_lambda_layer_version" "swagger_ui_handler" {
  layer_name = "swagger-ui-commonLibs"

  filename            = "${path.module}/src/swagger-ui/build/commonLibs.zip"
  compatible_runtimes = ["nodejs14.x"]

  #  depends_on = [
  #    data.archive_file.commonLibs
  #  ]
}

resource "aws_iam_role" "swagger_ui_handler" {
  name = "swagger-ui-handler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "swagger_ui_handler_cloudwatch_access" {
  role       = aws_iam_role.swagger_ui_handler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "swagger_ui_handler_api_gateway_access" {
  role       = aws_iam_role.swagger_ui_handler.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator"
}


################################################################################
# OPTIONAL: Perform npm install of dependencies and create zip file
################################################################################

# resource "null_resource" "lambda_swagger_ui_nodejs_layer" {

#   provisioner "local-exec" {
#     working_dir = "${path.module}/src/swagger-ui/layers/commonLibs/nodejs"
#     command     = "npm install"
#   }
# }

#data "archive_file" "commonLibs" {
#  type = "zip"
#
#  source_dir  = "${path.module}/src/swagger-ui/layers/commonLibs"
#  output_path = "${path.module}/src/swagger-ui/build/commonLibs.zip"
#
#depends_on = [null_resource.lambda_swagger_ui_nodejs_layer]


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
