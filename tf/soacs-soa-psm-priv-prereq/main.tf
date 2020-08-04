# Create the SOACS Compartment
resource "oci_identity_compartment" "soacs" {
  #Required
  name           = "${var.prefix}-${var.compartment_name}"
  description    = "SOA PSM with 2-node cluster, Private Network and Public LB"
  #Parent compartment id
  compartment_id = var.compartment_ocid

  #Optional
  enable_delete = false
}

# Create the VCN
resource "oci_core_vcn" "vcn" {
  #Required
  cidr_block     = var.vcn_cidr
  compartment_id = oci_identity_compartment.soacs.id

  #Optional
  display_name = "${var.prefix}-${var.vcn_display_name}"
  dns_label    = "${var.prefix}${var.vcn_dns_label}"
}

resource "oci_core_internet_gateway" "ig" {
  #Required
  compartment_id = oci_identity_compartment.soacs.id
  vcn_id         = oci_core_vcn.vcn.id

  #Optional
  display_name = "${var.prefix}-ig"
}

# NAT gateway is required for the private node of the SOACS instance to access the public Internet
resource "oci_core_nat_gateway" "ng" {
  #Required
  compartment_id = oci_identity_compartment.soacs.id
  vcn_id         = oci_core_vcn.vcn.id

  #Optional
  display_name = "${var.prefix}-ng"
}

# The service gateway is required for the private node of the SOACS instance to access the Oracle Services, such as Object Storage
resource "oci_core_service_gateway" "sg" {
  #Required
  compartment_id = oci_identity_compartment.soacs.id
  vcn_id         = oci_core_vcn.vcn.id

  services {
    service_id = lookup(data.oci_core_services.all_oci_services.services[0], "id")
  }

  #Optional
  display_name   = "${var.prefix}-sg"
}

resource "oci_core_route_table" "public_route_table" {
  compartment_id = oci_identity_compartment.soacs.id
  vcn_id         = oci_core_vcn.vcn.id

  #Required
  route_rules {
    #Required
    network_entity_id = oci_core_internet_gateway.ig.id

    #Optional
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }

  #Optional
  display_name = "${var.prefix}-public-rt"
}

resource "oci_core_route_table" "private_route_table" {
  compartment_id = oci_identity_compartment.soacs.id
  vcn_id         = oci_core_vcn.vcn.id

  #Required
  route_rules {
    #Required
    network_entity_id = oci_core_nat_gateway.ng.id

    #Optional
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
  }

  route_rules {
    #Required
    network_entity_id = oci_core_service_gateway.sg.id

    #Optional
    destination       = lookup(data.oci_core_services.all_oci_services.services[0], "cidr_block")
    # destination       = "all-fra-services-in-oracle-services-network"
    destination_type  = "SERVICE_CIDR_BLOCK"
  }

  #Optional
  display_name = "${var.prefix}-private-rt"
}


# Protocols are specified as protocol numbers.
# http://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml

# Security List for the Load Balancer Subnet
resource "oci_core_security_list" "lb_security_list" {
  #Required
  compartment_id = oci_identity_compartment.soacs.id
  vcn_id         = oci_core_vcn.vcn.id

  #Optional
  display_name   = "${var.prefix}-lb-sl"

  // allow outbound tcp traffic on all ports
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  // allow inbound tcp traffic for HTTP 80
  ingress_security_rules {
    #Required
    protocol  = "6"   // tcp
    source    = var.vcn_cidr

    #Optional
    stateless = false

    tcp_options {
      // These values correspond to the destination port range.
      min = 80
      max = 80
    }
  }

  // allow inbound tcp traffic for HTTPS 443
  ingress_security_rules {
    #Required
    protocol  = "6"   // tcp
    source    = var.vcn_cidr

    #Optional
    stateless = false

    tcp_options {
      // These values correspond to the destination port range.
      min = 443
      max = 443
    }
  }
}

