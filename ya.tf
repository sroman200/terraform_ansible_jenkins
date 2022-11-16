terraform {
  required_providers {
  yandex = {
      source  = "yandex-cloud/yandex"
    }

  aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  required_version = ">= 0.13"
}

variable "cloud_id" {type=string} # авторизация yandex cloud
variable "folder_id" {type=string} # авторизация yandex cloud
variable "aws_access_key" {type=string} # авторизация aws
variable "aws_secret_key" {type=string} # авторизация aws
variable "path_file_private_key" {type=string} # private key
variable "path_file_public_key" {type=string} # public key
variable "zone_name"{type = string} # domain zone
variable "dns_name"{type = string} # dns name
variable "remote_vps_user"{type = string} # remote_user
variable "image_centos"{type = string} # id_image

provider "aws" {
    access_key  = var.aws_access_key
    secret_key  = var.aws_secret_key	
    region      = "us-east-1"
}

provider "yandex" {
  service_account_key_file = file("key.json")
  cloud_id=var.cloud_id
  folder_id=var.folder_id
  zone="ru-central1-a"
}


resource "yandex_compute_instance" "vm-1" {
  name        = "vm1"
  hostname    = var.dns_name
  platform_id = "standard-v1"
  zone        = "ru-central1-a"

  resources {
    cores  = 2
    memory = 4
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id=var.image_centos # remote-user = centos
      size      = 100
    }
  }

  network_interface {
    subnet_id = data.yandex_vpc_subnet.subnet-1.id
    nat=true
  }

  metadata = {
    ssh-keys = "${var.remote_vps_user}:${file(var.path_file_public_key)}"
  }
  
  labels = {
    task="jenkins"
  }
##----------------------------------PROVISIONER START-----------------------##
      provisioner "remote-exec" {
  
    inline = [ "sudo yum -y install python3"]

    connection {
      host        = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
      type        = "ssh"
      user        = var.remote_vps_user
      private_key = "${file(var.path_file_private_key)}"
    }
 }
  provisioner "local-exec" {
    command = "ansible-playbook -u ${var.remote_vps_user} -i '${yandex_compute_instance.vm-1.network_interface.0.nat_ip_address},' --private-key ${var.path_file_private_key} env.yml"
  }
##----------------------------------PROVISIONER END------------------------##
    
}

data "yandex_vpc_network" "network-1" {
  name = "default"
}
data "yandex_vpc_subnet" "subnet-1" {
  name = "default-ru-central1-a"
}


// take id_zone from var.zone_name
data "aws_route53_zone" "selected" {
    name  = "${var.zone_name}."
}

resource "aws_route53_record" "web_vs_dns"{
  zone_id   = data.aws_route53_zone.selected.zone_id
  name      = var.dns_name 
  type      = "A"
  ttl       = "300"
  records   = [yandex_compute_instance.vm-1.network_interface.0.nat_ip_address]
}

output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}
