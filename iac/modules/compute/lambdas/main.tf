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
# IAM: Logs mínimo (restringido)
############################
data "aws_iam_policy_document" "lambda_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/aws/lambda/*",
      "arn:aws:logs:*:*:log-group:/aws/lambda/*:*"
    ]
  }
}

############################
# Roles (uno por Lambda)
############################
resource "aws_iam_role" "orders_create" {
  name               = "${var.name_prefix}-lambda-orders-create"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

resource "aws_iam_role" "orders_get" {
  name               = "${var.name_prefix}-lambda-orders-get"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

resource "aws_iam_role" "orders_update_status" {
  name               = "${var.name_prefix}-lambda-orders-update-status"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

resource "aws_iam_role" "payments_create" {
  name               = "${var.name_prefix}-lambda-payments-create"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

resource "aws_iam_role" "payments_webhook" {
  name               = "${var.name_prefix}-lambda-payments-webhook"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

resource "aws_iam_role" "products_list" {
  name               = "${var.name_prefix}-lambda-products-list"
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
# Policies (least privilege)
############################

data "aws_iam_policy_document" "orders_create_policy" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:PutItem"]
    resources = [var.orders_table_arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [var.sns_topic_arn]
  }
}

data "aws_iam_policy_document" "orders_get_policy" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:GetItem"]
    resources = [var.orders_table_arn]
  }
}

data "aws_iam_policy_document" "orders_update_status_policy" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:UpdateItem"]
    resources = [var.orders_table_arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [var.sns_topic_arn]
  }
}

data "aws_iam_policy_document" "payments_create_policy" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:PutItem"]
    resources = [var.payments_table_arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["sns:Publish"]
    resources = [var.sns_topic_arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [var.payments_secret_arn]
  }
}

data "aws_iam_policy_document" "products_list_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:GetItem"
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

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query"
    ]
    resources = [var.orders_table_arn]
  }
}

############################
# Attach logs + inline policy
############################
resource "aws_iam_role_policy" "orders_create_logs" {
  role   = aws_iam_role.orders_create.id
  policy = data.aws_iam_policy_document.lambda_logs.json
}
resource "aws_iam_role_policy" "orders_create_inline" {
  role   = aws_iam_role.orders_create.id
  policy = data.aws_iam_policy_document.orders_create_policy.json
}

resource "aws_iam_role_policy" "orders_get_logs" {
  role   = aws_iam_role.orders_get.id
  policy = data.aws_iam_policy_document.lambda_logs.json
}
resource "aws_iam_role_policy" "orders_get_inline" {
  role   = aws_iam_role.orders_get.id
  policy = data.aws_iam_policy_document.orders_get_policy.json
}

resource "aws_iam_role_policy" "orders_update_status_logs" {
  role   = aws_iam_role.orders_update_status.id
  policy = data.aws_iam_policy_document.lambda_logs.json
}
resource "aws_iam_role_policy" "orders_update_status_inline" {
  role   = aws_iam_role.orders_update_status.id
  policy = data.aws_iam_policy_document.orders_update_status_policy.json
}

resource "aws_iam_role_policy" "payments_create_logs" {
  role   = aws_iam_role.payments_create.id
  policy = data.aws_iam_policy_document.lambda_logs.json
}
resource "aws_iam_role_policy" "payments_create_inline" {
  role   = aws_iam_role.payments_create.id
  policy = data.aws_iam_policy_document.payments_create_policy.json
}

# ✅ Webhook: SOLO logs (NO inline policy vacía)
resource "aws_iam_role_policy" "payments_webhook_logs" {
  role   = aws_iam_role.payments_webhook.id
  policy = data.aws_iam_policy_document.lambda_logs.json
}

