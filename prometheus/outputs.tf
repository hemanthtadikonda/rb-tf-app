output "prometheus_ip" {
  value = "${aws_instance.main.private_ip}/32"
}