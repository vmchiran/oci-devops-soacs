data "oci_identity_availability_domain" "ad" {
  #Required
  compartment_id = oci_identity_compartment.soacs.id
  ad_number      = var.ad_number
}

data "oci_identity_availability_domain" "addr" {
  #Required
  compartment_id = oci_identity_compartment.soacs.id
  ad_number      = var.addr_number
}

data "oci_database_db_system_shapes" "soa_db_system_shapes" {
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = oci_identity_compartment.soacs.id

  filter {
    name   = "shape"
    values = [var.db_system_shape]
  }
}

# For object storage: read the object storage namespace
data "oci_objectstorage_namespace" "ns" {
}

# To route traffic bound for the Object Storage service through the service gateway 
data "oci_core_services" "all_oci_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}