resource "aws_iam_role_policy" "products_list_logs" {
  role   = aws_iam_role.products_list.id
  policy = data.aws_iam_policy_document.lambda_logs.json
}
resource "aws_iam_role_policy" "products_list_inline" {
  role   = aws_iam_role.products_list.id
  policy = data.aws_iam_policy_document.products_list_policy.json
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

resource "aws_lambda_function" "orders_create" {
  function_name    = "${var.name_prefix}-orders-create"
  role             = aws_iam_role.orders_create.arn
  handler          = "orders_create/index.handler"
  runtime          = "nodejs20.x"
  filename         = var.orders_create_zip_path
  source_code_hash = filebase64sha256(var.orders_create_zip_path)
  timeout          = 10

  reserved_concurrent_executions = var.lambda_reserved_concurrency != null ? var.lambda_reserved_concurrency : -1

  dynamic "dead_letter_config" {
    for_each = var.dlq_arn != null ? [1] : []
    content { target_arn = var.dlq_arn }
  }

  dynamic "vpc_config" {
    for_each = (var.security_group_id != null && length(var.subnet_ids) > 0) ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = [var.security_group_id]
    }
  }

  tracing_config { mode = "Active" }
  code_signing_config_arn = var.code_signing_config_arn
  kms_key_arn             = var.lambda_kms_key_arn

  environment {
    variables = {
      SERVICE_NAME      = "orders_create"
      ORDERS_TABLE_NAME = var.orders_table_name
      SNS_TOPIC_ARN     = var.sns_topic_arn
    }
  }

  tags = var.tags
}

resource "aws_lambda_function" "orders_get" {
  function_name    = "${var.name_prefix}-orders-get"
  role             = aws_iam_role.orders_get.arn
  handler          = "orders_get/index.handler"
  runtime          = "nodejs20.x"
  filename         = var.orders_get_zip_path
  source_code_hash = filebase64sha256(var.orders_get_zip_path)
  timeout          = 10

  reserved_concurrent_executions = var.lambda_reserved_concurrency != null ? var.lambda_reserved_concurrency : -1

  dynamic "vpc_config" {
    for_each = (var.security_group_id != null && length(var.subnet_ids) > 0) ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = [var.security_group_id]
    }
  }

  tracing_config { mode = "Active" }
  code_signing_config_arn = var.code_signing_config_arn
  kms_key_arn             = var.lambda_kms_key_arn

  environment {
    variables = {
      SERVICE_NAME      = "orders_get"
      ORDERS_TABLE_NAME = var.orders_table_name
    }
  }

  tags = var.tags
}

resource "aws_lambda_function" "orders_update_status" {
  function_name    = "${var.name_prefix}-orders-update-status"
  role             = aws_iam_role.orders_update_status.arn
  handler          = "orders_update_status/index.handler"
  runtime          = "nodejs20.x"
  filename         = var.orders_update_status_zip_path
  source_code_hash = filebase64sha256(var.orders_update_status_zip_path)
  timeout          = 10

  reserved_concurrent_executions = var.lambda_reserved_concurrency != null ? var.lambda_reserved_concurrency : -1

  dynamic "vpc_config" {
    for_each = (var.security_group_id != null && length(var.subnet_ids) > 0) ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = [var.security_group_id]
    }
  }

  tracing_config { mode = "Active" }
  code_signing_config_arn = var.code_signing_config_arn
  kms_key_arn             = var.lambda_kms_key_arn

  environment {
    variables = {
      SERVICE_NAME      = "orders_update_status"
      ORDERS_TABLE_NAME = var.orders_table_name
      SNS_TOPIC_ARN     = var.sns_topic_arn
    }
  }

  tags = var.tags
}

resource "aws_lambda_function" "payments_create" {
  function_name    = "${var.name_prefix}-payments-create"
  role             = aws_iam_role.payments_create.arn
  handler          = "payments_create/index.handler"
  runtime          = "nodejs20.x"
  filename         = var.payments_create_zip_path
  source_code_hash = filebase64sha256(var.payments_create_zip_path)
  timeout          = 10

  reserved_concurrent_executions = var.lambda_reserved_concurrency != null ? var.lambda_reserved_concurrency : -1

  dynamic "vpc_config" {
    for_each = (var.security_group_id != null && length(var.subnet_ids) > 0) ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = [var.security_group_id]
    }
  }

  tracing_config { mode = "Active" }
  code_signing_config_arn = var.code_signing_config_arn
  kms_key_arn             = var.lambda_kms_key_arn

  environment {
    variables = {
      SERVICE_NAME        = "payments_create"
      PAYMENTS_TABLE_NAME = var.payments_table_name
      SNS_TOPIC_ARN       = var.sns_topic_arn
      PAYMENTS_SECRET_ARN = var.payments_secret_arn
    }
  }

  tags = var.tags
}

