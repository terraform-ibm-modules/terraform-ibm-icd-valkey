terraform {
  # require 1.9 or later to make use of cross-object referencing for input variable validations
  #   more info: https://www.hashicorp.com/blog/terraform-1-9-enhances-input-variable-validations
  required_version = ">= 1.9.0"

  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 2.2.2, < 3.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1, < 1.0.0"
    }
  }
}
