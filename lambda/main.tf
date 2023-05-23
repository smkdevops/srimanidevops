data "aws_kms_key" "kms-validation" {
  count  = var.create_aws_lambda_function == true ? 1 : 0
  key_id = var.kms_key_arn
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  count = var.create_aws_lambda_function == true ? 1 : 0

  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.retention_in_days
  skip_destroy      = var.skip_destroy
  kms_key_id        = var.lambda_logs_kms_key_id
  tags              = var.tags
}

resource "aws_lambda_function" "lambda" {
  depends_on = [
    aws_cloudwatch_log_group.lambda_log_group
  ]
  count                   = var.create_aws_lambda_function == true ? 1 : 0
  function_name           = var.function_name
  filename                = lower(var.source_code_location) == "local" ? var.filename : null
  s3_bucket               = lower(var.source_code_location) == "s3" ? var.s3_bucket : null
  s3_key                  = lower(var.source_code_location) == "s3" ? var.s3_key : null
  s3_object_version       = lower(var.source_code_location) == "s3" ? var.s3_object_version : null
  description             = var.description
  handler                 = var.package_type != "Image" ? var.handler : null
  runtime                 = var.package_type != "Image" ? var.runtime : null
  timeout                 = var.timeout
  role                    = var.role
  image_uri               = lower(var.source_code_location) == "ecr" ? var.image_uri : null
  kms_key_arn             = data.aws_kms_key.kms-validation[0].id == null ? "The KMS key is not valid" : var.kms_key_arn
  source_code_hash        = lower(var.source_code_location) == "local" ? filebase64sha256(var.filename) : var.s3_key
  package_type            = lower(var.source_code_location) == "ecr" ? var.package_type : null
  architectures           = var.architectures
  code_signing_config_arn = var.code_signing_config_arn

  dynamic "vpc_config" {
    for_each = var.subnet_ids == [] ? [] : [1]
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  dynamic "image_config" {
    for_each = var.image_config != [] && lower(var.source_code_location) == "ecr" ? var.image_config : []
    content {
      entry_point       = lookup(image_config.value, "entry_point", null)
      command           = lookup(image_config.value, "command", null)
      working_directory = lookup(image_config.value, "working_directory", null)
    }
  }

  dynamic "environment" {
    for_each = length(var.lambda_environment) == 0 ? [] : [var.lambda_environment]
    content {
      variables = environment.value.variables
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_target_arn == "" ? [] : [1]
    content {
      target_arn = var.dead_letter_target_arn
    }
  }

  dynamic "tracing_config" {
    for_each = var.tracing_config_mode == "" ? [] : [1]
    content {
      mode = var.tracing_config_mode
    }
  }

  layers                         = var.package_type != "Image" ? (var.layers == [] ? null : var.layers) : null
  memory_size                    = var.memory_size
  reserved_concurrent_executions = var.reserved_concurrent_executions
  publish                        = var.publish

  dynamic "file_system_config" {
    for_each = var.file_system_config_arn == "" ? [] : [1]
    content {
      arn              = var.file_system_config_arn
      local_mount_path = var.local_mount_path
    }
  }

  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage
    content {
      size = lookup(ephemeral_storage.value, "size", null)
    }
  }

  tags = var.tags
}
