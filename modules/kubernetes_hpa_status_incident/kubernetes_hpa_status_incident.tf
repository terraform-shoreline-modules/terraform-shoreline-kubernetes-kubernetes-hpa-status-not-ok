resource "shoreline_notebook" "kubernetes_hpa_status_incident" {
  name       = "kubernetes_hpa_status_incident"
  data       = file("${path.module}/data/kubernetes_hpa_status_incident.json")
  depends_on = [shoreline_action.invoke_resource_availability_check,shoreline_action.invoke_hpa_verification,shoreline_action.invoke_get_hpa_status,shoreline_action.invoke_check_metrics]
}

resource "shoreline_file" "resource_availability_check" {
  name             = "resource_availability_check"
  input_file       = "${path.module}/data/resource_availability_check.sh"
  md5              = filemd5("${path.module}/data/resource_availability_check.sh")
  description      = "Insufficient resources available in the cluster to support the desired number of pods."
  destination_path = "/agent/scripts/resource_availability_check.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "hpa_verification" {
  name             = "hpa_verification"
  input_file       = "${path.module}/data/hpa_verification.sh"
  md5              = filemd5("${path.module}/data/hpa_verification.sh")
  description      = "Verify that the HPA is correctly configured for the deployment or stateful set in question, and that the minimum and maximum number of pods are set appropriately."
  destination_path = "/agent/scripts/hpa_verification.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "get_hpa_status" {
  name             = "get_hpa_status"
  input_file       = "${path.module}/data/get_hpa_status.sh"
  md5              = filemd5("${path.module}/data/get_hpa_status.sh")
  description      = "Check the metrics used by the HPA to determine whether to scale up or down the number of pods. Ensure that the metrics are correctly defined and that they reflect the actual resource utilization of the pods."
  destination_path = "/agent/scripts/get_hpa_status.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_file" "check_metrics" {
  name             = "check_metrics"
  input_file       = "${path.module}/data/check_metrics.sh"
  md5              = filemd5("${path.module}/data/check_metrics.sh")
  description      = "If the metrics are not available or not working as expected, consider using alternative metrics to determine scaling. For example, you can use custom metrics or metrics from external monitoring systems."
  destination_path = "/agent/scripts/check_metrics.sh"
  resource_query   = "host"
  enabled          = true
}

resource "shoreline_action" "invoke_resource_availability_check" {
  name        = "invoke_resource_availability_check"
  description = "Insufficient resources available in the cluster to support the desired number of pods."
  command     = "`chmod +x /agent/scripts/resource_availability_check.sh && /agent/scripts/resource_availability_check.sh`"
  params      = ["DEPLOYMENT_NAME","NAMESPACE","MAX_PODS"]
  file_deps   = ["resource_availability_check"]
  enabled     = true
  depends_on  = [shoreline_file.resource_availability_check]
}

resource "shoreline_action" "invoke_hpa_verification" {
  name        = "invoke_hpa_verification"
  description = "Verify that the HPA is correctly configured for the deployment or stateful set in question, and that the minimum and maximum number of pods are set appropriately."
  command     = "`chmod +x /agent/scripts/hpa_verification.sh && /agent/scripts/hpa_verification.sh`"
  params      = ["RESOURCE_NAME","RESOURCE_TYPE","NAMESPACE","CLUSTER_NAME"]
  file_deps   = ["hpa_verification"]
  enabled     = true
  depends_on  = [shoreline_file.hpa_verification]
}

resource "shoreline_action" "invoke_get_hpa_status" {
  name        = "invoke_get_hpa_status"
  description = "Check the metrics used by the HPA to determine whether to scale up or down the number of pods. Ensure that the metrics are correctly defined and that they reflect the actual resource utilization of the pods."
  command     = "`chmod +x /agent/scripts/get_hpa_status.sh && /agent/scripts/get_hpa_status.sh`"
  params      = ["METRIC_THRESHOLD","NAMESPACE","HPA_NAME","METRIC_NAME"]
  file_deps   = ["get_hpa_status"]
  enabled     = true
  depends_on  = [shoreline_file.get_hpa_status]
}

resource "shoreline_action" "invoke_check_metrics" {
  name        = "invoke_check_metrics"
  description = "If the metrics are not available or not working as expected, consider using alternative metrics to determine scaling. For example, you can use custom metrics or metrics from external monitoring systems."
  command     = "`chmod +x /agent/scripts/check_metrics.sh && /agent/scripts/check_metrics.sh`"
  params      = ["DEPLOYMENT_NAME","NAMESPACE","METRIC_NAME"]
  file_deps   = ["check_metrics"]
  enabled     = true
  depends_on  = [shoreline_file.check_metrics]
}

