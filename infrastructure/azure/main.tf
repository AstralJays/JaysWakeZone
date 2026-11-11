terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "name_prefix" {
  type    = string
  default = "jayswakezone"
}

variable "enable_lab1" {
  type    = bool
  default = true
}

variable "enable_lab2" {
  type    = bool
  default = true
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "ssh_public_key" {
  type        = string
  default     = ""
  description = "SSH public key for the Lab 2 VM (required when enable_lab2=true)"
}

variable "repo_url" {
  type    = string
  default = "https://github.com/AstralJays/JaysWakeZone.git"
}

variable "repo_ref" {
  type    = string
  default = "main"
}

variable "upwind_client_id" {
  type      = string
  default   = ""
  sensitive = true
}

variable "upwind_client_secret" {
  type      = string
  default   = ""
  sensitive = true
}

variable "upwind_agent_extra_config" {
  type    = string
  default = "scanner-v2=true"
}

locals {
  data_dir = "${path.module}/../../lab1-public-data"
  lab1_objects = {
    "exports/name-ssn-ccn.csv"   = { file = "name-ssn-ccn.csv", content_type = "text/csv" }
    "exports/name-ssn-dob.csv"   = { file = "name-ssn-dob.csv", content_type = "text/csv" }
    "exports/name-ccn-zip.csv"   = { file = "name-ccn-zip.csv", content_type = "text/csv" }
    "exports/name-dob-email.csv" = { file = "name-dob-email.csv", content_type = "text/csv" }
    "exports/customers.json"     = { file = "customers.json", content_type = "application/json" }
  }
  needs_network = var.enable_lab2
}

resource "azurerm_resource_group" "main" {
  name     = "${var.name_prefix}-rg"
  location = var.location
  tags     = { Project = "JaysWakeZone" }
}

# ---------------------------------------------------------------------------
# Lab 1 — public Blob container with synthetic PII
# ---------------------------------------------------------------------------

resource "azurerm_storage_account" "lab1" {
  count                    = var.enable_lab1 ? 1 : 0
  name                     = substr(replace("${var.name_prefix}pii${random_string.suffix[0].result}", "-", ""), 0, 24)
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = true

  tags = {
    Project     = "JaysWakeZone"
    Lab         = "1"
    DemoFinding = "public-blob-container"
    DataClass   = "synthetic-pii"
  }
}

resource "random_string" "suffix" {
  count   = var.enable_lab1 ? 1 : 0
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_container" "lab1" {
  count                 = var.enable_lab1 ? 1 : 0
  name                  = "exports"
  storage_account_name  = azurerm_storage_account.lab1[0].name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "lab1_objects" {
  for_each = var.enable_lab1 ? local.lab1_objects : {}

  name                   = trimprefix(each.key, "exports/")
  storage_account_name   = azurerm_storage_account.lab1[0].name
  storage_container_name = azurerm_storage_container.lab1[0].name
  type                   = "Block"
  source                 = "${local.data_dir}/${each.value.file}"
  content_type           = each.value.content_type
}

# ---------------------------------------------------------------------------
# Lab 2 — DVWA-lite on Azure VM (Docker)
# ---------------------------------------------------------------------------

resource "azurerm_virtual_network" "main" {
  count               = local.needs_network ? 1 : 0
  name                = "${var.name_prefix}-vnet"
  address_space       = ["10.40.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  count                = local.needs_network ? 1 : 0
  name                 = "default"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main[0].name
  address_prefixes     = ["10.40.1.0/24"]
}

resource "azurerm_public_ip" "lab2" {
  count               = var.enable_lab2 ? 1 : 0
  name                = "${var.name_prefix}-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "lab2" {
  count               = var.enable_lab2 ? 1 : 0
  name                = "${var.name_prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "App"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Webmin"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "10000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "lab2" {
  count               = var.enable_lab2 ? 1 : 0
  name                = "${var.name_prefix}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab2[0].id
  }
}

resource "azurerm_network_interface_security_group_association" "lab2" {
  count                     = var.enable_lab2 ? 1 : 0
  network_interface_id      = azurerm_network_interface.lab2[0].id
  network_security_group_id = azurerm_network_security_group.lab2[0].id
}

locals {
  cloud_init = <<-EOF
    #cloud-config
    package_update: true
    packages: [git, curl, ca-certificates]
    runcmd:
      - export REPO_URL='${var.repo_url}'
      - export REPO_REF='${var.repo_ref}'
      - export UPWIND_CLIENT_ID='${var.upwind_client_id}'
      - export UPWIND_CLIENT_SECRET='${var.upwind_client_secret}'
      - export UPWIND_AGENT_EXTRA_CONFIG='${var.upwind_agent_extra_config}'
      - git clone --depth 1 --branch "${var.repo_ref}" "${var.repo_url}" /tmp/jwz
      - chmod +x /tmp/jwz/scripts/install-app.sh /tmp/jwz/scripts/install-upwind-sensor.sh
      - /tmp/jwz/scripts/install-upwind-sensor.sh || true
      - /tmp/jwz/scripts/install-app.sh
  EOF
}

resource "azurerm_linux_virtual_machine" "lab2" {
  count               = var.enable_lab2 ? 1 : 0
  name                = "${var.name_prefix}-vm"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = "Standard_D2s_v5"
  admin_username      = var.admin_username
  network_interface_ids = [azurerm_network_interface.lab2[0].id]
  custom_data         = base64encode(local.cloud_init)

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    Project = "JaysWakeZone"
    Lab     = "2"
  }
}

output "lab1_storage_account" {
  value = var.enable_lab1 ? azurerm_storage_account.lab1[0].name : null
}

output "lab1_public_url" {
  value = var.enable_lab1 ? "https://${azurerm_storage_account.lab1[0].name}.blob.core.windows.net/exports/customers.json" : null
}

output "lab2_application_url" {
  value = var.enable_lab2 ? "http://${azurerm_public_ip.lab2[0].ip_address}:8080/labs" : null
}

output "lab2_webmin_url" {
  value = var.enable_lab2 ? "https://${azurerm_public_ip.lab2[0].ip_address}:10000" : null
}

output "lab2_webmin_credentials" {
  value = var.enable_lab2 ? "admin / password" : null
}

output "lab2_public_ip" {
  value = var.enable_lab2 ? azurerm_public_ip.lab2[0].ip_address : null
}
