terraform {

  required_version = ">= 1.4.0"

  required_providers {
    opentelekomcloud = {
      source  = "opentelekomcloud/opentelekomcloud"
      version = ">=1.32.0"
    }
    errorcheck = {
      source  = "iits-consulting/errorcheck"
      version = "3.0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">=4.0.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">=0.10.0"
    }
  }
}
