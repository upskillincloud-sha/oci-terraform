variable "inst_var" {
  type = map(object({
    dev_display_name  = string
    dev_memory_in_gbs = string
    dev_ocpus         = string
    })
  )
}
