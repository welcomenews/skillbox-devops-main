## skillbox-devops-main

```
# Устанавливаем Terraform

# Откройте файл конфигурации Terraform CLI:
vim ~/.terraformrc

provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}


# Запуск
# terraform init
# terraform apply


# ansible-playbook -i hosts playbook.yml
```

========================================


https://habr.com/ru/post/683844/

https://itnan.ru/post.php?c=1&p=685062

https://habr.com/ru/post/685520/

https://the-devops.ru/practicum-yandex/практическая-работа-создаём-виртуал/

https://www.dmosk.ru/instruktions.php?object=terraform


https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/data-sources/datasource_compute_instance#ip_address
