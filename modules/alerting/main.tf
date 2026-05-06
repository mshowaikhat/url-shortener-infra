# ---------------------------------------------------------------------------
# Alert policy: high 5xx error rate
# Fires when any Cloud Run revision returns more than error_rate_threshold
# 5xx responses per second, sustained for 5 minutes.
# ---------------------------------------------------------------------------

resource "google_monitoring_alert_policy" "error_rate" {
  project      = var.project_id
  display_name = "Cloud Run — High 5xx Error Rate"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "5xx req/s > ${var.error_rate_threshold} for 5 min"

    condition_threshold {
      filter = join(" AND ", [
        "resource.type=\"cloud_run_revision\"",
        "metric.type=\"run.googleapis.com/request_count\"",
        "metric.labels.response_code_class=\"5xx\"",
      ])

      comparison      = "COMPARISON_GT"
      threshold_value = var.error_rate_threshold
      # Condition must be true for this entire window before the alert fires.
      duration = "300s"

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.labels.service_name"]
      }
    }
  }

  notification_channels = var.notification_channel_ids

  alert_strategy {
    # Auto-close the incident after 7 days if it stops firing.
    auto_close = "604800s"
  }

  documentation {
    content = join("\n", [
      "## High 5xx Error Rate",
      "",
      "A Cloud Run service is returning more than **${var.error_rate_threshold} 5xx req/s**.",
      "",
      "**Immediate steps:**",
      "1. Check `/readyz` on the affected service — a 503 means Firestore is unreachable.",
      "2. Read recent logs: `gcloud run services logs read <service> --region=us-central1 --limit=100`",
      "3. Check the Cloud Run revision traffic split for a bad rollout.",
    ])
    mime_type = "text/markdown"
  }
}

# ---------------------------------------------------------------------------
# Alert policy: high p95 request latency
# Fires when the 95th-percentile request latency across Cloud Run revisions
# exceeds latency_p95_threshold_ms for 5 minutes.
# ---------------------------------------------------------------------------

resource "google_monitoring_alert_policy" "latency_p95" {
  project      = var.project_id
  display_name = "Cloud Run — High p95 Request Latency"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "p95 latency > ${var.latency_p95_threshold_ms}ms for 5 min"

    condition_threshold {
      filter = join(" AND ", [
        "resource.type=\"cloud_run_revision\"",
        "metric.type=\"run.googleapis.com/request_latencies\"",
      ])

      comparison      = "COMPARISON_GT"
      threshold_value = var.latency_p95_threshold_ms
      duration        = "300s"

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
        group_by_fields      = ["resource.labels.service_name"]
      }
    }
  }

  notification_channels = var.notification_channel_ids

  alert_strategy {
    auto_close = "604800s"
  }

  documentation {
    content = join("\n", [
      "## High p95 Request Latency",
      "",
      "Cloud Run p95 latency has exceeded **${var.latency_p95_threshold_ms}ms**.",
      "",
      "**Common causes:**",
      "- Firestore slow query or cold-start connection",
      "- Redis connection issue (redirect service falls back to Firestore on every request)",
      "- Container cold start (min_instances = 0 means the first request after idle is slow)",
      "",
      "**Immediate steps:**",
      "1. Check `/readyz` — a degraded Redis will increase latency.",
      "2. Check Cloud Trace for slow spans.",
      "3. Consider raising `min_instances` to eliminate cold starts.",
    ])
    mime_type = "text/markdown"
  }
}
