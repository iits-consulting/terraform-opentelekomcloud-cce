resource "opentelekomcloud_vpc_eip_v1" "cce_eip" {
  count = var.cluster_public_access ? 1 : 0
  bandwidth {
    charge_mode = "traffic"
    name        = "${var.name}-cluster-kubectl-endpoint"
    share_type  = "PER"
    size        = 50
  }
  tags = var.tags
  publicip {
    type = "5_bgp"
  }
}

data "opentelekomcloud_vpc_subnet_v1" "eni_subnet" {
  count = local.cluster_container_network_type == "eni" ? 1 : 0
  id    = length(var.cluster_eni_subnet_id) > 0 ? var.cluster_eni_subnet_id : var.cluster_subnet_id
}

resource "opentelekomcloud_cce_cluster_v3" "cluster" {
  name                     = var.name
  annotations              = merge(var.cluster_annotations, var.cluster_install_icagent ? { "cluster.install.addons.external/install" = jsonencode([{ addonTemplateName = "icagent" }]) } : {})
  timezone                 = var.cluster_timezone
  flavor_id                = "cce.${var.cluster_type == "BareMetal" ? "t" : "s"}${var.cluster_high_availability ? 2 : 1}.${lower(var.cluster_size)}"
  cluster_version          = var.cluster_version
  cluster_type             = var.cluster_type
  description              = "Kubernetes Cluster ${var.name}."
  ipv6_enable              = var.cluster_ipv6_enable
  extend_param             = var.cluster_extend_param
  enable_volume_encryption = var.cluster_enable_volume_encryption
  vpc_id                   = var.cluster_vpc_id
  subnet_id                = var.cluster_subnet_id
  security_group_id        = var.cluster_security_group_id
  highway_subnet_id        = var.cluster_highway_subnet_id
  container_network_type   = local.cluster_container_network_type
  container_network_cidr   = local.cluster_container_network_type == "eni" ? null : var.cluster_container_cidr
  eni_subnet_id            = local.cluster_container_network_type == "eni" ? data.opentelekomcloud_vpc_subnet_v1.eni_subnet[0].subnet_id : null
  # var.cluster_eni_subnet_cidr is disabled here since setting it to any CIDR other than the full range of the eni_subnet results in:
  # {"kind":"Status","apiVersion":"v1","metadata":{},"status":"Failure","code":400,"errorCode":"CCE.01400001","errorMessage":"Invalid request.","error_code":"CCE_CM.0004","error_msg":"Request is invalid","message":"Eni subnetId and subnetCidr not matched","reason":"BadRequest"}
  # eni_subnet_cidr = local.cluster_container_network_type == "eni" ? length(var.cluster_eni_subnet_cidr) > 0 ? var.cluster_eni_subnet_cidr : data.opentelekomcloud_vpc_subnet_v1.eni_subnet[0].cidr : null
  eni_subnet_cidr                  = local.cluster_container_network_type == "eni" ? data.opentelekomcloud_vpc_subnet_v1.eni_subnet[0].cidr : null
  api_access_trustlist             = var.cluster_api_access_trustlist
  kubernetes_svc_ip_range          = var.cluster_service_cidr
  eip                              = var.cluster_public_access ? opentelekomcloud_vpc_eip_v1.cce_eip[0].publicip[0].ip_address : null
  multi_az                         = var.cluster_high_availability ? var.cluster_high_availability : null
  authentication_mode              = var.cluster_authentication_mode
  no_addons                        = var.cluster_no_addons
  ignore_addons                    = var.cluster_ignore_addons
  ignore_certificate_users_data    = var.cluster_ignore_certificate_users_data
  ignore_certificate_clusters_data = var.cluster_ignore_certificate_clusters_data
  kube_proxy_mode                  = var.cluster_kube_proxy_mode
  delete_evs                       = var.cluster_delete_evs
  delete_obs                       = var.cluster_delete_obs
  delete_sfs                       = var.cluster_delete_sfs
  delete_efs                       = var.cluster_delete_efs
  delete_eni                       = var.cluster_delete_eni
  delete_net                       = var.cluster_delete_net
  delete_all_storage               = var.cluster_delete_all_storage
  delete_all_network               = var.cluster_delete_all_network

  dynamic "authenticating_proxy" {
    for_each = var.cluster_authentication_mode != "authenticating_proxy" ? toset([]) : toset(["authenticating_proxy"])
    content {
      ca          = var.cluster_authenticating_proxy_ca
      cert        = var.cluster_authenticating_proxy_cert
      private_key = var.cluster_authenticating_proxy_private_key
    }
  }

  timeouts {
    create = "60m"
    delete = "60m"
  }
  depends_on = [errorcheck_is_valid.cluster_container_network_type]
}
