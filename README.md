##### - set up vps in yandex cloud
##### - start provisioner with ansible which performs deployment jenkins
##### - creates A-record in AWS rout53 for public_ip vps

#### CHECK
```
cp terraform.tfvars.example terraform.tfvars

vim terraform.tfvars
...
Your credentilas
...
```

#### RUN
```
terraform plan
terraform apply -auto-approve 
```

