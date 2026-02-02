variable "name" {
  type        = string
  description = "CCE cluster name"
}

variable "tags" {
  type        = map(any)
  description = "Common tag set for CCE resources"
  default     = {}
}

variable "cluster_annotations" {
  type        = map(string)
  description = "CCE cluster annotations, key/value pair format. This field is not stored in the database and is used only to specify the add-ons to be installed in the cluster."
  default     = {}
}

variable "cluster_timezone" {
  type        = string
  description = "CCE cluster timezone in string format"
  default     = null
}

variable "cluster_ipv6_enable" {
  type        = bool
  description = "Specifies whether the cluster supports IPv6 addresses. This field is supported in clusters of v1.25 and later versions."
  default     = null
}

variable "cluster_extend_param" {
  type        = map(string)
  description = "CCE cluster extended parameters, key/value pair format. For details, please see https://docs.otc.t-systems.com/cloud-container-engine/api-ref/apis/cluster_management/creating_a_cluster.html#cce-02-0236-table17575013586."
  default     = null
}

variable "cluster_vpc_id" {
  type        = string
  description = "The ID of the VPC for the cluster nodes."
}

variable "cluster_subnet_id" {
  type        = string
  description = "The UUID of the subnet for the cluster nodes."
}

variable "cluster_eni_subnet_id" {
  type        = string
  description = "Specifies the UUID of ENI subnet. Specified only when creating a CCE Turbo cluster (when cluster_container_network_type = \"eni\"). If unspecified, module will use the same subnet as cluster_subnet_id."
  default     = ""
}

# var.cluster_eni_subnet_cidr is disabled here since setting it to any CIDR other than the full range of the eni_subnet results in:
# {"kind":"Status","apiVersion":"v1","metadata":{},"status":"Failure","code":400,"errorCode":"CCE.01400001","errorMessage":"Invalid request.","error_code":"CCE_CM.0004","error_msg":"Request is invalid","message":"Eni subnetId and subnetCidr not matched","reason":"BadRequest"}
# variable "cluster_eni_subnet_cidr" {
#   type        = string
#   description = "Specifies the ENI network segment. Currently this parameter cannot be set to any CIDR except the entire ENI subnet range and is therefore disabled."
#   default     = ""
# }
#
# resource "errorcheck_is_valid" "cluster_eni_subnet_id" {
#   name = "Check if cluster_eni_subnet_id is set up correctly when cluster_eni_subnet_cidr is specified."
#   test = {
#     assert        = length(var.cluster_eni_subnet_cidr) > 0 ? length(var.cluster_eni_subnet_id) > 0 : true
#     error_message = "If cluster_eni_subnet_cidr is specified, the cluster_eni_subnet_id must also be set."
#   }
# }

resource "errorcheck_is_valid" "cluster_container_network_type" {
  name = "Check if cluster_container_network_type is set up correctly when cluster_eni_subnet_id is specified."
  test = {
    assert        = length(var.cluster_eni_subnet_id) > 0 ? local.cluster_container_network_type == "eni" : true
    error_message = "If cluster_eni_subnet_id is specified, cluster_container_network_type must must be \"eni\" (CCE Turbo Cluster)."
  }
}

variable "cluster_security_group_id" {
  type        = string
  description = "Default worker node security group ID of the cluster. If specified, the cluster will be bound to the target security group. Otherwise, the system will automatically create a default worker node security group for you."
  default     = null
}

variable "cluster_highway_subnet_id" {
  type        = string
  description = "The ID of the high speed network for bare metal nodes."
  default     = null
}

variable "cluster_version" {
  type        = string
  description = "CCE cluster version."
  default     = "v1.31"
}

variable "cluster_size" {
  type        = string
  description = "Size of the cluster: small, medium, large"
  default     = "small"
  validation {
    condition     = contains(["small", "medium", "large"], lower(var.cluster_size))
    error_message = "Allowed values for cluster_size are \"small\", \"medium\" and \"large\"."
  }
}

variable "cluster_type" {
  type        = string
  description = "Cluster type: VirtualMachine or BareMetal"
  default     = "VirtualMachine"
}

variable "cluster_container_network_type" {
  type        = string
  description = "Container network type: vpc-router, overlay_l2 or eni for VirtualMachine Clusters; underlay_ipvlan for BareMetal Clusters"
  default     = ""
}

variable "cluster_enable_volume_encryption" {
  type        = bool
  description = "System and data disks encryption of master nodes. Changing this parameter will create a new cluster resource."
  default     = true
}

variable "cluster_container_cidr" {
  type        = string
  description = "Kubernetes pod network CIDR range"
  default     = "172.16.0.0/16"
}

variable "cluster_service_cidr" {
  type        = string
  description = "Kubernetes service network CIDR range"
  default     = "172.17.0.0/16"
}

variable "cluster_public_access" {
  type        = bool
  description = "Bind a public IP to the CLuster to make it publicly reachable over the internet."
  default     = true
}