resource "aws_lambda_function" "payments_webhook" {
  function_name    = "${var.name_prefix}-payments-webhook"
  role             = aws_iam_role.payments_webhook.arn
  handler          = "payments_webhook/index.handler"
  runtime          = "nodejs20.x"
  filename         = var.payments_webhook_zip_path
  source_code_hash = filebase64sha256(var.payments_webhook_zip_path)
  timeout          = 10

  reserved_concurrent_executions = var.lambda_reserved_concurrency != null ? var.lambda_reserved_concurrency : -1

  dynamic "vpc_config" {
    for_each = (var.security_group_id != null && length(var.subnet_ids) > 0) ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = [var.security_group_id]
    }
  }

  tracing_config { mode = "Active" }
  code_signing_config_arn = var.code_signing_config_arn
  kms_key_arn             = var.lambda_kms_key_arn

  environment {
    variables = {
      SERVICE_NAME = "payments_webhook"
    }
  }

  tags = var.tags
}

resource "aws_lambda_function" "products_list" {
  function_name    = "${var.name_prefix}-products-list"
  role             = aws_iam_role.products_list.arn
  handler          = "products_list/index.handler"
  runtime          = "nodejs20.x"
  filename         = var.products_list_zip_path
  source_code_hash = filebase64sha256(var.products_list_zip_path)
  timeout          = 10

  reserved_concurrent_executions = var.lambda_reserved_concurrency != null ? var.lambda_reserved_concurrency : -1

  dynamic "vpc_config" {
    for_each = (var.security_group_id != null && length(var.subnet_ids) > 0) ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = [var.security_group_id]
    }
  }

  tracing_config { mode = "Active" }
  code_signing_config_arn = var.code_signing_config_arn
  kms_key_arn             = var.lambda_kms_key_arn

  environment {
    variables = {
      SERVICE_NAME        = "products_list"
      PRODUCTS_TABLE_NAME = var.products_table_name
    }
  }

  tags = var.tags
}

resource "aws_lambda_function" "notifications_worker" {
  function_name    = "${var.name_prefix}-notifications-worker"
  role             = aws_iam_role.notifications_worker.arn
  handler          = "notifications_worker/index.handler"
  runtime          = "nodejs20.x"
  filename         = var.notifications_worker_zip_path
  source_code_hash = filebase64sha256(var.notifications_worker_zip_path)
  timeout          = 10

  environment {
    variables = { SERVICE_NAME = "notifications_worker" }
  }

  tags = var.tags
}

resource "aws_lambda_function" "inventory_worker" {
  function_name    = "${var.name_prefix}-inventory-worker"
  role             = aws_iam_role.inventory_worker.arn
  handler          = "inventory_worker/index.handler"
  runtime          = "nodejs20.x"
  filename         = var.inventory_worker_zip_path
  source_code_hash = filebase64sha256(var.inventory_worker_zip_path)
  timeout          = 10

  environment {
    variables = {
      SERVICE_NAME      = "inventory_worker"
      ORDERS_TABLE_NAME = var.orders_table_name
    }
  }

  tags = var.tags
}

############################
# API GW v2: Integrations
############################
resource "aws_apigatewayv2_integration" "orders_create" {
  api_id                 = var.api_id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.orders_create.arn
  payload_format_version = "2.0"

  lifecycle { create_before_destroy = true }
}

resource "aws_apigatewayv2_integration" "orders_get" {
  api_id                 = var.api_id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.orders_get.arn
  payload_format_version = "2.0"

  lifecycle { create_before_destroy = true }
}

resource "aws_apigatewayv2_integration" "orders_update_status" {
  api_id                 = var.api_id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.orders_update_status.arn
  payload_format_version = "2.0"

  lifecycle { create_before_destroy = true }
}

resource "aws_apigatewayv2_integration" "payments_create" {
  api_id                 = var.api_id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.payments_create.arn
  payload_format_version = "2.0"

  lifecycle { create_before_destroy = true }
}

resource "aws_apigatewayv2_integration" "payments_webhook" {
  api_id                 = var.api_id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.payments_webhook.arn
  payload_format_version = "2.0"

  lifecycle { create_before_destroy = true }
}

resource "aws_apigatewayv2_integration" "products_list" {
  api_id                 = var.api_id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.products_list.arn
  payload_format_version = "2.0"

  lifecycle { create_before_destroy = true }
}

