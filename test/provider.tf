provider "oci" {
  auth             = "APIKey"
  tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaamfnmv4ola7zjuktdzg6xk3v4jc7aig4qq2t6pzjcrhzlyikiamra"
  user_ocid        = "ocid1.user.oc1..aaaaaaaaxkt6mvstx3yihhacw2xmhl3li2hq54lqmsuatxi5oxdpzc34x34a"
  fingerprint      = "11:58:77:66:f4:62:39:9c:cd:07:72:a3:8f:6e:34:11"
  private_key_path = "~/instance_codes/instance_module/priv.pem"
  region           = "eu-frankfurt-1"
}