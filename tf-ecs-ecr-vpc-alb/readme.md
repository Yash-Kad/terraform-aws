# AWS ECS Fargate Microservices Deployment Through Terraform (Flask + Express)

This repository contains the Infrastructure as Code (Terraform) and source code required to deploy a production-grade microservices architecture on AWS.

The architecture features a **Python Flask Backend** (data service) and a **Node.js Express Frontend** (UI service), orchestrated via **AWS ECS Fargate** and routed through a single **Application Load Balancer (ALB)**.

---

## Architecture Overview

The system is designed to allow the Frontend container to communicate securely with the Backend container via the Load Balancer. This approach circumvents common connectivity issues (such as `localhost` limitations) inherent in containerized environments.

### Traffic Flow
1.  **User Access:** The user navigates to the Application Load Balancer DNS URL via Port 80.
2.  **Frontend Routing:** The ALB routes the incoming request to the **Frontend Task** on Port 3000.
3.  **Internal API Call:** When data is required, the Frontend initiates an Axios request to the ALB DNS on Port 8000.
4.  **Backend Routing:** The ALB accepts the request on Port 8000 and forwards it to the **Backend Task** on Port 8000.
5.  **Response:** The Flask application serves the `details.json` data, which returns through the load balancer to the user.

---

## Prerequisites

Before executing the deployment, ensure the following tools are installed and configured:

* **AWS CLI:** Configured with valid credentials (`aws configure`).
* **Terraform:** Installed and initialized.
* **Docker Desktop:** Running (required for building images).
* **Git:** Required to clone the repository.

---

## Deployment Guide

To prevent "Image Not Found" errors during the initial provision, this project utilizes a "Two-Pass" deployment strategy: **Repository Creation** followed by **Service Deployment**.

### Step 1: Create ECR Repositories

The Elastic Container Registry (ECR) repositories must exist before Docker images can be pushed.


#### Initialize Terraform
`terraform init`

#### Apply ONLY the ECR resources first
`terraform apply -target=aws_ecr_repository.backend -target=aws_ecr_repository.frontend -auto-approve
`

Rationale: ECS Tasks will fail to start if the referenced Docker images do not exist in the registry.

### Step 2: Build and Push Docker Images

Retrieve the ECR repository URLs from the Terraform output or the AWS Console, then authenticate and push the images.

#### 1. Login to ECR

` aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin <YOUR_ACCOUNT_ID>.dkr.ecr.ap-south-1.amazonaws.com`

##### 2. Build & Push Backend

` cd backend
docker build -t flask-backend .
docker tag flask-backend:latest <YOUR_ACCOUNT_ID>[.dkr.ecr.ap-south-1.amazonaws.com/flask-backend:latest](https://.dkr.ecr.ap-south-1.amazonaws.com/flask-backend:latest)
docker push <YOUR_ACCOUNT_ID>[.dkr.ecr.ap-south-1.amazonaws.com/flask-backend:latest](https://.dkr.ecr.ap-south-1.amazonaws.com/flask-backend:latest)
cd ..`

#### 3. Build & Push Frontend

`cd frontend
docker build -t express-frontend .
docker tag express-frontend:latest <YOUR_ACCOUNT_ID>[.dkr.ecr.ap-south-1.amazonaws.com/express-frontend:latest](https://.dkr.ecr.ap-south-1.amazonaws.com/express-frontend:latest)
docker push <YOUR_ACCOUNT_ID>[.dkr.ecr.ap-south-1.amazonaws.com/express-frontend:latest](https://.dkr.ecr.ap-south-1.amazonaws.com/express-frontend:latest)
cd ..`

### Step 3: Full Infrastructure Deployment
Once the images are successfully uploaded to AWS, deploy the remaining infrastructure (Networking, ALB, and ECS Tasks).

` terraform apply -auto-approve`

Note: It takes approximately 3-5 minutes for Fargate tasks to provision, register, and pass initial health checks. Output: Terraform will display the alb_dns_name. Use this URL to access the application.

Key Configurations
The following configurations address specific challenges encountered during the development of microservices on ECS.

####    1. The "Localhost" Resolution
Problem: Containers within ECS cannot communicate using localhost or 127.0.0.1 as they run in isolated contexts.

Solution: The Load Balancer's DNS name is injected into the Frontend container as an environment variable.

Code: value = "http://${aws_lb.main.dns_name}:8000/people"

Why: This routes internal traffic out to the ALB and back to the Backend Service correctly.

####    2. Security Group Chaining
Problem: Allowing traffic from 0.0.0.0/0 is insecure, while blocking all traffic causes timeouts.

Solution: Security Group Referencing.

ALB Security Group: Allows Inbound HTTP (80) and Custom TCP (8000).

Task Security Group: Allows Inbound on ports 3000 and 8000 only from the ALB Security Group.

Why: This enforces the principle of least privilege, ensuring containers only accept traffic from the Load Balancer, effectively eliminating 504 Gateway Timeouts.

####   3. Health Check Grace Periods
Problem: Fargate tasks can take over 60 seconds to initialize. If the ALB checks health immediately, the task fails and enters a restart loop (503 Service Unavailable).

Solution: health_check_grace_period_seconds = 180

Why: This pauses health checks for 3 minutes, allowing the application server (Gunicorn/Node.js) sufficient time to boot.

####    4. Logging Configuration
Feature: The awslogs driver is enabled in the task definition.

Benefit: Application logs (stdout/stderr) are streamed directly to CloudWatch (/ecs/frontend-task). This is essential for debugging internal application errors.

###    Cleanup
To prevent ongoing AWS costs, destroy the infrastructure when it is no longer needed.

`terraform destroy -auto-approve`

Note: If the deletion process hangs on the Security Group, ensure all Load Balancers and ECS Services have been fully deleted first.

