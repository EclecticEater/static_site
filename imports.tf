# This will likely work as an import file to the main config file if I rename some of my resources, 
# but the purpose of the main file was to remake the resources with different names and a different RG to prevent overwriting my project and require debugging
# The Azure provider doesn't support deployment from github. I might be able to by using the github provider and modifying the workflow.yml file, but it again will impact my working project if that file is modified

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure Providers
provider "azurerm" {
  features {}
}


import {
  to = azurerm_resource_group.tfresourcegroup
  id = "/subscriptions/e719e20e-9597-4ac5-a930-f10c25fd2678/resourceGroups/testing"
}

import {
  to = azurerm_storage_account.tfstorageacc
  id = "/subscriptions/e719e20e-9597-4ac5-a930-f10c25fd2678/resourceGroups/testing/providers/Microsoft.Storage/storageAccounts/jpopresume"
}

import {
  to = azurerm_cosmosdb_account.cosmosdb
  id = "/subscriptions/e719e20e-9597-4ac5-a930-f10c25fd2678/resourceGroups/testing/providers/Microsoft.DocumentDB/databaseAccounts/jpopresume"
}

import {
  to = azurerm_cosmosdb_table.cosmosdb_table
  id = "/subscriptions/e719e20e-9597-4ac5-a930-f10c25fd2678/resourceGroups/testing/providers/Microsoft.DocumentDB/databaseAccounts/jpopresume/tables/Visitors"
}

import {
  to = azurerm_service_plan.API_ASP
  id = "/subscriptions/e719e20e-9597-4ac5-a930-f10c25fd2678/resourceGroups/testing/providers/Microsoft.Web/serverFarms/ASP-testing-bc04"
}

import {
  to = azurerm_linux_function_app.resumeapi
  id = "/subscriptions/e719e20e-9597-4ac5-a930-f10c25fd2678/resourceGroups/testing/providers/Microsoft.Web/sites/jpopresumeapi"
}

import {
  to = azurerm_function_app_function.resumeapifunction
  id = "/subscriptions/e719e20e-9597-4ac5-a930-f10c25fd2678/resourceGroups/testing/providers/Microsoft.Web/sites/jpopresumeapi/functions/HttpTrigger1"
}

import {
  to = azurerm_cdn_profile.cdn_profile
  id = "/subscriptions/e719e20e-9597-4ac5-a930-f10c25fd2678/resourceGroups/testing/providers/Microsoft.Cdn/profiles/jpopresume"
}

import {
  to = azurerm_cdn_endpoint.cdn_endpoint
  id = "/subscriptions/e719e20e-9597-4ac5-a930-f10c25fd2678/resourceGroups/testing/providers/Microsoft.Cdn/profiles/jpopresume/endpoints/jpopresume"
}

import {
  to = azurerm_cdn_endpoint_custom_domain.custom_domain
  id = "/subscriptions/e719e20e-9597-4ac5-a930-f10c25fd2678/resourceGroups/testing/providers/Microsoft.Cdn/profiles/jpopresume/endpoints/jpopresume/customDomains/resume-cyberpops-pro"
}
