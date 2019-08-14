output "address" {
	value = aws_db_instance.postgres_db.address
	description = "endpoint to connect to the database"
}

output "port" {
	value = aws_db_instance.postgres_db.port
	description = "port the database is listening on"
}
