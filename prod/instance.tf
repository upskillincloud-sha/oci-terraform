module "prod_instance" {
  source            = "../instance_module"
  env_display_name  = "prod_instance"
  env_memory_in_gbs = "32"
  env_ocpus         = "2"
}

