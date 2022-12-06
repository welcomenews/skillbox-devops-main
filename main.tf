## Yandex.Cloud
variable "yc_token" {
  type        = string
  description = "Yandex Cloud API key"
}
variable "yc_region" {
  type        = string
  description = "Yandex Cloud Region (i.e. ru-central1-c)"
}
variable "yc_cloud_id" {
  type        = string
  description = "Yandex Cloud id"
}
variable "yc_folder_id" {
  type        = string
  description = "Yandex Cloud folder id"
}

# Provider
terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
      #version = ">= 0.13"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone      = var.yc_region
}

## network
resource "yandex_vpc_network" "internal" {
  name = "internal-2"
}

resource "yandex_vpc_subnet" "internal-c" {
  name           = "internal-c"
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.internal.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

## instance
resource "yandex_compute_instance" "vm-1" {
  name        = "skillbox-vm1"
  platform_id = "standard-v3"

  resources {
    # Данный параметр позволяет уменьшить производительность CPU и сильно
    # уменьшить затраты на инфраструктуру
    core_fraction = 20
    cores         = 2
    memory        = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8ciuqfa001h8s9sa7i"
      type     = "network-hdd"
      size     = 15
    }
  }

## Делает машину прирываемой.
  scheduling_policy {
    preemptible = true
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.internal-c.id
    nat       = true
  }

  metadata = {
    ssh-keys = "sergey:${file("~/.ssh/id_rsa.pub")}"
  }
}

# Выведем IP адресa сервера
output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.ip_address
}

output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}


## target_group
resource "yandex_lb_target_group" "tg-skillbox" {
  name      = "my-tg"
  region_id = "ru-central1"

  target {
    subnet_id = yandex_vpc_subnet.internal-c.id
    address   = yandex_compute_instance.vm-1.network_interface.0.ip_address
  }
}

##  load-balancer
resource "yandex_lb_network_load_balancer" "lb-skillbox" {
  name = "my-load-balancer"

  listener {
    name = "my-listener"
    port = 80
    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.tg-skillbox.id

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}

output "lb_ip_address" {
  value = yandex_lb_network_load_balancer.lb-skillbox.*
}
