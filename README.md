# AWS Terraform Multi-Tier Infrastructure


A production-style AWS infrastructure project built with Terraform that demonstrates networking, load balancing, auto scaling, containerized deployments, monitoring/alerting, security, and CI/CD with Infrastructure as Code best practices.


## Architecture Diagram

![Architecture Diagram](./app/static/architecture-diagram.png)

Brief Architecture Rundown:

### Presentation Tier
- Route 53
- ACM Certificate
- Application Load Balancer (HTTP --> HTTPS redirect)
- Public Subnets across two Availability Zones

### Application Tier
- Auto Scaling Group (2-4 EC2 instances) across private subnets in two AZs
- Launch Template (Amazon Linux 2023, t3.micro)
- Dockerized Flask app (Gunicorn) pulled from ECR and run on each instance via user data
- Target tracking scaling policy (60% average CPU)

### Data Tier
- DynamoDB table (linkedin user-handles / contact form submissions)
- DynamoDB Gateway VPC Endpoint (private-subnet access without NAT/internet)

### Container Registry
- ECR repository (portfolio-app) with scan-on push enabled
- Instances authenticate via IAM instance profile and pull the latest image on boot

### Monitoring & Alerting
- CloudWatch Agent on each instances (cloud-init logs; container/app logs as configured)
- CloudWatch Alarms: high ASG CPU utilization, unhealthy ALB targets
- SNS topic with email subscription for alarm notifications
- CloudWatch Dashboard for ASG CPU and instance count

### CI/CD
- GitHub Actions
- OIDC Authentication (no long-term AWS credentials)
- Terraform fmt, init, plan, validate on push/PR
- Automatic terraform apply on merge to main



Infrastructure Details:


- Networking
	* 4 subnets under a VPC (2 public and 2 private) across two Availability Zones
	* IGW and NATGW
	* Public subnets route to the IGW via the main route table
	* Private subnets route to the NATGW via the private route table
	* DynamoDB Gateway Endpoint attached to the private route table

- Frontend
	* ALB deployed across both public subnets
	* Security Group allows inbound HTTP/HTTPS and all outbound traffic
	* R53 record points the domain at the ALB
	* ACM certificate secures HTTPS
	* ALB listener redirects HTTP to HTTPS; HTTPS listener forwards to the target group
	* Target group performs health checks and routes traffic to ASG instances on port 80

- Application
	* Auto Scaling Group (min 2, max 4, desired 2) spans both private subnets
	* Instances launched from a shared Launch Template (latest Amazon Linux AMI, t3.micro)
	* On boot, each instance installs Docker, authenticates to ECR, and pulls/runs the portfolio-app container
	* Container runs a Flask app (via Gunicorn) on port 5000, mapped to host port 80
	* Flask app (boto3) handles a contact form submission and writes entries to DynamoDB
	* IAM instance profile grants:
		* DynamoDB read/write (GetItem, PutItem, UpdateItem, Query, DescribeTable)
		* SSM Managed Instance Core (for Session Manager access, no SSH needed)
		* CloudWatch Agent Server Policy (for log/metric shipping)
	* Security group allows inbound HTTP (80) from the ALB only, and all outbound traffic

- Database
	* DynamoDB table to store LinkedIn user-handles (name, LinkedIn, message, timestamp, UUID)
	* Pay-per-request, single-attribute hash ke
	* Reached privately from the ASG instances via a Gateway VPC Endpoint -- no internet egress required

- Monitoring & Alerting
	* CloudWatch Agent collects cloud-init logs into into dedicated log groups
	* High CPU alarm on the ASG (>80% over 2 periods) triggers SNS notification
	* Unhealthy target alarm on the ALB target group triggers SNS notification
	* SNS topic emails alerts to the project owner
	* Target tracking scaling policy automatically adjusts ASG capacity to maintain ~60% average CPU


Infrastructure Workflow:


1. Traffic Hits my domain (thomasbleckmandev.com)
2. Route 53 resolves to my IGW
3. IGW routes traffic towards my ALB listeners (if requested by HTTP --> redirect into HTTPS)
4. ALB Listener directs traffic towards ALB target group
5. Target group route traffic to a healthy ASG instance on port 80
6. The instance runs a Dcoker container (pulled from ECR on boot) serving the Flask app via Gunicorn on port 5000, mapped to host port 80
7. For contact form submissions, Flask writes the entry to DynamoDB via the Gateway VPC Endpoint
8. CloudWatch Agent ships logs/metrics; alarms notify via SNS if thresholds are breached
9. ASG scales in/out based on average CPU utilization
10. Response traffic returns through the ALB back to the user



CI/CD:

	* Utilizes Github Actions on pushes to test/main and PRs targeting main
	* OIDC for Github to access my remote backend (no stored secrets)
	* Pipeline runs terraform fmt -check, init, plan, and validate on every run
	* On merge to main, the pipeline automatically runs terraform apply -auto-approve


## Lessons I've Learned
- Importance of logging
	* While integrating Docker into my ASG to containerize my application, my instances were healthy, yet I couldn't connect to my website, its health subdomain, or use SSM to find the issue
	* From using the EC2 logs, however, I was able to identify that the issue was that the EC2 instances didn't have enough space to download Docker, and solve the issue from there (EC2 booting with an EBS volume)
	* Understood the importance of troubleshooting via logs
- Making a diagram to represent my infrastructure
	* A README just giving the workflows and infrastructure are important, but it does not give a first-time looker a holistic view of how the infrastructure welds together
	* Diagram accomplishes exactly that, reducing the time it takes for someone to understand my project, as well as making the worklfow of it easier to understand

Possible Next Steps
* Move from ASG to ECS/Fargate
* Structure flat .tf files into reusable modules (networking, frontend, application, data, monitoring)
* Add vairables.tf / outputs.tf to remove hardcoded values
* Update diagram to change static EC2 to ASG (or ECS/Fargate depending on when I complete that), SNS, CloudWatch, etc.