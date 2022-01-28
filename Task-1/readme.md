File Structure
Task1-/
├── main.tf
├── network.tf
├── web.tf
├── app.tf
├── database.tf
├── outputs.tf
└── variables.tf
└── env/
    └──dev.tfvars

Terraform is used for creating the infrastructure as code
Region used for the Solution ap-southeast-1 and 2 Availability zones were used for high HA.
Profile is being used fro location %USERPROFILE%\.aws\config and %USERPROFILE%\.aws\credentials

Load balancing is enabled in Web layer (External, exposed to internet) and Application Layer (Internal. private only)
Health check is enabled on port 80 for both load balancer.

App servers and web servers are hosted in Private subnets.

Autoscaling is in place for both Web layer and Application Layer.
Scale out and in policy is set based on CPU utilization

Database engine is Postgres and configured as Multi AZ

Solution is built keeping HA, Scalability, Security, Performance and cost.


terraform plan -var-file=env/dev.tfvars
terraform apply -var-file=env/dev.tfvars
