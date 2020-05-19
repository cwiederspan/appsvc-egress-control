# App Service with VNET Integration and Egress Control

## Setup

```bash

# No need for remote state here
terraform init

# Run the plan to see the changes
terraform plan

# Test from Kudo command prompt
curl --connect-timeout 2 --max-time 6 https://cdw-powerappapi-20200317.azurewebsites.net/api/IpAddress

```