variable "cluster_api_access_trustlist" {
  type        = list(string)
  description = "Specifies the trustlist of network CIDRs that are allowed to access cluster APIs."
  default     = null
}

variable "cluster_high_availability" {
  type        = bool
  description = "Create the cluster in highly available mode"
  default     = false
}

variable "cluster_enable_scaling" {
  type        = bool
  description = "Enable autoscaling of the cluster node pools"
  default     = false
}

variable "cluster_install_icagent" {
  type        = bool
  description = "Install icagent for logging and metrics via AOM"
  default     = false
}

variable "cluster_component_configurations" {
  type        = map(map(string))
  description = "Specifies the kubernetes component configurations. For details, see https://docs.otc.t-systems.com/cloud-container-engine/umn/clusters/managing_clusters/modifying_cluster_configurations.html#cce-10-0213"
  default     = {}
}

# # This is the actual provider / API Spec. We opted to use the above solution instead as it was equivalent but more concise, making the module easier to configure and maintain
# variable "cluster_component_configurations" {
#   type = list(object({
#     name = string
#     configurations = optional(list(object({
#       name = string
#       value = string
#     })),[])
#   }))
#   description = "Specifies the kubernetes component configurations. For details, see https://docs.otc.t-systems.com/cloud-container-engine/umn/clusters/managing_clusters/modifying_cluster_configurations.html#cce-10-0213"
#   default     = []
# }
#
# locals {
#   cluster_component_configurations = { for configuration in var.cluster_component_configurations:
#     configuration.name => { for conf in configuration.configurations: conf.name => conf.value }
#   }
# }

variable "node_storage_runtime_size" {
  type        = number
  default     = null
  description = "How much of the data disk (in percent) is reserved for the node runtime storage (i.e. docker images). OTC default is 90"
  validation {
    condition     = var.node_storage_runtime_size == null ? true : var.node_storage_runtime_size >= 10 && var.node_storage_runtime_size <= 90
    error_message = "node_storage_runtime_size not in range 10 <= x <= 90"
  }
}

variable "node_storage_kubernetes_size" {
  type        = number
  default     = null
  description = "How much of the data disk (in percent) is reserved for the kubernetes runtime storage (i.e. ephemeral storage). OTC default is 10"
  validation {
    condition     = var.node_storage_kubernetes_size == null ? true : var.node_storage_kubernetes_size >= 10 && var.node_storage_kubernetes_size <= 90
    error_message = "node_storage_kubernetes_size not in range 10 <= x <= 90"
  }
}

variable "node_storage_remainder_path" {
  type        = string
  default     = null
  description = "If the runtime & kubernetes sizes do not add up to 100(%), otc wants to know where/how to mount the remaining space. Note that there are forbidden paths, see otc-documentation for which paths are forbidden."
}

locals {
  is_disk_spacing_default = var.node_storage_runtime_size == null && var.node_storage_kubernetes_size == null
}

resource "errorcheck_is_valid" "node_storage_remainder_path" {
  name = "Check if node_storage_remainder_path is set up correctly."
  test = {
    assert        = local.is_disk_spacing_default ? var.node_storage_remainder_path == null : var.node_storage_runtime_size + var.node_storage_kubernetes_size == 100 ? var.node_storage_remainder_path == null : var.node_storage_remainder_path != null && try(length(var.node_storage_remainder_path) > 0, false)
    error_message = "If the runtime & kubernetes size do not sum up to 100(%%) node_storage_remainder_path must be set, otherwise it must be unset."
  }
}

resource "errorcheck_is_valid" "cluster_storage_size_both_set" {
  name = "Check if cluster_storage_remainder_path and cluster_storage_kubernetes_size are set up correctly."
  test = {
    assert        = local.is_disk_spacing_default ? true : var.node_storage_runtime_size != null && var.node_storage_kubernetes_size != null
    error_message = "Either both runtime & kubernetes sizes need to be unset, or both need to be set."
  }
}

resource "errorcheck_is_valid" "cluster_storage_size_combined" {
  name = "Check if cluster_storage_remainder_path and cluster_storage_kubernetes_size are set up correctly."
  test = {
    assert        = local.is_disk_spacing_default ? true : var.node_storage_runtime_size + var.node_storage_kubernetes_size <= 100
    error_message = "The sum of node_storage_runtime_size and node_storage_kubernetes_size cannot exceed 100(%%)."
  }
}

locals {
  //"Container network type: vpc-router or overlay_l2 for VirtualMachine Clusters; underlay_ipvlan for BareMetal Clusters"
  cluster_container_network_type = length(var.cluster_container_network_type) > 0 ? var.cluster_container_network_type : var.cluster_type == "VirtualMachine" ? "vpc-router" : "underlay_ipvlan"
}

variable "node_availability_zones" {
  type        = set(string)
  description = "Availability zones for the node pools. Providing multiple availability zones creates one node pool in each zone."
}

variable "node_count" {
  type        = number
  description = "Number of nodes to create"
}

variable "node_flavor" {
  type        = string
  description = "Node specifications in otc flavor format"
}

