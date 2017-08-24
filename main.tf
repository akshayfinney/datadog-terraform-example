provider "datadog" {
  api_key = "${var.datadog_api_key}"
  app_key = "${var.datadog_app_key}"
}

variable "datadog_api_key" {}
variable "datadog_app_key" {}

variable "datadog_alert_footer" {
  default = <<EOF
{{#is_no_data}}Not receiving data{{/is_no_data}}
{{#is_alert}}@pagerduty{{/is_alert}}
{{#is_recovery}}@pagerduty-resolve{{/is_recovery}}
@slack-alerts
EOF
}

variable "trigger_by" {
  default = "{host,env}"
}

variable "disk_usage" {
  type = "map"

  default = {
    query = "max:system.disk.in_use"
    threshold = "85"
  }
}

resource "datadog_monitor" "disk_usage" {
  name  = "Disk usage high"
  query = "avg(last_5m):${var.disk_usage["query"]}{*} by ${var.trigger_by} * 100 > ${var.disk_usage["threshold"]}"
  type  = "metric alert"
  notify_no_data = true
  include_tags = true

  message = <<EOM
Disk usage high: {{value}}

${var.datadog_alert_footer}
EOM
}


variable "cpu_usage" {
  type = "map"

  default = {
    query = "avg:aws.ec2.cpuutilization"
    threshold = "85"
  }
}
resource "datadog_monitor" "cpu_usage" {
  name  = "CPU usage high"
  query = "avg(last_5m):${var.cpu_usage["query"]}{*} by ${var.trigger_by} > ${var.cpu_usage["threshold"]}"
  type  = "query alert"
  notify_no_data = true
  include_tags = true

  message = <<EOM
CPU usage high: {{value}}

${var.datadog_alert_footer}
EOM
}

resource "datadog_timeboard" "host_metrics" {
  title = "Host metrics"
  description = "Host level metrics: CPU, memory, disk, etc."
  read_only = true

  graph {
    title = "CPU usage"
    viz = "timeseries"
    autoscale = true

    request {
      q = "${var.cpu_usage["query"]}{*} by ${var.trigger_by}"
      aggregator = "avg"
      type = "line"
    }

    marker {
      value = "y > ${var.cpu_usage["threshold"]}"
      type = "error dashed"
    }
  }

  graph {
    title = "Disk usage"
    viz = "timeseries"
    autoscale = true

    request {
      q = "${var.disk_usage["query"]}{*} by ${var.trigger_by}"
      aggregator = "avg"
      type = "line"
    }

    marker {
      value = "y > ${var.disk_usage["threshold"]}"
      type = "error dashed"
    }
  }
}