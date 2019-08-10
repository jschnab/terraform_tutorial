provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "example" {
	ami =  "ami-02f706d959cedf892"
	instance_type = "t2.micro"

	tags {
		Name = "terraform-example"
	}
}
