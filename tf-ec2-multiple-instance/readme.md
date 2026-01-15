# Multi-Tier Infrastructure Deployment (AWS EC2)

This repository contains **Infrastructure as Code (IaC)** written in **Terraform** to deploy a **decoupled, multi-tier web application** on AWS EC2. The architecture separates the **Backend API** and **Frontend UI** into independent instances within a secure **Virtual Private Cloud (VPC)**, following best practices for scalability, security, and maintainability.

---

##  Architecture Overview

The application is deployed across **two EC2 instances** communicating over the **AWS private network**:

### Backend Tier (API Layer)

* **Technology:** Python 3.12, Flask
* **Responsibility:** Serves a RESTful JSON API containing personnel data
* **Port:** 5000
* **Access:** Private VPC network (consumed by Frontend)

### Frontend Tier (UI Layer)

* **Technology:** Node.js 20, Express
* **Responsibility:** Consumes the Backend API and renders a dynamic HTML dashboard
* **Port:** 3000
* **Access:** Publicly accessible

This separation ensures **clear responsibility boundaries**, improved security, and easier future scaling.

---

##  Technology Stack

| Component        | Technology                      | Port     |
| ---------------- | ------------------------------- | -------- |
| Infrastructure   | Terraform                       | N/A      |
| Cloud Provider   | AWS (EC2, VPC, Security Groups) | N/A      |
| Operating System | Ubuntu 24.04 LTS                | 22 (SSH) |
| Backend API      | Python 3.12 / Flask             | 5000     |
| Frontend UI      | Node.js 20 / Express            | 3000     |

---

##  Repository Structure

```
.
├── main.tf              # Provider configuration and VPC setup
├── instances.tf         # EC2 definitions for Backend and Frontend
├── variables.tf         # Input variables (AMI, instance type, key pair)
├── terraform.tfvars     # User-specific configuration values
├── outputs.tf           # Public IPs and application endpoints
└── README.md            # Project documentation
```

---

##  Deployment Instructions

### 1. Prerequisites

Ensure the following are installed and configured:

* Terraform (latest stable version)
* AWS CLI configured with valid IAM credentials
* An existing AWS EC2 Key Pair (`.pem` file)

---

### 2. Initialize Terraform

```bash
terraform init
```

This downloads the required provider plugins and initializes the working directory.

---

### 3. Configure Variables

Update the `terraform.tfvars` file with your environment-specific values:

```hcl
key_name   = "your-key-pair-name"
aws_region = "ap-south-1"
```

>  **Note:** Do not commit sensitive information to version control.

---

### 4. Deploy Infrastructure

```bash
terraform apply -auto-approve
```

Terraform will provision the VPC, security groups, and EC2 instances automatically.

---

##  Post-Deployment Verification

After Terraform displays **"Apply complete"**, wait approximately **90 seconds** for the `user_data` scripts to finish installing dependencies and starting services.

### Access Endpoints

* **Backend API Health Check**
  `http://<backend-public-ip>:5000/api/names`

* **Frontend Web Dashboard**
  `http://<frontend-public-ip>:3000`

The Frontend communicates with the Backend using its **private IP**, ensuring secure internal traffic.

---

##  Troubleshooting

If the application is not accessible, connect to the EC2 instances via SSH:

```bash
ssh -i your-key.pem ubuntu@<instance-public-ip>
```

### Check Running Services

```bash
ps aux | grep node
ps aux | grep python
```

### View Application Logs

```bash
cat /home/ubuntu/frontend/app.log
cat /home/ubuntu/backend/app.log
```

Logs provide valuable insight into startup or runtime issues.

---

##  Security Considerations

* **VPC Isolation:** Backend services are accessed internally via private IPs
* **Security Groups:**

  * Inbound access limited to ports **22**, **3000**, and **5000**
  * For production use, restrict **SSH (22)** access to your IP address only
* **Principle of Least Privilege:** Ensure IAM credentials have minimal required permissions

---

##  Cleanup

To avoid unnecessary AWS charges, destroy all provisioned resources when no longer needed:

```bash
terraform destroy -auto-approve
```

This safely removes the EC2 instances, networking components, and associated resources.

---

## Summary

This project demonstrates a **production-style multi-tier deployment** using Terraform on AWS. It highlights:

* Clean separation of frontend and backend services
* Secure VPC-based communication
* Automated provisioning using Infrastructure as Code

This setup is ideal for learning, demonstrations, and as a foundation for more advanced cloud-native architectures.

---