resource "oci_core_security_list" "wls_lb_security_list" {
  #Required
  compartment_id = oci_identity_compartment.soacs.id
  vcn_id         = oci_core_vcn.vcn.id

  #Optional
  display_name   = "${var.prefix}-wls-lb-sl"

  // allow inbound tcp traffic on 9073, for the wls managed
  ingress_security_rules {
    #Required
    protocol  = "6"   // tcp
    source    = var.subnet_lb_private_cidr

    #Optional
    stateless = false

    tcp_options {
      // These values correspond to the destination port range.
      min = 9073
      max = 9073
    }
  }
}

resource "oci_core_security_list" "internal_security_list" {
  #Required
  compartment_id = oci_identity_compartment.soacs.id
  vcn_id         = oci_core_vcn.vcn.id

  #Optional
  display_name   = "${var.prefix}-internal-sl"


  // allow inbound tcp traffic for the subnet
  ingress_security_rules {
    #Required
    protocol  = "6"   // tcp
    source    = var.subnet_private_cidr

    #Optional
    stateless = false
  }
}

resource "oci_core_security_list" "wls_security_list" {
  #Required
  compartment_id = oci_identity_compartment.soacs.id
  vcn_id         = oci_core_vcn.vcn.id

  #Optional
  display_name   = "${var.prefix}-wls-sl"

  // allow outbound tcp traffic on all ports
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  // allow inbound ssh traffic
  ingress_security_rules {
    #Required
    protocol  = "6"   // tcp
    source    = var.subnet_bastion_cidr

    #Optional
    stateless = false

    tcp_options {
      // These values correspond to the destination port range.
      min = 22
      max = 22
    }
  }

  // allow inbound tcp traffic on 7002, for wls admin
  ingress_security_rules {
    #Required
    protocol  = "6"   // tcp
    source    = var.vcn_cidr

    #Optional
    stateless = false

    tcp_options {
      // These values correspond to the destination port range.
      min = 7002
      max = 7002
    }
  }
}

# Security List for the Bastion Subnet
resource "oci_core_security_list" "bastion_security_list" {
  #Required
  compartment_id = oci_identity_compartment.soacs.id
  vcn_id         = oci_core_vcn.vcn.id

  #Optional
  display_name   = "${var.prefix}-bastion-sl"

  // allow outbound tcp traffic on all ports
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  // allow inbound ssh traffic
  ingress_security_rules {
    #Required
    protocol  = "6"   // tcp
    source    = "0.0.0.0/0"

    #Optional
    stateless = false

    tcp_options {
      // These values correspond to the destination port range.
      min = 22
      max = 22
    }
  }
}

resource "oci_core_subnet" "soa_bastion_subnet" {
  #Required
  cidr_block        = var.subnet_bastion_cidr
  compartment_id    = oci_identity_compartment.soacs.id
  vcn_id            = oci_core_vcn.vcn.id

  #Optional
  display_name    = "soa-bastion-subnet1"
  dhcp_options_id = oci_core_vcn.vcn.default_dhcp_options_id
  dns_label       = "soabastion1"
  route_table_id  = oci_core_route_table.public_route_table.id
  # security_list_ids = [oci_core_vcn.vcn.default_security_list_id, oci_core_security_list.security_list.id]
  security_list_ids = [oci_core_security_list.bastion_security_list.id]
}

resource "oci_core_subnet" "soa_lb_private_subnet" {
  #Required
  cidr_block        = var.subnet_lb_private_cidr
  compartment_id    = oci_identity_compartment.soacs.id
  vcn_id            = oci_core_vcn.vcn.id

  #Optional
  display_name    = "soa-lb-private-subnet1"
  dhcp_options_id = oci_core_vcn.vcn.default_dhcp_options_id
  dns_label       = "soalbprivate1"
  prohibit_public_ip_on_vnic = true
  route_table_id  = oci_core_route_table.private_route_table.id
  # security_list_ids = [oci_core_vcn.vcn.default_security_list_id, oci_core_security_list.security_list.id]
  security_list_ids = [oci_core_security_list.lb_security_list.id]
}

