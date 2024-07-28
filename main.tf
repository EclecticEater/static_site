# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
    
  }
}


# Create a resource group
resource "azurerm_resource_group" "tfresourcegroup" {
  name     = "tfresourcegroup"
  location = "East US"
}


# Create the static website and Storage Account

# Deploying from github actions to a static site is not a official function of Azure
# To potentially perform this deployment to the static site, I would need to import the Github provider and modify the workflow for Github actions with a SP and the name of the storage account.
# Since I want to avoid breaking what is already working, I'd rather not try and attempt to modify my github workflow (also it'd take a lot more time to do)

resource "azurerm_storage_account" "tfstorageacc" {
  name                     = "tfstorageacc"
  resource_group_name      = azurerm_resource_group.tfresourcegroup.name
  location                 = azurerm_resource_group.tfresourcegroup.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  static_website {
    index_document = "index.html"
  }
}




# Create the Cosmos DB and Table

resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

resource "azurerm_cosmosdb_account" "cosmosdb" {
  name                = "tf-cosmos-db-${random_integer.ri.result}"
  location            = azurerm_resource_group.tfresourcegroup.location
  resource_group_name = azurerm_resource_group.tfresourcegroup.name
  offer_type          = "Standard"

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = "eastus"
    failover_priority = 0
  }
}


resource "azurerm_cosmosdb_table" "cosmosdb_table" {
  name                = "cosmosdb_table"
  resource_group_name = azurerm_cosmosdb_account.cosmosdb.resource_group_name
  account_name        = azurerm_cosmosdb_account.cosmosdb.name
  throughput          = 400
}



# Create the Function App for connecting to the CosmosdB Table.

# From this article https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/app_service_source_control
# As of writing this configuration file source control from a GitHub repository for an Azure Function is not supported.
# The terraform for the Azure function is best-effort given this constraint along with being unable to set the needed environment variable

resource "azurerm_service_plan" "API_ASP" {
  name                = "API_ASP"
  resource_group_name = azurerm_resource_group.tfresourcegroup.name
  location            = azurerm_resource_group.tfresourcegroup.location
  os_type             = "Linux"
  sku_name            = "Y1"
}


resource "azurerm_linux_function_app" "resumeapi" {
  name                = "resumeapi"
  resource_group_name = azurerm_resource_group.tfresourcegroup.name
  location            = azurerm_resource_group.tfresourcegroup.location
  service_plan_id     = azurerm_service_plan.API_ASP.id
  # Pretty sure for my live deployment that I am using a different storage account for the function app than the static site
  storage_account_name       = azurerm_storage_account.tfstorageacc.name
  storage_account_access_key = azurerm_storage_account.tfstorageacc.primary_access_key
  
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"

    # I have tried a local value and the below configuration, but terraform validate does not seem to like this attribute
    # even if it is valid: https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_account
    
    # "CONNECTION_STRING"          =  azurerm_cosmosdb_account.cosmosdb.primary_sql_connection_string
  }
  site_config {}
}

resource "azurerm_function_app_function" "resumeapifunction" {
  name            = "resumeapifunction"
  function_app_id = azurerm_linux_function_app.resumeapi.id
  language        = "Python"

  config_json = jsonencode({
    "bindings" = [
      {
        "authLevel" = "function"
        "direction" = "in"
        "methods" = [
          "get",
          "post",
        ]
        "name" = "req"
        "type" = "httpTrigger"
      },
      {
        "direction" = "out"
        "name"      = "$return"
        "type"      = "http"
      },
    ]
  })
}



# Create CDN

resource "azurerm_cdn_profile" "cdn_profile" {
  name                = "cdn_profile"
  location            = azurerm_resource_group.tfresourcegroup.location
  resource_group_name = azurerm_resource_group.tfresourcegroup.name
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "cdn_endpoint" {
  name                = "cdn_endpoint"
  profile_name        = azurerm_cdn_profile.cdn_profile.name
  location            = azurerm_resource_group.tfresourcegroup.location
  resource_group_name = azurerm_resource_group.tfresourcegroup.name

  origin {
    name      = "tf_cdn_origin"
    host_name = azurerm_storage_account.tfstorageacc.primary_web_endpoint
  }
}

# DNS is managed my a third-party domain registrar, so do not need to configure DNS Zone and Cname record here

resource "azurerm_cdn_endpoint_custom_domain" "custom_domain" {
  name            = "customdomain"
  cdn_endpoint_id = azurerm_cdn_endpoint.cdn_endpoint.id
  host_name       = "resume.cyberpops.pro"
}
