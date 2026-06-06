Description of Terraform project:

Since this is not yet complete, I will currently explain the features of it here for quick reference:

- Networking:
	* 4 subnets under a VPC (2 public and 2 private)
	* IGW and NATGW
	* Public subnets having routing associations with the main route table to the IGW
	* Private subnets having routing associations with the private route table to the NATGW

