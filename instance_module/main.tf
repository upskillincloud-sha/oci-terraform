resource "oci_core_instance" "generated_oci_core_instance" {
  agent_config {
    is_management_disabled = "false"
    is_monitoring_disabled = "false"
    plugins_config {
      desired_state = "DISABLED"
      name          = "WebLogic Management Service"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Vulnerability Scanning"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Oracle Java Management Service"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "OS Management Hub Agent"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Management Agent"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Fleet Application Management Service"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Custom Logs Monitoring"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Compute RDMA GPU Monitoring"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Run Command"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Compute Instance Monitoring"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Compute HPC RDMA Auto-Configuration"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Compute HPC RDMA Authentication"
    }
    plugins_config {
      desired_state = "ENABLED"
      name          = "Cloud Guard Workload Protection"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Block Volume Management"
    }
    plugins_config {
      desired_state = "DISABLED"
      name          = "Bastion"
    }
  }
  availability_config {
    recovery_action = "RESTORE_INSTANCE"
  }
  availability_domain = "Xmsk:EU-FRANKFURT-1-AD-1"
  compartment_id      = "ocid1.compartment.oc1..aaaaaaaahcf6doaviuas5e57pk5gb6o6bpatolajtqidjg7eeo5k2qwn7wga"
  create_vnic_details {
    assign_ipv6ip             = "false"
    assign_private_dns_record = "true"
    assign_public_ip          = "false"
    subnet_id                 = "ocid1.subnet.oc1.eu-frankfurt-1.aaaaaaaalcwmbmwenfqcbkizxpx6d6sqvruaw7gcjt4xld6m27hiva4dncqq"
  }
  defined_tags = {
    "Hub-tags.Env" = "Test"
  }
  display_name = var.env_display_name
  instance_options {
    are_legacy_imds_endpoints_disabled = "true"
  }
  is_pv_encryption_in_transit_enabled = "true"
  metadata = {
    "ssh_authorized_keys" = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDLS3j19UVM+Ls15vrTJUaICdPyDu/LFlLhycSlMgZX1CJPUo9E07G5AG9WEcYIQ7kWb55brMiU5smH0vsKmpP5p7YHkC8CQui4nZPrLSYeF7pf+VdyT/wi+PFRC36QL8PL7q/LPnOM1RgscqopR6/SGr3V8jCKSNbkCQMM8rg/x7CA8+n4CtGq/Z1vGitjWt2lb0fpU+8yslCGyfh64D7wnZQeLL28bo3MH35PJGf4kDfjKex0YOifiC6qpFZf2SY6lV74MvVMr1eHQsrSX2NK/QsFqSr2vxys5jojAFoHiL6WuNmgw9pio3VpbylQeJf9L5CWSWqVVuUmxoQg4RVL ssh-key-2026-04-19"
  }
  platform_config {
    is_symmetric_multi_threading_enabled = "true"
    type                                 = "AMD_VM"
  }
  shape = "VM.Standard.E5.Flex"
  shape_config {
    memory_in_gbs = var.env_memory_in_gbs
    ocpus         = var.env_ocpus
  }
  source_details {
    source_id   = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaasp7mnywxja6iap2fefkbpgxx2o7zz27mhtqqjmuiuii3wc5f37eq"
    source_type = "image"
  }
}