variable "node_os" {
  type        = string
  description = "Operating system of worker nodes: EulerOS 2.9 or HCE OS 2.0"
  default     = "HCE OS 2.0"
}

variable "node_container_runtime" {
  type        = string
  description = "The container runtime to use. Must be set to either containerd or docker."
  default     = "containerd"
  validation {
    condition     = contains(["containerd", "docker"], var.node_container_runtime)
    error_message = "Allowed values for node_container_runtime are either \"containerd\" or \"docker\"."
  }
}

variable "node_storage_type" {
  type        = string
  description = "Type of node storage SATA, SAS or SSD"
  default     = "SATA"
}

variable "node_storage_size" {
  type        = number
  description = "Size of the node system disk in GB"
  default     = 100
}

variable "node_storage_encryption_enabled" {
  type        = bool
  description = "Enable OTC KMS volume encryption for the node pool volumes."
  default     = true
}

variable "node_storage_encryption_kms_key_name" {
  type        = string
  description = "If KMS volume encryption is enabled, specify a name of an existing kms key. Setting this disables the creation of a new kms key."
  default     = null
}

variable "node_postinstall" {
  type        = string
  description = "Post install script for the cluster ECS node pool."
  default     = ""
}

variable "node_taints" {
  type = list(object({
    effect = string
    key    = string
    value  = string
  }))
  description = "Node taints for the node pool"
  default     = []
}

variable "node_k8s_tags" {
  default     = {}
  description = "(Optional, Map) Tags of a Kubernetes node, key/value pair format."
  type        = map(string)
}

variable "autoscaler_node_max" {
  type        = number
  description = "Maximum limit of servers to create"
  default     = 10
}

variable "autoscaler_node_min" {
  type        = number
  description = "Lower bound of servers to always keep (default: <node_count>)"
  default     = null
}

locals {
  // Lower bound of servers to always keep (default: <node_count>)
  autoscaler_node_min = var.autoscaler_node_min == null ? var.node_count : var.autoscaler_node_min
}

variable "autoscaler_version" {
  type        = string
  description = "Version of the Autoscaler Addon Template"
  default     = "latest"
}

variable "metrics_server_version" {
  type        = string
  description = "Version of the Metrics Server Addon Template"
  default     = "latest"
}

variable "cluster_authentication_mode" {
  type        = string
  description = "Authentication mode of the Cluster. Either rbac or authenticating_proxy"
  default     = "rbac"
}

variable "cluster_authenticating_proxy_ca" {
  type        = string
  description = "X509 CA certificate configured in authenticating_proxy mode. The maximum size of the certificate is 1 MB."
  default     = null
}

variable "cluster_authenticating_proxy_cert" {
  type        = string
  description = "Client certificate issued by the X509 CA certificate configured in authenticating_proxy mode."
  default     = null
}

variable "cluster_authenticating_proxy_private_key" {
  type        = string
  description = "Private key of the client certificate issued by the X509 CA certificate configured in authenticating_proxy mode."
  default     = null
}

variable "cluster_no_addons" {
  type        = bool
  description = "Remove addons installed by the default after the cluster creation."
  default     = null
}

variable "cluster_ignore_addons" {
  type        = bool
  description = "Skip all cluster addons operations."
  default     = null
}

variable "cluster_ignore_certificate_users_data" {
  type        = bool
  description = "Skip sensitive user data. (will disable some module outputs)"
  default     = null
}

variable "cluster_ignore_certificate_clusters_data" {
  type        = bool
  description = "Skip sensitive cluster data. (will disable some module outputs)"
  default     = null
}

variable "cluster_kube_proxy_mode" {
  type        = string
  description = "Service forwarding mode: iptables or ipvs "
  default     = null
}

variable "cluster_delete_evs" {
  type        = bool
  description = "Specifies whether to delete associated EVS disks when deleting the CCE cluster."
  default     = null
}

variable "cluster_delete_obs" {
  type        = bool
  description = "Specifies whether to delete associated OBS buckets when deleting the CCE cluster. "
  default     = null
}

variable "cluster_delete_sfs" {
  type        = bool
  description = "Specifies whether to delete associated SFS file systems when deleting the CCE cluster."
  default     = null
}

variable "cluster_delete_efs" {
  type        = bool
  description = "Specifies whether to unbind associated SFS Turbo file systems when deleting the CCE cluster."
  default     = null
}

variable "cluster_delete_eni" {
  type        = bool
  description = "Specifies whether to delete ENI ports when deleting the CCE cluster."
  default     = null
}

variable "cluster_delete_net" {
  type        = bool
  description = "Specifies whether to delete cluster Service/ingress-related resources, such as ELB when deleting the CCE cluster."
  default     = null
}

variable "cluster_delete_all_storage" {
  type        = bool
  description = "Specifies whether to delete all associated storage resources when deleting the CCE cluster."
  default     = null
}

variable "cluster_delete_all_network" {
  type        = bool
  description = "Specifies whether to delete all associated network resources when deleting the CCE cluster."
  default     = null
}
