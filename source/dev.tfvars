aws_region      = "eu-west-1"
project_name    = "seera-cc"
db_name         = "seera-db"
db_user         = "user"
db_password     = "passw0rd"
ssh_public_key  = "./id_seera.pub"
ssh_private_key = "./id_seera"

extra_tags = {
  Owner       = "jonasdp"
  Terraform   = "true"
  Environment = "development"
  Consumer    = "seera"
}
