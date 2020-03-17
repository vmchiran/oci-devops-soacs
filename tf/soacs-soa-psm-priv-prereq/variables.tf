variable "prefix" {
  type        = string
  default     = "pref"
}

# Identity and access parameters
variable "tenancy_ocid" {
  type        = string
  description = "tenancy id"
}

variable "user_ocid" {
  type        = string
  description = "user ocid"
}

variable "compartment_ocid" {
  type        = string
  description = "compartment ocid"
}

variable "api_fingerprint" {
  description = "fingerprint of oci api private key"
}

variable "api_private_key_path" {
  description = "path to oci api private key"
}

variable "ssh_public_key_path" {
  description = "path to ssh public key"
}

# general oci parameters

variable "region" {
  # List of regions: https://docs.cloud.oracle.com/iaas/Content/General/Concepts/regions.htm
  description = "region"
  default     = "eu-frankfurt-1"
}

variable "ad_number" {
}

variable "compartment_name" {
}

# Networking parameters
variable "vcn_display_name" {
  type    = string
  default = "vcn-1"
}

variable "vcn_dns_label" {
  type    = string
  default = "vcn1"
}

variable "vcn_cidr" {
  type        = string
  description = "cidr block of VCN"
  default     = "10.0.0.0/16"
}

variable "subnet_public_cidr" {
  type        = string
  description = "cidr block of subnet"
  default     = "10.0.1.0/24"
}

variable "subnet_bastion_cidr" {
  type        = string
  description = "cidr block of subnet"
  default     = "10.0.1.0/24"
}

variable "subnet_private_cidr" {
  type        = string
  description = "cidr block of subnet"
  default     = "10.0.2.0/24"
}

variable "subnet_lb_private_cidr" {
  type        = string
  description = "cidr block of subnet"
  default     = "10.0.2.0/24"
}

# Object storage
variable "soa_bucket_name" {
}

# DBSystem 
variable "db_system_shape" {
  default = "VM.Standard2.1"
}

variable "db_system_edition" {
  default = "ENTERPRISE_EDITION"
}

variable "soa_db_system_display_name" {
}

variable "db_version" {
  default = "18.8.0.0"
}

variable "db_admin_password" {
  default = "BEstrO0ng_#12"
}

variable "soa_db1_name" {
}

variable "db_workload" {
  default = "OLTP"
}

variable "license_model" {
  default = "LICENSE_INCLUDED"
}

#Initial data storage size (in GB) must be one of [256, 512, 1024, 2048, 4096, 6144, 8192, 10240, 12288, 14336, 16384, 18432, 20480, 22528, 24576, 26624, 28672, 30720, 32768, 34816, 36864, 38912, 40960]
variable "data_storage_size_in_gb" {
  default = "256"
}

variable "soa_db_hostname" {
}

# Bastion
variable "imageocids" {
  type = map(string)

  default = {
    # https://docs.cloud.oracle.com/iaas/images/
    # E.g. CentOS-7-2020.02.22-0
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaahkaj2rzfdpruxajpy77gohgczstwhygsimohss2plkfslbbh4xfa"

    eu-amsterdam-1 = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaat32fvq5hsmbljrvy77gr2xel7i3l3oc6g3bcnnd6mimzz5jqa7ka"
  }
}

variable "bastion_name" {
  type        = string
  description = "compute name"
  default     = "mycompute"
}

variable "bastion_shape" {
  type        = string
  description = "compute shape"
  default     = "VM.Standard2.1"
}
