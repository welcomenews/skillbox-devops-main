# Выведем IP адресa сервера
output "internal_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.ip_address
}

output "external_ip_address_vm_1" {
  value = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}

output "lb_ip_address" {
#  value = yandex_lb_network_load_balancer.lb-skillbox.*
##   value = yandex_lb_network_load_balancer.lb-skillbox.*.listener[0].*.external_address_spec[0].*.address
   value = yandex_lb_network_load_balancer.lb-skillbox.listener.*.external_address_spec[0].*.address
}

