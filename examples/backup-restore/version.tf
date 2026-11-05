terraform {
  required_version = ">= 1.9.0"
  required_providers {
    # This example always uses the latest provider version within the range defined in the main module's version.tf
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 2.2.2, < 3.0.0"
    }
  }
}
