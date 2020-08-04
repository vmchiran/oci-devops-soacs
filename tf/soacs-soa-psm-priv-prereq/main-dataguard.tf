data "oci_database_db_homes" "primarydb_home" {
  #Required
  compartment_id = oci_identity_compartment.soacs.id
  #Optional
  db_system_id   = oci_database_db_system.soa_db_system.id
}

data "oci_database_databases" "primarydb" {
  #Required
  compartment_id = oci_identity_compartment.soacs.id
  #Optional
  db_home_id     = data.oci_database_db_homes.primarydb_home.db_homes[0].db_home_id
}

resource "oci_database_data_guard_association" "soa_dbdr_system" {
  #Required
  creation_type = "NewDbSystem"
  database_admin_password = var.db_admin_password
  database_id = data.oci_database_databases.primarydb.databases[0].id
  delete_standby_db_home_on_delete = "true"
  protection_mode = "MAXIMUM_PERFORMANCE"
  transport_type = "ASYNC"

  #Optional
  availability_domain = data.oci_identity_availability_domain.addr.name
  display_name = "${var.prefix}-${var.soa_dbdr_system_display_name}"
  hostname = var.dbdr_hostname
  subnet_id = oci_core_subnet.soa_public_subnet.id
}