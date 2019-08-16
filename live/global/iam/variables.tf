variable "user_names" {
	description = "create IAM users with these names"
	type = list(string)
	default = ["jon", "jaynee", "sammy"]
}
