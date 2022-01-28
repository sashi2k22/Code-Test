output "web_alb_endpoint" {
  value = aws_lb.web_alb.dns_name
}

output "app_alb_endpoint" {
  value = aws_lb.app_lb.dns_name
}

output "web_alb_name" {
  value = aws_lb.web_alb.name
}

output "app_alb_name" {
  value = aws_lb.app_lb.name
}

output "database_name" {
  value = aws_db_instance.db_postgres.name
}
