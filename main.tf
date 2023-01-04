
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

resource "yandex_vpc_subnet" "internal-b" {
  name           = "internal-b"
  zone           = "ru-central1-b"
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
  provisioner "local-exec" {
    command = <<EOT
        echo [servers] >> hosts.txt;
        echo vm-1 ansible_host=${yandex_compute_instance.vm-1.network_interface.0.nat_ip_address} >> hosts.txt
    EOT
  }
 

## Делает машину не прирываемой.
  scheduling_policy {
    preemptible = false 
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.internal-b.id
    nat       = true
  }

  metadata = {
    ssh-keys = "sergey:${file("~/.ssh/id_rsa.pub")}"
  }
}


## target_group
resource "yandex_lb_target_group" "tg-skillbox" {
  name      = "my-tg"
  region_id = "ru-central1"

  target {
    subnet_id = yandex_vpc_subnet.internal-b.id
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
## Create DNS zone
resource "yandex_dns_zone" "zone1" {
  name        = "my-public-zone"
  description = "desc"
  zone        = "welcomenews.tk."
  public      = true
}

### Создание DNS записи
resource "yandex_dns_recordset" "rs1" {
  zone_id = yandex_dns_zone.zone1.id
  name    = "test.welcomenews.tk."
  type    = "A"
  ttl     = 200
  data  = [yandex_compute_instance.vm-1.network_interface.0.nat_ip_address]
}

resource "null_resource" "start_ansible" {
  
  provisioner "local-exec" {
    command = "sleep 15"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -i hosts.txt -u ubuntu ansible/playbook.yml"
  }
  depends_on = [yandex_lb_network_load_balancer.lb-skillbox]
}