############################
# API GW v2: Routes
############################
resource "aws_apigatewayv2_route" "orders_post" {
  api_id             = var.api_id
  route_key          = "POST /orders"
  target             = "integrations/${aws_apigatewayv2_integration.orders_create.id}"
  authorization_type = "JWT"
  authorizer_id      = var.authorizer_id

  depends_on = [aws_apigatewayv2_integration.orders_create]
  lifecycle  { create_before_destroy = true }
}

resource "aws_apigatewayv2_route" "orders_get" {
  api_id             = var.api_id
  route_key          = "GET /orders/{id}"
  target             = "integrations/${aws_apigatewayv2_integration.orders_get.id}"
  authorization_type = "JWT"
  authorizer_id      = var.authorizer_id

  depends_on = [aws_apigatewayv2_integration.orders_get]
  lifecycle  { create_before_destroy = true }
}

resource "aws_apigatewayv2_route" "orders_status_put" {
  api_id             = var.api_id
  route_key          = "PUT /orders/{id}/status"
  target             = "integrations/${aws_apigatewayv2_integration.orders_update_status.id}"
  authorization_type = "JWT"
  authorizer_id      = var.authorizer_id

  depends_on = [aws_apigatewayv2_integration.orders_update_status]
  lifecycle  { create_before_destroy = true }
}

resource "aws_apigatewayv2_route" "payments_post" {
  api_id             = var.api_id
  route_key          = "POST /payments"
  target             = "integrations/${aws_apigatewayv2_integration.payments_create.id}"
  authorization_type = "JWT"
  authorizer_id      = var.authorizer_id

  depends_on = [aws_apigatewayv2_integration.payments_create]
  lifecycle  { create_before_destroy = true }
}

resource "aws_apigatewayv2_route" "payments_webhook_post" {
  api_id             = var.api_id
  route_key          = "POST /payments/webhook"
  target             = "integrations/${aws_apigatewayv2_integration.payments_webhook.id}"
  authorization_type = "NONE"

  depends_on = [aws_apigatewayv2_integration.payments_webhook]
  lifecycle  { create_before_destroy = true }
}

resource "aws_apigatewayv2_route" "products_get" {
  api_id             = var.api_id
  route_key          = "GET /products"
  target             = "integrations/${aws_apigatewayv2_integration.products_list.id}"
  authorization_type = "JWT"
  authorizer_id      = var.authorizer_id

  depends_on = [aws_apigatewayv2_integration.products_list]
  lifecycle  { create_before_destroy = true }
}

############################
# Permiso: API GW -> Lambda
############################
resource "aws_lambda_permission" "orders_create_invoke" {
  statement_id  = "AllowInvokeFromAPIGWOrdersCreate"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.orders_create.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.api_id}/*/*"
}

resource "aws_lambda_permission" "orders_get_invoke" {
  statement_id  = "AllowInvokeFromAPIGWOrdersGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.orders_get.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.api_id}/*/*"
}

resource "aws_lambda_permission" "orders_update_status_invoke" {
  statement_id  = "AllowInvokeFromAPIGWOrdersUpdateStatus"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.orders_update_status.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.api_id}/*/*"
}

resource "aws_lambda_permission" "payments_create_invoke" {
  statement_id  = "AllowInvokeFromAPIGWPaymentsCreate"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.payments_create.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.api_id}/*/*"
}

resource "aws_lambda_permission" "payments_webhook_invoke" {
  statement_id  = "AllowInvokeFromAPIGWPaymentsWebhook"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.payments_webhook.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.api_id}/*/*"
}

resource "aws_lambda_permission" "products_list_invoke" {
  statement_id  = "AllowInvokeFromAPIGWProductsList"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.products_list.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.api_id}/*/*"
}

############################
# SQS -> Lambda mappings (Workers)
############################
resource "aws_lambda_event_source_mapping" "notifications" {
  event_source_arn         = var.notifications_queue_arn
  function_name            = aws_lambda_function.notifications_worker.arn
  batch_size               = 10
  enabled                  = true
  function_response_types  = ["ReportBatchItemFailures"]
}

resource "aws_lambda_event_source_mapping" "inventory" {
  event_source_arn         = var.inventory_queue_arn
  function_name            = aws_lambda_function.inventory_worker.arn
  batch_size               = 10
  enabled                  = true
  function_response_types  = ["ReportBatchItemFailures"]
}