resource "oci_core_subnet" "soa_private_subnet" {
  #Required
  cidr_block        = var.subnet_private_cidr
  compartment_id    = oci_identity_compartment.soacs.id
  vcn_id            = oci_core_vcn.vcn.id

  #Optional
  display_name    = "soa-private-subnet1"
  dhcp_options_id = oci_core_vcn.vcn.default_dhcp_options_id
  dns_label       = "soaprivate1"
  prohibit_public_ip_on_vnic = true
  route_table_id  = oci_core_route_table.private_route_table.id
  # security_list_ids = [oci_core_vcn.vcn.default_security_list_id, oci_core_security_list.security_list.id]
  security_list_ids = [oci_core_security_list.wls_lb_security_list.id, oci_core_security_list.internal_security_list.id, oci_core_security_list.wls_security_list.id]
}

# Define the Security Policy
resource "oci_identity_policy" "soa_policy" {
  #Required
  compartment_id = oci_identity_compartment.soacs.id
  description    = "SOACS PSM Policy created by Terraform"
  name           = "soa-psm-policy"

  statements = [
    "Allow service PSM to inspect vcns in compartment ${oci_identity_compartment.soacs.name}",
    "Allow service PSM to use subnets in compartment ${oci_identity_compartment.soacs.name}",
    "Allow service PSM to use vnics in compartment ${oci_identity_compartment.soacs.name}",
    "Allow service PSM to manage security-lists in compartment ${oci_identity_compartment.soacs.name}",
    "Allow service PSM to inspect database-family in compartment ${oci_identity_compartment.soacs.name}",
    "Allow service PSM to inspect autonomous-database in compartment ${oci_identity_compartment.soacs.name}",
  ]
}

# Create the Bucket
resource "oci_objectstorage_bucket" "soa_bucket" {
  #Required
  compartment_id = oci_identity_compartment.soacs.id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "${var.prefix}-${var.soa_bucket_name}"

  #Optional
  access_type = "NoPublicAccess"
}

# Create the DBSystem
resource "oci_database_db_system" "soa_db_system" {
  #Required
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = oci_identity_compartment.soacs.id
  database_edition    = var.db_system_edition

  db_home {
    #Required
    database {
      #Required
      admin_password = var.db_admin_password

      #Optional
      db_backup_config {
        auto_backup_enabled = false
      }

      db_name = var.db_name
    }

    #Optional
    db_version = var.db_version
  }

  hostname        = var.db_hostname
  shape           = var.db_system_shape
  ssh_public_keys = [file(var.ssh_public_key_path)]
  subnet_id       = oci_core_subnet.soa_private_subnet.id

  #Optional
  display_name            = "${var.prefix}-${var.soa_db_system_display_name}"
  #Initial data storage size (in GB) must be one of [256, 512, 1024, 2048, 4096, 6144, 8192, 10240, 12288, 14336, 16384, 18432, 20480, 22528, 24576, 26624, 28672, 30720, 32768, 34816, 36864, 38912, 40960]
  data_storage_size_in_gb = var.data_storage_size_in_gb
  license_model           = var.license_model
  # node_count              = data.oci_database_db_system_shapes.soa_db_system_shapes.db_system_shapes[0]["minimum_node_count"]
  node_count              = 2
}

# Create the Bastion
resource "oci_core_instance" "bastion" {
  # Required
  availability_domain = data.oci_identity_availability_domain.ad.name
  compartment_id      = oci_identity_compartment.soacs.id
  shape               = var.bastion_shape

  # display_name = "vch-build-server"
  display_name = "${var.prefix}-${var.bastion_name}"

  # Optional
  create_vnic_details {
    # Required
    subnet_id = oci_core_subnet.soa_bastion_subnet.id

    # Optional
    assign_public_ip = true
  }

  source_details {
    # Required
    source_type = "image"
    source_id   = var.imageocids[var.region]

    # Apply this to set the size of the boot volume that's created for this instance.
    # Otherwise, the default boot volume size of the image is used.
    # This should only be specified when source_type is set to "image".
    #boot_volume_size_in_gbs = "60"
  }

  # Apply the following flag only if you wish to preserve the attached boot volume upon destroying this instance
  # Setting this and destroying the instance will result in a boot volume that should be managed outside of this config.
  # When changing this value, make sure to run 'terraform apply' so that it takes effect before the resource is destroyed.
  #preserve_boot_volume = true

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    # user_data           = base64encode(file(var.BootStrapFile))
  }
}