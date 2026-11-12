# Stack 1 of 3 — Labs 1–3 (Storage + VM and Hosts + Serverless)
# Independent of containers/ and kubernetes/. Destroy this stack without touching those.

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

variable "serverless_image" {
  type        = string
  default     = "python:3.9-bullseye"
  description = "Public Docker Hub image — no build/push."
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for Lab 2 VM and Hosts"
}

variable "repo_url" {
  type    = string
  default = "https://github.com/AstralJays/JaysWakeZone.git"
}

variable "repo_ref" {
  type    = string
  default = "main"
}

locals {
  data_dir = "${path.module}/../../../lab1-public-data"
  lab1_objects = {
    "exports/name-ssn-ccn.csv"   = { file = "name-ssn-ccn.csv", content_type = "text/csv" }
    "exports/name-ssn-dob.csv"   = { file = "name-ssn-dob.csv", content_type = "text/csv" }
    "exports/name-ccn-zip.csv"   = { file = "name-ccn-zip.csv", content_type = "text/csv" }
    "exports/name-dob-email.csv" = { file = "name-dob-email.csv", content_type = "text/csv" }
    "exports/customers.json"     = { file = "customers.json", content_type = "application/json" }
  }
  lab1_stores = {
    remediate = { short = "rem", cspm_loop = "remediate" }
    exception = { short = "exc", cspm_loop = "risk-accept" }
  }
  lab1_object_keys = {
    for pair in setproduct(keys(local.lab1_stores), keys(local.lab1_objects)) :
    "${pair[0]}|${pair[1]}" => {
      store_key    = pair[0]
      object_key   = pair[1]
      file         = local.lab1_objects[pair[1]].file
      content_type = local.lab1_objects[pair[1]].content_type
    }
  }
  cloud_init = <<-EOF
    #cloud-config
    package_update: true
    packages: [git, curl, ca-certificates]
    runcmd:
      - export REPO_URL='${var.repo_url}'
      - export REPO_REF='${var.repo_ref}'
      - git clone --depth 1 --branch "${var.repo_ref}" "${var.repo_url}" /tmp/jwz
      - chmod +x /tmp/jwz/scripts/install-app.sh
      - /tmp/jwz/scripts/install-app.sh
  EOF
  lab3_boot  = <<-BOOT
    set -e
    pip install --no-cache-dir flask==2.0.3 werkzeug==2.0.3
    cat >/tmp/jwz_app.py <<'PY'
    from flask import Flask
    app = Flask(__name__)
    @app.route("/")
    def index():
        return {"status": "running", "demo": "cve-detection", "lab": "3-serverless"}
    @app.route("/health")
    def health():
        return {"ok": True}
    app.run(host="0.0.0.0", port=8080)
    PY
    exec python /tmp/jwz_app.py
  BOOT
}

resource "azurerm_resource_group" "main" {
  name     = "${var.name_prefix}-rg"
  location = var.location
  tags = {
    Project = "JaysWakeZone"
    Stack   = "labs-1-3"
  }
}

# --- Lab 1 ---

resource "random_string" "suffix" {
  for_each = local.lab1_stores
  length   = 6
  special  = false
  upper    = false
}

resource "azurerm_storage_account" "lab1" {
  for_each                        = local.lab1_stores
  name                            = substr(replace("${var.name_prefix}${each.value.short}${random_string.suffix[each.key].result}", "-", ""), 0, 24)
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  allow_nested_items_to_be_public = true

  tags = {
    Project     = "JaysWakeZone"
    Stack       = "labs-1-3"
    Lab         = "1"
    CspmLoop    = each.value.cspm_loop
    DemoFinding = "public-blob-container"
    DataClass   = "synthetic-pii"
  }
}

resource "azurerm_storage_container" "lab1" {
  for_each              = local.lab1_stores
  name                  = "exports"
  storage_account_name  = azurerm_storage_account.lab1[each.key].name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "lab1_objects" {
  for_each               = local.lab1_object_keys
  name                   = trimprefix(each.value.object_key, "exports/")
  storage_account_name   = azurerm_storage_account.lab1[each.value.store_key].name
  storage_container_name = azurerm_storage_container.lab1[each.value.store_key].name
  type                   = "Block"
  source                 = "${local.data_dir}/${each.value.file}"
  content_type           = each.value.content_type
}

# --- Lab 2 — VM and Hosts ---

resource "azurerm_virtual_network" "main" {
  name                = "${var.name_prefix}-vnet"
  address_space       = ["10.40.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.40.1.0/24"]
}

resource "azurerm_public_ip" "lab2" {
  name                = "${var.name_prefix}-pip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "lab2" {
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
  name                = "${var.name_prefix}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab2.id
  }
}

resource "azurerm_network_interface_security_group_association" "lab2" {
  network_interface_id      = azurerm_network_interface.lab2.id
  network_security_group_id = azurerm_network_security_group.lab2.id
}

resource "azurerm_linux_virtual_machine" "lab2" {
  name                  = "${var.name_prefix}-vm"
  resource_group_name   = azurerm_resource_group.main.name
  location              = azurerm_resource_group.main.location
  size                  = "Standard_D2s_v5"
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.lab2.id]
  custom_data           = base64encode(local.cloud_init)

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
    Stack   = "labs-1-3"
    Lab     = "2"
    Track   = "VM-and-Hosts"
  }
}

# --- Lab 3 — App Service ---

resource "random_string" "lab3" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_service_plan" "lab3" {
  name                = "${var.name_prefix}-lab3-plan"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "B1"

  tags = {
    Project = "JaysWakeZone"
    Stack   = "labs-1-3"
    Lab     = "3"
  }
}

resource "azurerm_linux_web_app" "lab3" {
  name                = "${var.name_prefix}-lab3-${random_string.lab3.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.lab3.id
  https_only          = true

  site_config {
    always_on        = false
    app_command_line = local.lab3_boot
    application_stack {
      docker_image_name   = var.serverless_image
      docker_registry_url = "https://index.docker.io"
    }
  }

  app_settings = {
    WEBSITES_PORT = "8080"
  }

  tags = {
    Project = "JaysWakeZone"
    Stack   = "labs-1-3"
    Lab     = "3"
    Demo    = "serverless-tracer-candidate"
  }
}

output "lab1_remediate_storage_account" {
  description = "Fix this one (make private → reassess clear)"
  value       = azurerm_storage_account.lab1["remediate"].name
}

output "lab1_remediate_url" {
  value = "https://${azurerm_storage_account.lab1["remediate"].name}.blob.core.windows.net/exports/customers.json"
}

output "lab1_exception_storage_account" {
  description = "Leave public; whitelist / accept risk"
  value       = azurerm_storage_account.lab1["exception"].name
}

output "lab1_exception_url" {
  value = "https://${azurerm_storage_account.lab1["exception"].name}.blob.core.windows.net/exports/customers.json"
}

output "lab2_application_url" {
  value = "http://${azurerm_public_ip.lab2.ip_address}:8080/labs"
}

output "lab2_webmin_url" {
  value = "https://${azurerm_public_ip.lab2.ip_address}:10000"
}

output "lab2_webmin_credentials" {
  value = "admin / password"
}

output "lab2_public_ip" {
  value = azurerm_public_ip.lab2.ip_address
}

output "lab3_app_name" {
  value = azurerm_linux_web_app.lab3.name
}

output "lab3_app_url" {
  description = "App Service URL — SA installs tracer themselves"
  value       = "https://${azurerm_linux_web_app.lab3.default_hostname}"
}
