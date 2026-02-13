data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

############################
# IAM: Assume role Lambda
############################
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

############################
# IAM: Logs mínimo
############################
data "aws_iam_policy_document" "lambda_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

############################
# Roles (uno por Lambda)
############################
resource "aws_iam_role" "orders" {
  name               = "${var.name_prefix}-lambda-orders"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

resource "aws_iam_role" "payments" {
  name               = "${var.name_prefix}-lambda-payments"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

resource "aws_iam_role" "products" {
  name               = "${var.name_prefix}-lambda-products"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

resource "aws_iam_role" "notifications_worker" {
  name               = "${var.name_prefix}-lambda-notifications-worker"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

resource "aws_iam_role" "inventory_worker" {
  name               = "${var.name_prefix}-lambda-inventory-worker"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

############################
# Policies mínimas por dominio
############################
data "aws_iam_policy_document" "orders_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query"
    ]
    resources = [var.orders_table_arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [var.sns_topic_arn]
  }
}

data "aws_iam_policy_document" "payments_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query"
    ]
    resources = [var.payments_table_arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [var.sns_topic_arn]
  }

  ############################
  # Secrets Manager (solo lectura del secret de pagos)
  ############################
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue"
    ]
    resources = [var.payments_secret_arn]
  }
}

data "aws_iam_policy_document" "products_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [var.products_table_arn]
  }
}

data "aws_iam_policy_document" "notifications_worker_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility"
    ]
    resources = [var.notifications_queue_arn]
  }
}

data "aws_iam_policy_document" "inventory_worker_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility"
    ]
    resources = [var.inventory_queue_arn]
  }
}

############################
# Attach logs + policy específica
############################
resource "aws_iam_role_policy" "orders_logs" {
  role   = aws_iam_role.orders.id
  policy = data.aws_iam_policy_document.lambda_logs.json
}

resource "aws_iam_role_policy" "orders_inline" {
  role   = aws_iam_role.orders.id
  policy = data.aws_iam_policy_document.orders_policy.json
}

resource "aws_iam_role_policy" "payments_logs" {
  role   = aws_iam_role.payments.id
  policy = data.aws_iam_policy_document.lambda_logs.json
}

resource "aws_iam_role_policy" "payments_inline" {
  role   = aws_iam_role.payments.id
  policy = data.aws_iam_policy_document.payments_policy.json
}

resource "aws_iam_role_policy" "products_logs" {
  role   = aws_iam_role.products.id
  policy = data.aws_iam_policy_document.lambda_logs.json
}

resource "aws_iam_role_policy" "products_inline" {
  role   = aws_iam_role.products.id
  policy = data.aws_iam_policy_document.products_policy.json
}

resource "aws_iam_role_policy" "notifications_logs" {
  role   = aws_iam_role.notifications_worker.id
  policy = data.aws_iam_policy_document.lambda_logs.json
}

resource "aws_iam_role_policy" "notifications_inline" {
  role   = aws_iam_role.notifications_worker.id
  policy = data.aws_iam_policy_document.notifications_worker_policy.json
}

resource "aws_iam_role_policy" "inventory_logs" {
  role   = aws_iam_role.inventory_worker.id
  policy = data.aws_iam_policy_document.lambda_logs.json
}

resource "aws_iam_role_policy" "inventory_inline" {
  role   = aws_iam_role.inventory_worker.id
  policy = data.aws_iam_policy_document.inventory_worker_policy.json
}

############################
# Lambdas (ZIP)
############################
resource "aws_lambda_function" "orders" {
  function_name    = "${var.name_prefix}-orders"
  role             = aws_iam_role.orders.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = var.orders_zip_path
  source_code_hash = filebase64sha256(var.orders_zip_path)
  timeout          = 10

  environment {
    variables = {
      SERVICE_NAME = "orders"
    }
  }

  tags = var.tags
}

resource "aws_lambda_function" "payments" {
  function_name    = "${var.name_prefix}-payments"
  role             = aws_iam_role.payments.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = var.payments_zip_path
  source_code_hash = filebase64sha256(var.payments_zip_path)
  timeout          = 10

  environment {
    variables = {
      SERVICE_NAME        = "payments"
      PAYMENTS_SECRET_ARN = var.payments_secret_arn
    }
  }

  tags = var.tags
}

