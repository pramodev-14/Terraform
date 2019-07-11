resource "aws_lambda_function" "lambda" {
  function_name = "monitoring-api"

  s3_bucket    = "${var.lambda_repo_bucket}"
  s3_key       = "teecontrol/${var.resource_build_name}-${var.build_tag}.zip"
  handler      = "${var.lambda_handler}"
  source_code_hash = "${base64sha256(file("${var.resource_build_name}.zip"))}"
  runtime      = "${var.lambda_runtime}"
  memory_size  = "${var.memory_size}"
  role = "${aws_iam_role.lambda_monitoring_role.arn}"

  environment   {
    variables   = {
    DB_HOST     = "${var.db_host}"
    DB_PASSWORD = "${var.db_password}"
    DB_USERNAME = "${var.db_username}"
    LOG_LEVEL   = "${var.log_level}"
            
    }
  }
}


resource "aws_iam_role" "lambda_monitoring_role" {
name = "lambda_monitoring_role_${var.project}_${var.environment}"

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

resource "aws_iam_role_policy_attachment" "lambda_execution" {
  role       = "${aws_iam_role.lambda_monitoring_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
