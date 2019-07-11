resource "aws_api_gateway_rest_api" "monitoring-api" {
  name        = "monitoring-api"
  description = "Motnitoring API"
}

resource "aws_api_gateway_resource" "system" {
  rest_api_id = "${aws_api_gateway_rest_api.monitoring-api.id}"
  parent_id   = "${aws_api_gateway_rest_api.monitoring-api.root_resource_id}"
  path_part   = "system"
}

resource "aws_api_gateway_method" "system_get" {
  rest_api_id   = "${aws_api_gateway_rest_api.monitoring-api.id}"
  resource_id   = "${aws_api_gateway_resource.system.id}"
  http_method   = "GET"
  authorization = "AWS_IAM"
}

resource "aws_api_gateway_method_response" "200" {
  rest_api_id = "${aws_api_gateway_rest_api.monitoring-api.id}"
  resource_id = "${aws_api_gateway_resource.system.id}"
  http_method = "${aws_api_gateway_method.system_get.http_method}"
  status_code = "200"
  response_models {
        "application/json" = "Empty"
    }
   
  response_parameters {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}


resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.monitoring-api.id}"
  resource_id             = "${aws_api_gateway_resource.system.id}"
  http_method             = "${aws_api_gateway_method.system_get.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.lambda.arn}/invocations"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.arn}"
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.monitoring-api.id}/*/*/*"
}

resource "aws_api_gateway_integration_response" "response" {
  rest_api_id = "${aws_api_gateway_rest_api.monitoring-api.id}"
  resource_id = "${aws_api_gateway_resource.system.id}"
  http_method = "${aws_api_gateway_method.system_get.http_method}"
  status_code = "${aws_api_gateway_method_response.200.status_code}"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
  depends_on = ["aws_api_gateway_integration.integration"]

}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    "aws_api_gateway_method.system_get",
    "aws_api_gateway_integration.integration",
    "aws_api_gateway_method.options_method",
    "aws_api_gateway_integration.options_integration"
  ]

  rest_api_id = "${aws_api_gateway_rest_api.monitoring-api.id}"
  stage_name  = "${var.environment}"
  stage_description = "${md5(file("api.tf"))}"
}

resource "aws_api_gateway_method" "options_method" {
    rest_api_id   = "${aws_api_gateway_rest_api.monitoring-api.id}"
    resource_id   = "${aws_api_gateway_resource.system.id}"
    http_method   = "OPTIONS"
    authorization = "NONE"
}
resource "aws_api_gateway_method_response" "options_200" {
    rest_api_id   = "${aws_api_gateway_rest_api.monitoring-api.id}"
    resource_id   = "${aws_api_gateway_resource.system.id}"
    http_method   = "${aws_api_gateway_method.options_method.http_method}"
    status_code   = 200
    response_models {
        "application/json" = "Empty"
    }
    response_parameters {
        "method.response.header.Access-Control-Allow-Headers" = true,
        "method.response.header.Access-Control-Allow-Methods" = true,
        "method.response.header.Access-Control-Allow-Origin" = true,
        "method.response.header.Access-Control-Allow-Credentials" = true
    }
    depends_on = ["aws_api_gateway_method.options_method"]
}
resource "aws_api_gateway_integration" "options_integration" {
    rest_api_id   = "${aws_api_gateway_rest_api.monitoring-api.id}"
    resource_id   = "${aws_api_gateway_resource.system.id}"
    http_method   = "${aws_api_gateway_method.options_method.http_method}"
    type          = "MOCK"
    request_templates = {
      "application/json" = "{\"statusCode\": 200}"
    }
    depends_on = ["aws_api_gateway_method.options_method"]
}
resource "aws_api_gateway_integration_response" "options_integration_response" {
    rest_api_id   = "${aws_api_gateway_rest_api.monitoring-api.id}"
    resource_id   = "${aws_api_gateway_resource.system.id}"
    http_method   = "${aws_api_gateway_method.options_method.http_method}"
    status_code   = "${aws_api_gateway_method_response.options_200.status_code}"
    response_parameters = {
        "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
        "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'",
        "method.response.header.Access-Control-Allow-Origin" = "'*'",
    }
    response_templates = {
      "application/json" = ""
    }
    depends_on = ["aws_api_gateway_method_response.options_200"]
}

