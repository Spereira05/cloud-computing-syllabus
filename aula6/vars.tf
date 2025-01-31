# variable "environment" {
#     description = "The environment to deploy the resources"
#     type = string

#     validation {
#         condition = contains(["dev", "beta", "prod"])
#         error_message = "The environment variable must be set"
#     }
# }