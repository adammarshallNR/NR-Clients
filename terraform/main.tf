variable "insertAPIKey" { description="A New Relic insert key for sending data to metrics API"}


module "SSLChecker" {
    source = "./modules/sslchecker"
    insertAPIKey = var.insertAPIKey
    locations = ["AF-SOUTH-1"] //set the AWS region(s) you want it to run 
    frequency = 60
    jobs = {
        # Small example

        one = {
            name = "Static External Domains",
            data = file("${path.module}/targetdata/static_large.js")
        },


        # Longer example to show batching in operation

        # two = {
        #     name = "Static targets (large)",
        #     data = file("${path.module}/targetdata/static_large.js")
        # },


        # API driven example

        # api = {
        #     name = "API Example",
        #     data = file("${path.module}/targetdata/api-driven.js")
        # }
    }

}