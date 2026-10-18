module "test_instance" {
  source            = "../instance_module"
  env_display_name  = "test_instance"
  env_memory_in_gbs = "32"
  env_ocpus         = "2"
}

