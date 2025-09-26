resource "tls_private_key" "cluster_keypair" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "random_id" "cluster_keypair_id" {
  byte_length = 4
}

resource "opentelekomcloud_compute_keypair_v2" "cluster_keypair" {
  name       = "${var.name}-cluster-keypair-${random_id.cluster_keypair_id.hex}"
  public_key = tls_private_key.cluster_keypair.public_key_openssh
}

resource "random_id" "id" {
  count       = var.node_storage_encryption_enabled && var.node_storage_encryption_kms_key_name == null ? 1 : 0
  byte_length = 4
}

resource "opentelekomcloud_kms_key_v1" "node_storage_encryption_key" {
  count           = var.node_storage_encryption_enabled && var.node_storage_encryption_kms_key_name == null ? 1 : 0
  key_alias       = "${var.name}-node-pool-${random_id.id[0].hex}"
  key_description = "${var.name} CCE Node Pool volume encryption key"
  pending_days    = 7
  is_enabled      = "true"
}

data "opentelekomcloud_kms_key_v1" "node_storage_encryption_existing_key" {
  count     = var.node_storage_encryption_enabled && var.node_storage_encryption_kms_key_name != null ? 1 : 0
  key_alias = var.node_storage_encryption_kms_key_name
}

resource "opentelekomcloud_cce_node_pool_v3" "cluster_node_pool" {
  for_each           = var.node_availability_zones
  cluster_id         = opentelekomcloud_cce_cluster_v3.cluster.id
  name               = "${var.name}-nodes-${each.value}"
  flavor             = var.node_flavor
  initial_node_count = var.node_count
  availability_zone  = each.value
  key_pair           = opentelekomcloud_compute_keypair_v2.cluster_keypair.name
  os                 = var.node_os
  runtime            = var.node_container_runtime

  scale_enable             = var.cluster_enable_scaling
  min_node_count           = local.autoscaler_node_min
  max_node_count           = var.autoscaler_node_max
  scale_down_cooldown_time = 15
  priority                 = 1
  user_tags                = var.tags
  docker_base_size         = 20
  postinstall              = var.node_postinstall

  k8s_tags = var.node_k8s_tags

  dynamic "taints" {
    for_each = var.node_taints
    content {
      effect = taints.value.effect
      key    = taints.value.key
      value  = taints.value.value
    }
  }

  storage = local.is_disk_spacing_default ? null : jsonencode({
    storageSelectors = [
      {
        name        = "cceUse"
        storageType = "evs"
        matchLabels = {
          count             = "1"
          metadataCmkid     = var.node_storage_encryption_enabled ? (var.node_storage_encryption_kms_key_name == null ? opentelekomcloud_kms_key_v1.node_storage_encryption_key[0].id : data.opentelekomcloud_kms_key_v1.node_storage_encryption_existing_key[0].id) : null
          metadataEncrypted = var.node_storage_encryption_enabled ? "1" : "0"
          size              = tostring(var.node_storage_size)
          volumeType        = var.node_storage_type
        }
      }
    ]
    storageGroups = [
      {
        name       = "vgpaas"
        cceManaged = true
        selectorNames = [
          "cceUse"
        ]
        virtualSpaces = concat([
          {
            name = "runtime"
            size = "${var.node_storage_runtime_size}%"
            runtimeConfig = {
              lvType = "linear"
            }
          },
          {
            name = "kubernetes"
            size = "${var.node_storage_kubernetes_size}%"
            lvmConfig = {
              lvType = "linear"
            }
          }
          ], var.node_storage_remainder_path == null ? [] : [
          {
            name = "user"
            size = "${100 - var.node_storage_kubernetes_size - var.node_storage_runtime_size}%"
            lvmConfig = {
              lvType = "linear"
            }
        }])
      }
    ]
  })

  root_volume {
    size       = 50
    volumetype = "SSD"
    kms_id     = var.node_storage_encryption_enabled ? (var.node_storage_encryption_kms_key_name == null ? opentelekomcloud_kms_key_v1.node_storage_encryption_key[0].id : data.opentelekomcloud_kms_key_v1.node_storage_encryption_existing_key[0].id) : null
  }

  data_volumes {
    size       = var.node_storage_size
    volumetype = var.node_storage_type
    kms_id     = var.node_storage_encryption_enabled ? (var.node_storage_encryption_kms_key_name == null ? opentelekomcloud_kms_key_v1.node_storage_encryption_key[0].id : data.opentelekomcloud_kms_key_v1.node_storage_encryption_existing_key[0].id) : null
  }

  lifecycle {
    ignore_changes = [
      initial_node_count,
    ]
    create_before_destroy = true
  }
}
