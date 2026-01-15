#  Flask & Express Deployment on AWS EC2 using Terraform

This project demonstrates **Part 2: Deploy Flask and Express on Separate EC2 Instances** using **Terraform** on **Amazon Linux**.

The goal is to provision infrastructure automatically and deploy:

*  **Flask Backend** on one EC2 instance
*  **Express Frontend** on another EC2 instance

Both services communicate securely over a private network while remaining publicly accessible on their own ports.

---

##  Architecture Overview

```
User (Browser)
   |
   |  Public IP :3000
   v
Express Frontend (EC2)
   |
   |  Private IP :5000
   v
Flask Backend (EC2)
```

---

##  Technologies Used

* **AWS EC2 (Amazon Linux 2)**
* **Terraform** (Infrastructure as Code)
* **Flask (Python Backend)**
* **Express (Node.js Frontend)**
* **Security Groups for controlled access**

---

##  Project Structure

```
project-root/
│── main.tf
│── variables.tf
│── backend-userdata.sh
│── frontend-userdata.sh
│── README.md
```

---

##  Security Groups Configuration

### Backend (Flask)

* Allows **port 5000** only from Frontend Security Group
* Allows **SSH (22)** from anywhere

### Frontend (Express)

* Allows **port 3000** from the internet
* Allows **SSH (22)** from anywhere

This ensures **secure service-to-service communication**.

---

##  Terraform Deployment Steps

### 1. Configure AWS Credentials

```bash
aws configure
```

Ensure you have permissions to create EC2, VPC, and Security Groups.

---

### 2. Initialize Terraform

```bash
terraform init
```

---

### 3. Review the Execution Plan

```bash
terraform plan
```

---

### 4. Deploy Infrastructure (First Deploy)

```bash
terraform apply
```

Type **yes** when prompted.

>  This is the **FIRST DEPLOY** — user data scripts run only at this time.

---

##  What Happens During First Deploy

### Backend EC2

* Amazon Linux boots
* Python & Flask installed
* Flask app starts on **port 5000**

### Frontend EC2

* Node.js installed
* Express app starts on **port 3000**
* Backend private IP injected automatically

---

##  Access the Application

###  Frontend (Public)

```
http://<FRONTEND_PUBLIC_IP>:3000
```

###  Backend (Internal Only)

```
http://<BACKEND_PRIVATE_IP>:5000/people
```

---

##  Redeploying Changes (Important)

User data scripts **DO NOT re-run automatically**.

To apply changes:

### Option 1: Recreate instances (Recommended)

```bash
terraform destroy
terraform apply
```

### Option 2: Recreate only one instance

```bash
terraform taint aws_instance.backend
terraform apply
```

---

##  Verification Commands

### SSH into instance

```bash
ssh -i key.pem ec2-user@<PUBLIC_IP>
```

### Check running services

```bash
ps aux | grep python
ps aux | grep node
```

### Check logs

```bash
cat backend.log
cat frontend.log
```

---

##  Expected Result

* Two EC2 instances running independently
* Flask backend reachable internally
* Express frontend accessible via browser
* Clean, automated, reproducible deployment

---

##  Key Takeaways

* **First deploy is critical** — userdata runs only once
* Terraform ensures **repeatable infrastructure**
* Separation of frontend & backend improves scalability
* Security groups control traffic cleanly

---

##  Conclusion

This setup represents a **production-style deployment** using best practices:

* Infrastructure as Code
* Service isolation
* Secure networking
* Automated provisioning

You now have a **fully working Flask + Express deployment on AWS EC2 using Terraform** 

---

