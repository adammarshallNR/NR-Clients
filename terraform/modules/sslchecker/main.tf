variable "jobs" {
    type = map(object({
        name = string
        data = string
  }))
}
variable insertAPIKey { description = "New Relic Metrics API insert key" }
variable locations { description = "New Relic Locations to run from"}
variable nameSpace { 
    description = "Namespace for the app, usually SSLCHKR, provide a different one if deploying this app more than once to an account" 
    default="SSLCHKR"
}
variable frequency { 
    description = "Monitor runtime frequency"  
    default=60
}

module "SSLminion" {
    source = "./modules/sslminion"
    for_each = var.jobs
    name = each.value.name
    nameSpace = var.nameSpace
    targetDataJS = each.value.data
    frequency = var.frequency
    insertKeyName = "${var.nameSpace}_MetricInsertKey"
    insertKeyValue = var.insertAPIKey
    locations = var.locations
}


resource "newrelic_one_dashboard" "dashboard" {
  name = "SSL Certificate Checks (${var.nameSpace})"

  page {
    name = "SSL Certificate Checks (${var.nameSpace})"

    widget_markdown {
      title = ""
      row = 1
      column = 1
      width = 3
      height = 3

      text = "# SSL /TLS Certificate Dashboard ![New Relic logo](https://newrelic.com/static-assets/images/icons/avatar-newrelic.png)\nThis dashboard show the number of expired certficates to the right, with certificates expiring in less than 30 days and less than 90 days below.\nThe list of certificates is to the far right, ordered by the soonest to expire.\n\nThis dashboard, the custom metrics and the Scripted API Synthetic monitor are based on [this](https://github.com/newrelic-experimental/nr-bulk-ssl-checker) from the New Relic Experimental Repository."
    }

    widget_billboard {
      title = "Expired"
      row = 1
      column = 4
      width = 3
      height = 3

      nrql_query {
        query = "SELECT count(*) AS 'Certificates EXPIRED' from (From Metric select latest(SSLCHKR.state) as state where tool='SSLCHKR' AND SSLCHKR.state ='OVERDUE' facet SSLCHKR.name as name  limit max)"
      }

      critical = 1
    }

    widget_billboard {
      title = "Expiring in 30 Days"
      row = 4
      column = 1
      width = 3
      height = 3

      nrql_query {
        query = "SELECT count(*) AS 'Certificates Expiring in 30 Days' from (From Metric select latest(SSLCHKR.state) as state where tool='SSLCHKR' AND SSLCHKR.state ='CRITICAL' facet SSLCHKR.name as name  limit max)"
      }

      critical = 1
    }

    widget_billboard {
      title = "Expiring in 90 Days"
      row = 4
      column = 4
      width = 3
      height = 3

      nrql_query {
        query = "SELECT count(*) AS 'Certificates Expiring in 90 Days' from (From Metric select latest(SSLCHKR.state) as state where tool='SSLCHKR' AND SSLCHKR.state='WARNING' facet SSLCHKR.name as name  limit max)"
      }

      warning = 1
    }

    widget_billboard {
      title = "Next Expiring Certificate"
      row = 7
      column = 1
      width = 6
      height = 3

      nrql_query {
        query = "SELECT 0-latest(SSLCHKR.days) as 'Days until expire' from Metric where tool='SSLCHKR' since 1 hour ago limit 1 facet SSLCHKR.domain as 'Next Expiring Domain', SSLCHKR.expirationDate"
      }

      warning = -90
      critical = -30 
    }

    widget_pie {
      title = "Certificate States"
      row = 10
      column = 1
      width = 3
      height = 3

      nrql_query {
        query = "select count(*) from (From Metric select latest(${var.nameSpace}.state) as state where tool='${var.nameSpace}' facet ${var.nameSpace}.name as name  limit max) since 1 hour ago facet state"
      }
    }

    widget_pie {
      title = "Certificate Issuers"
      row = 10
      column = 4
      width = 3
      height = 3

      nrql_query {
        query = "SELECT count(*) as 'Issuers' from Metric where  tool='${var.nameSpace}'  since 1 hour ago limit max  facet ${var.nameSpace}.issuer "
      }
    }

    widget_line {
      title = "Error breakdown by day"
      row = 15
      column = 1
      width = 6
      height = 3

      nrql_query {
        query = "select count(*) from (From Metric select latest(${var.nameSpace}.state) as state facet SSLCHKR.name as name where ${var.nameSpace}.state!='OK' and tool='${var.nameSpace}' timeseries 1 day limit max) since 3 months ago facet state timeseries 1 day"
      }
    }

    widget_table {
      title = "Certificate Data"
      row = 1
      column = 7
      width = 6
      height = 17

      nrql_query {
        query = "SELECT 0-latest(${var.nameSpace}.days) as 'Days until expire', latest(${var.nameSpace}.state) as 'State', latest(${var.nameSpace}.expirationDate) as 'Expiration', latest(${var.nameSpace}.issuer) as 'Issuer' from Metric where tool='${var.nameSpace}' since 1 hour ago limit max facet ${var.nameSpace}.domain as 'Domain'"
      }
    }

    
    widget_table {
      title = "Monitor Summary"
      row = 13
      column = 1
      width = 6
      height = 2

      nrql_query {
        query = "SELECT latest(result), latest(custom.expectedTargets) as 'Targets',  latest(custom.criticalErrors) as 'Critical', latest(custom.warningErrors) as 'Warning', latest(custom.scriptErrors) as 'Error' from SyntheticCheck where monitorName like '${var.nameSpace}-%' facet monitorName "
      }
    }
  }
  
}