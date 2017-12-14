data "azurerm_subscription" "current" {}

data "azurerm_resource_group" "netRG" {
  name = "minschoNetRG"
}

data "azurerm_public_ip" "nic_ip" {
  name="ip0-pztosnpebhtt6"
  resource_group_name="${data.azurerm_resource_group.netRG.name}"
}

#data source에는 network interface가 없음. private ip는 어떻게 알아내지?
#data "azurerm_network_interface" "nic" {
#  name="${var.provisionedNicName}"
#  resource_group_name="${data.azurerm_resource_group.netRG.name}"
#}

output "public_ip" {
  value = "${data.azurerm_public_ip.nic_ip.ip_address}"
}

#private ip를 어떻게 알아낼까? 아래처럼 하면 안됨
#output "private_ip" {
#  value = "${azurerm_virtual_machine.vm0}"
#}

variable "provisionedNicName" {
    default = "vm0nic"
}

# variable 내에서 interpolation을 사용할 수 없다고 오류남
#variable "fullNicId" {
#    default = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.netRGName}/providers/Microsoft.Network/networkInterfaces/${var.provisionedNicName}"
#}

variable "vmName" {
}

variable "adminId" {
}

variable "adminKey" {
}

variable "targetRgName" {
    default = "minschoTfmRG01"
}

provider "azurerm" {
}

resource "azurerm_resource_group" "rg1" {
	name = "${var.targetRgName}"
	location = "koreacentral"
	tags {
	  environment = "terraform test"
	  department = "db실"
	}
}

resource "azurerm_managed_disk" "dummy" {
  name                 = "datadisk_dummy"
  location             = "${azurerm_resource_group.rg1.location}"
  resource_group_name  = "${azurerm_resource_group.rg1.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "10"
}

resource "azurerm_virtual_machine" "vm0" {
  name                  = "${var.vmName}"
  location              = "${azurerm_resource_group.rg1.location}"
  resource_group_name   = "${azurerm_resource_group.rg1.name}"
  network_interface_ids = ["/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${data.azurerm_resource_group.netRG.name}/providers/Microsoft.Network/networkInterfaces/${var.provisionedNicName}"]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "${var.vmName}-osDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.dummy.name}"
    managed_disk_id = "${azurerm_managed_disk.dummy.id}"
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = "${azurerm_managed_disk.dummy.disk_size_gb}"
  }

  os_profile {
    computer_name  = "${var.vmName}"
    admin_username = "${var.adminId}"
  }

  os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/${var.adminId}/.ssh/authorized_keys"
            key_data = "${var.adminKey}"
        }
  }

  tags {
    environment = "development"
  }
}