resource "aws_lambda_function" "products" {
  function_name    = "${var.name_prefix}-products"
  role             = aws_iam_role.products.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = var.products_zip_path
  source_code_hash = filebase64sha256(var.products_zip_path)
  timeout          = 10

  environment {
    variables = {
      SERVICE_NAME = "products"
    }
  }

  tags = var.tags
}

resource "aws_lambda_function" "notifications_worker" {
  function_name    = "${var.name_prefix}-notifications-worker"
  role             = aws_iam_role.notifications_worker.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = var.notifications_worker_zip_path
  source_code_hash = filebase64sha256(var.notifications_worker_zip_path)
  timeout          = 10

  environment {
    variables = {
      SERVICE_NAME = "notifications_worker"
    }
  }

  tags = var.tags
}

resource "aws_lambda_function" "inventory_worker" {
  function_name    = "${var.name_prefix}-inventory-worker"
  role             = aws_iam_role.inventory_worker.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = var.inventory_worker_zip_path
  source_code_hash = filebase64sha256(var.inventory_worker_zip_path)
  timeout          = 10

  environment {
    variables = {
      SERVICE_NAME = "inventory_worker"
    }
  }

  tags = var.tags
}

############################
# API GW v2: Integrations
############################
resource "aws_apigatewayv2_integration" "orders" {
  api_id                 = var.api_id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.orders.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "payments" {
  api_id                 = var.api_id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.payments.arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "products" {
  api_id                 = var.api_id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.products.arn
  payload_format_version = "2.0"
}

############################
# API GW v2: Routes
############################
resource "aws_apigatewayv2_route" "orders_post" {
  api_id             = var.api_id
  route_key          = "POST /orders"
  target             = "integrations/${aws_apigatewayv2_integration.orders.id}"
  authorization_type = "JWT"
  authorizer_id      = var.authorizer_id
}

resource "aws_apigatewayv2_route" "orders_get" {
  api_id             = var.api_id
  route_key          = "GET /orders/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.orders.id}"
  authorization_type = "JWT"
  authorizer_id      = var.authorizer_id
}

resource "aws_apigatewayv2_route" "orders_status_put" {
  api_id             = var.api_id
  route_key          = "PUT /orders/{id}/status"
  target             = "integrations/${aws_apigatewayv2_integration.orders.id}"
  authorization_type = "JWT"
  authorizer_id      = var.authorizer_id
}

resource "aws_apigatewayv2_route" "payments_post" {
  api_id             = var.api_id
  route_key          = "POST /payments"
  target             = "integrations/${aws_apigatewayv2_integration.payments.id}"
  authorization_type = "JWT"
  authorizer_id      = var.authorizer_id
}

# Webhook inbound: sin auth
resource "aws_apigatewayv2_route" "payments_webhook_post" {
  api_id    = var.api_id
  route_key = "POST /payments/webhook"
  target    = "integrations/${aws_apigatewayv2_integration.payments.id}"
}

resource "aws_apigatewayv2_route" "products_get" {
  api_id             = var.api_id
  route_key          = "GET /products"
  target             = "integrations/${aws_apigatewayv2_integration.products.id}"
  authorization_type = "JWT"
  authorizer_id      = var.authorizer_id
}

############################
# Permiso: API GW -> Lambda
############################
resource "aws_lambda_permission" "orders_invoke" {
  statement_id  = "AllowInvokeFromAPIGWOrders"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.orders.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${var.api_id}/*/*"
}

resource "aws_lambda_permission" "payments_invoke" {
  statement_id  = "AllowInvokeFromAPIGWPayments"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.payments.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${var.api_id}/*/*"
}

resource "aws_lambda_permission" "products_invoke" {
  statement_id  = "AllowInvokeFromAPIGWProducts"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.products.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${var.api_id}/*/*"
}

############################
# SQS -> Lambda mappings (Workers)
############################
resource "aws_lambda_event_source_mapping" "notifications" {
  event_source_arn = var.notifications_queue_arn
  function_name    = aws_lambda_function.notifications_worker.arn
  batch_size       = 10
  enabled          = true
}

resource "aws_lambda_event_source_mapping" "inventory" {
  event_source_arn = var.inventory_queue_arn
  function_name    = aws_lambda_function.inventory_worker.arn
  batch_size       = 10
  enabled          = true
}
