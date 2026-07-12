   module "prod_instance"{
 source = "/home/upskillinc/instance_codes/instance_module"
  env_display_name = "prod_instance"
  env_memory_in_gbs = "32"
  env_ocpus         = "2"
  }

