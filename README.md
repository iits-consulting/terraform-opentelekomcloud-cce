## OTC Cloud Container Engine Terraform module

A module designed to support full capabilities of OTC CCE while simplifying the configuration for ease of use.

Usage example

```hcl
module "cce" {
  source             = "iits-consulting/cce/opentelekomcloud"
  name               = var.name

  // Cluster configuration
  cluster_vpc_id            = module.vpc.vpc.id
  cluster_subnet_id         = values(module.vpc.subnets)[0].id
  cluster_cluster_version   = "v1.19.8-r0"
  cluster_high_availability = false
  cluster_enable_scaling    = true #set this flag to false to disable auto scaling
  // Node configuration
  node_availability_zones = ["eu-de-03", "eu-de-01"]
  node_count              = 3
  node_flavor             = local.node_spec_default
  node_storage_type       = "SSD"
  node_storage_size       = 100
  // Autoscaling configuration
  autoscaling_node_max = 8
}
```

> **WARNING:** The parameter `node_config.node_storage_encryption_enabled` should be kept as `false` unless an agency for EVS is created with:
>
> - Agency Name = `EVSAccessKMS`
> - Agency Type = `Account`
> - Delegated Account = `op_svc_evs`
> - Permissions = `KMS Administrator` within the project

#### Testing Scaling up and down

We first test the scaling up by adding a test deployment:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: autoscale-test-deployment
  labels:
    app: autoscale-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: autoscale-test
  template:
    metadata:
      labels:
        app: autoscale-test
    spec:
      containers:
        - name: hello-world
          image: nginx
          ports:
            - containerPort: 80
          resources:
            requests:
              memory: "64Mi"
              cpu: "250m"
```

We can scale the deployment and see how the cluster responds:

```shell script
> kubectl scale deployment/autoscale-test-deployment --replicas=40
```

Since the 40 replicas utilize 10 CPUs, these do not fit on the nodes in the default node pool. Therefore the autoscaler
will kick in and create an additional node.

```shell script
> kubectl get pods
NAME                                        READY   STATUS            RESTARTS   AGE
autoscale-test-deployment-6f9ff6448-4x248   0/2     Pending           0          13s
autoscale-test-deployment-6f9ff6448-5kdcn   0/2     PodInitializing   0          14s
autoscale-test-deployment-6f9ff6448-6pcmv   0/2     Pending           0          14s
autoscale-test-deployment-6f9ff6448-8ftc8   1/2     Running           0          14s
autoscale-test-deployment-6f9ff6448-9kxvt   0/2     Pending           0          14s
autoscale-test-deployment-6f9ff6448-9scj5   0/2     Pending           0          13s
autoscale-test-deployment-6f9ff6448-d7btf   0/2     Pending           0          13s
autoscale-test-deployment-6f9ff6448-dsrvs   0/2     PodInitializing   0          14s
autoscale-test-deployment-6f9ff6448-dxf58   0/2     Pending           0          14s
autoscale-test-deployment-6f9ff6448-gdjvx   0/2     PodInitializing   0          14s
autoscale-test-deployment-6f9ff6448-grwsl   0/2     PodInitializing   0          14s
autoscale-test-deployment-6f9ff6448-gxbr9   0/2     Pending           0          13s
autoscale-test-deployment-6f9ff6448-h27z2   0/2     Init:0/1          0          14s
autoscale-test-deployment-6f9ff6448-h89vw   0/2     Pending           0          13s
autoscale-test-deployment-6f9ff6448-hltfb   0/2     Pending           0          13s
autoscale-test-deployment-6f9ff6448-hs5q8   0/2     Pending           0          13s
autoscale-test-deployment-6f9ff6448-m5zn9   0/2     PodInitializing   0          14s
autoscale-test-deployment-6f9ff6448-m6fxx   0/2     Pending           0          14s
autoscale-test-deployment-6f9ff6448-mmtz2   0/2     Pending           0          14s
autoscale-test-deployment-6f9ff6448-mrpjt   0/2     Pending           0          14s
autoscale-test-deployment-6f9ff6448-mzkrn   2/2     Running           0          26h
autoscale-test-deployment-6f9ff6448-n6hrq   1/2     Running           0          14s
autoscale-test-deployment-6f9ff6448-p2p9v   0/2     PodInitializing   0          14s
autoscale-test-deployment-6f9ff6448-pt4vj   0/2     Pending           0          13s
autoscale-test-deployment-6f9ff6448-q2ksm   0/2     Pending           0          14s
autoscale-test-deployment-6f9ff6448-q7p7t   0/2     Pending           0          14s
autoscale-test-deployment-6f9ff6448-qfbqq   0/2     Pending           0          13s
autoscale-test-deployment-6f9ff6448-qs949   0/2     Pending           0          13s
autoscale-test-deployment-6f9ff6448-qszsx   0/2     PodInitializing   0          14s
autoscale-test-deployment-6f9ff6448-rm6c9   0/2     Pending           0          14s
autoscale-test-deployment-6f9ff6448-rnfzn   0/2     PodInitializing   0          14s
autoscale-test-deployment-6f9ff6448-rsgh6   0/2     Pending           0          14s
autoscale-test-deployment-6f9ff6448-sgzhb   0/2     Pending           0          13s
autoscale-test-deployment-6f9ff6448-v8qvm   0/2     Pending           0          13s
autoscale-test-deployment-6f9ff6448-w57gp   0/2     Pending           0          14s
autoscale-test-deployment-6f9ff6448-wfp5p   0/2     Pending           0          14s
autoscale-test-deployment-6f9ff6448-xh5sm   0/2     Pending           0          13s
autoscale-test-deployment-6f9ff6448-xrnrz   0/2     Pending           0          13s
autoscale-test-deployment-6f9ff6448-z72sp   0/2     Pending           0          13s
autoscale-test-deployment-6f9ff6448-zdgkp   0/2     PodInitializing   0          14s
```

And then we also see the started nodes, 2 in the default node pool and 4 in the autoscale node pool:

```shell script
> kubectl get nodes -L cce.cloud.com/cce-nodepool
NAME              STATUS   ROLES    AGE     VERSION                             CCE-NODEPOOL
192.168.13.187    Ready    <none>   6m23s   v1.17.9-r0-CCE20.7.1.B003-17.36.3   otc-customer-success-dev-node-pool-autoscale
192.168.161.247   Ready    <none>   4h15m   v1.17.9-r0-CCE20.7.1.B003-17.36.3   otc-customer-success-dev-node-pool-autoscale
192.168.182.115   Ready    <none>   39d     v1.17.9-r0-CCE20.7.1.B003-17.36.3
192.168.186.181   Ready    <none>   6m23s   v1.17.9-r0-CCE20.7.1.B003-17.36.3   otc-customer-success-dev-node-pool-autoscale
192.168.42.133    Ready    <none>   39d     v1.17.9-r0-CCE20.7.1.B003-17.36.3
192.168.83.154    Ready    <none>   6m17s   v1.17.9-r0-CCE20.7.1.B003-17.36.3   otc-customer-success-dev-node-pool-autoscale
```

Scaling down again...

```shell script
> kubectl scale deployment/autoscale-test-deployment --replicas=1
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_errorcheck"></a> [errorcheck](#requirement\_errorcheck) | 3.0.3 |
| <a name="requirement_opentelekomcloud"></a> [opentelekomcloud](#requirement\_opentelekomcloud) | ~> 1.36, >=1.36.48 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_errorcheck"></a> [errorcheck](#provider\_errorcheck) | 3.0.3 |
| <a name="provider_opentelekomcloud"></a> [opentelekomcloud](#provider\_opentelekomcloud) | ~> 1.36, >=1.36.48 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | ~> 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [errorcheck_is_valid.autoscaler_version_availability](https://registry.terraform.io/providers/iits-consulting/errorcheck/3.0.3/docs/resources/is_valid) | resource |
| [errorcheck_is_valid.cluster_container_network_type](https://registry.terraform.io/providers/iits-consulting/errorcheck/3.0.3/docs/resources/is_valid) | resource |
| [errorcheck_is_valid.cluster_storage_size_both_set](https://registry.terraform.io/providers/iits-consulting/errorcheck/3.0.3/docs/resources/is_valid) | resource |
| [errorcheck_is_valid.cluster_storage_size_combined](https://registry.terraform.io/providers/iits-consulting/errorcheck/3.0.3/docs/resources/is_valid) | resource |
| [errorcheck_is_valid.metrics_version_availability](https://registry.terraform.io/providers/iits-consulting/errorcheck/3.0.3/docs/resources/is_valid) | resource |
| [errorcheck_is_valid.node_storage_remainder_path](https://registry.terraform.io/providers/iits-consulting/errorcheck/3.0.3/docs/resources/is_valid) | resource |
| [opentelekomcloud_cce_addon_v3.autoscaler](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/cce_addon_v3) | resource |
| [opentelekomcloud_cce_addon_v3.metrics](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/cce_addon_v3) | resource |
| [opentelekomcloud_cce_cluster_v3.cluster](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/cce_cluster_v3) | resource |
| [opentelekomcloud_cce_node_pool_v3.cluster_node_pool](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/cce_node_pool_v3) | resource |
| [opentelekomcloud_compute_keypair_v2.cluster_keypair](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/compute_keypair_v2) | resource |
| [opentelekomcloud_kms_key_v1.node_storage_encryption_key](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/kms_key_v1) | resource |
| [opentelekomcloud_vpc_eip_v1.cce_eip](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/resources/vpc_eip_v1) | resource |
| [random_id.cluster_keypair_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_id.id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [tls_private_key.cluster_keypair](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [opentelekomcloud_cce_addon_templates_v3.autoscaler](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/data-sources/cce_addon_templates_v3) | data source |
| [opentelekomcloud_cce_addon_templates_v3.metrics](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/data-sources/cce_addon_templates_v3) | data source |
| [opentelekomcloud_identity_project_v3.current](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/data-sources/identity_project_v3) | data source |
| [opentelekomcloud_kms_key_v1.node_storage_encryption_existing_key](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/data-sources/kms_key_v1) | data source |
| [opentelekomcloud_vpc_subnet_v1.eni_subnet](https://registry.terraform.io/providers/opentelekomcloud/opentelekomcloud/latest/docs/data-sources/vpc_subnet_v1) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cluster_subnet_id"></a> [cluster\_subnet\_id](#input\_cluster\_subnet\_id) | The UUID of the subnet for the cluster nodes. | `string` | n/a | yes |
| <a name="input_cluster_vpc_id"></a> [cluster\_vpc\_id](#input\_cluster\_vpc\_id) | The ID of the VPC for the cluster nodes. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | CCE cluster name | `string` | n/a | yes |
| <a name="input_node_availability_zones"></a> [node\_availability\_zones](#input\_node\_availability\_zones) | Availability zones for the node pools. Providing multiple availability zones creates one node pool in each zone. | `set(string)` | n/a | yes |
| <a name="input_node_count"></a> [node\_count](#input\_node\_count) | Number of nodes to create | `number` | n/a | yes |
| <a name="input_node_flavor"></a> [node\_flavor](#input\_node\_flavor) | Node specifications in otc flavor format | `string` | n/a | yes |
| <a name="input_autoscaler_node_max"></a> [autoscaler\_node\_max](#input\_autoscaler\_node\_max) | Maximum limit of servers to create | `number` | `10` | no |
| <a name="input_autoscaler_node_min"></a> [autoscaler\_node\_min](#input\_autoscaler\_node\_min) | Lower bound of servers to always keep (default: <node\_count>) | `number` | `null` | no |
| <a name="input_autoscaler_version"></a> [autoscaler\_version](#input\_autoscaler\_version) | Version of the Autoscaler Addon Template | `string` | `"latest"` | no |
| <a name="input_cluster_annotations"></a> [cluster\_annotations](#input\_cluster\_annotations) | CCE cluster annotations, key/value pair format. This field is not stored in the database and is used only to specify the add-ons to be installed in the cluster. | `map(string)` | `{}` | no |
| <a name="input_cluster_api_access_trustlist"></a> [cluster\_api\_access\_trustlist](#input\_cluster\_api\_access\_trustlist) | Specifies the trustlist of network CIDRs that are allowed to access cluster APIs. | `list(string)` | `null` | no |
| <a name="input_cluster_authenticating_proxy_ca"></a> [cluster\_authenticating\_proxy\_ca](#input\_cluster\_authenticating\_proxy\_ca) | X509 CA certificate configured in authenticating\_proxy mode. The maximum size of the certificate is 1 MB. | `string` | `null` | no |
| <a name="input_cluster_authenticating_proxy_cert"></a> [cluster\_authenticating\_proxy\_cert](#input\_cluster\_authenticating\_proxy\_cert) | Client certificate issued by the X509 CA certificate configured in authenticating\_proxy mode. | `string` | `null` | no |
| <a name="input_cluster_authenticating_proxy_private_key"></a> [cluster\_authenticating\_proxy\_private\_key](#input\_cluster\_authenticating\_proxy\_private\_key) | Private key of the client certificate issued by the X509 CA certificate configured in authenticating\_proxy mode. | `string` | `null` | no |
| <a name="input_cluster_authentication_mode"></a> [cluster\_authentication\_mode](#input\_cluster\_authentication\_mode) | Authentication mode of the Cluster. Either rbac or authenticating\_proxy | `string` | `"rbac"` | no |
| <a name="input_cluster_container_cidr"></a> [cluster\_container\_cidr](#input\_cluster\_container\_cidr) | Kubernetes pod network CIDR range | `string` | `"172.16.0.0/16"` | no |
| <a name="input_cluster_container_network_type"></a> [cluster\_container\_network\_type](#input\_cluster\_container\_network\_type) | Container network type: vpc-router, overlay\_l2 or eni for VirtualMachine Clusters; underlay\_ipvlan for BareMetal Clusters | `string` | `""` | no |
| <a name="input_cluster_delete_all_network"></a> [cluster\_delete\_all\_network](#input\_cluster\_delete\_all\_network) | Specifies whether to delete all associated network resources when deleting the CCE cluster. | `bool` | `null` | no |
| <a name="input_cluster_delete_all_storage"></a> [cluster\_delete\_all\_storage](#input\_cluster\_delete\_all\_storage) | Specifies whether to delete all associated storage resources when deleting the CCE cluster. | `bool` | `null` | no |
| <a name="input_cluster_delete_efs"></a> [cluster\_delete\_efs](#input\_cluster\_delete\_efs) | Specifies whether to unbind associated SFS Turbo file systems when deleting the CCE cluster. | `bool` | `null` | no |
| <a name="input_cluster_delete_eni"></a> [cluster\_delete\_eni](#input\_cluster\_delete\_eni) | Specifies whether to delete ENI ports when deleting the CCE cluster. | `bool` | `null` | no |
| <a name="input_cluster_delete_evs"></a> [cluster\_delete\_evs](#input\_cluster\_delete\_evs) | Specifies whether to delete associated EVS disks when deleting the CCE cluster. | `bool` | `null` | no |
| <a name="input_cluster_delete_net"></a> [cluster\_delete\_net](#input\_cluster\_delete\_net) | Specifies whether to delete cluster Service/ingress-related resources, such as ELB when deleting the CCE cluster. | `bool` | `null` | no |
| <a name="input_cluster_delete_obs"></a> [cluster\_delete\_obs](#input\_cluster\_delete\_obs) | Specifies whether to delete associated OBS buckets when deleting the CCE cluster. | `bool` | `null` | no |
| <a name="input_cluster_delete_sfs"></a> [cluster\_delete\_sfs](#input\_cluster\_delete\_sfs) | Specifies whether to delete associated SFS file systems when deleting the CCE cluster. | `bool` | `null` | no |
| <a name="input_cluster_enable_scaling"></a> [cluster\_enable\_scaling](#input\_cluster\_enable\_scaling) | Enable autoscaling of the cluster node pools | `bool` | `false` | no |
| <a name="input_cluster_enable_volume_encryption"></a> [cluster\_enable\_volume\_encryption](#input\_cluster\_enable\_volume\_encryption) | System and data disks encryption of master nodes. Changing this parameter will create a new cluster resource. | `bool` | `true` | no |
| <a name="input_cluster_eni_subnet_id"></a> [cluster\_eni\_subnet\_id](#input\_cluster\_eni\_subnet\_id) | Specifies the UUID of ENI subnet. Specified only when creating a CCE Turbo cluster (when cluster\_container\_network\_type = "eni"). If unspecified, module will use the same subnet as cluster\_subnet\_id. | `string` | `""` | no |
| <a name="input_cluster_extend_param"></a> [cluster\_extend\_param](#input\_cluster\_extend\_param) | CCE cluster extended parameters, key/value pair format. For details, please see https://docs.otc.t-systems.com/cloud-container-engine/api-ref/apis/cluster_management/creating_a_cluster.html#cce-02-0236-table17575013586. | `map(string)` | `null` | no |
| <a name="input_cluster_high_availability"></a> [cluster\_high\_availability](#input\_cluster\_high\_availability) | Create the cluster in highly available mode | `bool` | `false` | no |
| <a name="input_cluster_highway_subnet_id"></a> [cluster\_highway\_subnet\_id](#input\_cluster\_highway\_subnet\_id) | The ID of the high speed network for bare metal nodes. | `string` | `null` | no |
| <a name="input_cluster_ignore_addons"></a> [cluster\_ignore\_addons](#input\_cluster\_ignore\_addons) | Skip all cluster addons operations. | `bool` | `null` | no |
| <a name="input_cluster_ignore_certificate_clusters_data"></a> [cluster\_ignore\_certificate\_clusters\_data](#input\_cluster\_ignore\_certificate\_clusters\_data) | Skip sensitive cluster data. (will disable some module outputs) | `bool` | `null` | no |
| <a name="input_cluster_ignore_certificate_users_data"></a> [cluster\_ignore\_certificate\_users\_data](#input\_cluster\_ignore\_certificate\_users\_data) | Skip sensitive user data. (will disable some module outputs) | `bool` | `null` | no |
| <a name="input_cluster_install_icagent"></a> [cluster\_install\_icagent](#input\_cluster\_install\_icagent) | Install icagent for logging and metrics via AOM | `bool` | `false` | no |
| <a name="input_cluster_ipv6_enable"></a> [cluster\_ipv6\_enable](#input\_cluster\_ipv6\_enable) | Specifies whether the cluster supports IPv6 addresses. This field is supported in clusters of v1.25 and later versions. | `bool` | `null` | no |
| <a name="input_cluster_kube_proxy_mode"></a> [cluster\_kube\_proxy\_mode](#input\_cluster\_kube\_proxy\_mode) | Service forwarding mode: iptables or ipvs | `string` | `null` | no |
| <a name="input_cluster_no_addons"></a> [cluster\_no\_addons](#input\_cluster\_no\_addons) | Remove addons installed by the default after the cluster creation. | `bool` | `null` | no |
| <a name="input_cluster_public_access"></a> [cluster\_public\_access](#input\_cluster\_public\_access) | Bind a public IP to the CLuster to make it publicly reachable over the internet. | `bool` | `true` | no |
| <a name="input_cluster_security_group_id"></a> [cluster\_security\_group\_id](#input\_cluster\_security\_group\_id) | Default worker node security group ID of the cluster. If specified, the cluster will be bound to the target security group. Otherwise, the system will automatically create a default worker node security group for you. | `string` | `null` | no |
| <a name="input_cluster_service_cidr"></a> [cluster\_service\_cidr](#input\_cluster\_service\_cidr) | Kubernetes service network CIDR range | `string` | `"172.17.0.0/16"` | no |
| <a name="input_cluster_size"></a> [cluster\_size](#input\_cluster\_size) | Size of the cluster: small, medium, large | `string` | `"small"` | no |
| <a name="input_cluster_timezone"></a> [cluster\_timezone](#input\_cluster\_timezone) | CCE cluster timezone in string format | `string` | `null` | no |
| <a name="input_cluster_type"></a> [cluster\_type](#input\_cluster\_type) | Cluster type: VirtualMachine or BareMetal | `string` | `"VirtualMachine"` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | CCE cluster version. | `string` | `"v1.31"` | no |
| <a name="input_metrics_server_version"></a> [metrics\_server\_version](#input\_metrics\_server\_version) | Version of the Metrics Server Addon Template | `string` | `"latest"` | no |
| <a name="input_node_container_runtime"></a> [node\_container\_runtime](#input\_node\_container\_runtime) | The container runtime to use. Must be set to either containerd or docker. | `string` | `"containerd"` | no |
| <a name="input_node_k8s_tags"></a> [node\_k8s\_tags](#input\_node\_k8s\_tags) | (Optional, Map) Tags of a Kubernetes node, key/value pair format. | `map(string)` | `{}` | no |
| <a name="input_node_os"></a> [node\_os](#input\_node\_os) | Operating system of worker nodes: EulerOS 2.9 or HCE OS 2.0 | `string` | `"HCE OS 2.0"` | no |
| <a name="input_node_postinstall"></a> [node\_postinstall](#input\_node\_postinstall) | Post install script for the cluster ECS node pool. | `string` | `""` | no |
| <a name="input_node_storage_encryption_enabled"></a> [node\_storage\_encryption\_enabled](#input\_node\_storage\_encryption\_enabled) | Enable OTC KMS volume encryption for the node pool volumes. | `bool` | `true` | no |
| <a name="input_node_storage_encryption_kms_key_name"></a> [node\_storage\_encryption\_kms\_key\_name](#input\_node\_storage\_encryption\_kms\_key\_name) | If KMS volume encryption is enabled, specify a name of an existing kms key. Setting this disables the creation of a new kms key. | `string` | `null` | no |
| <a name="input_node_storage_kubernetes_size"></a> [node\_storage\_kubernetes\_size](#input\_node\_storage\_kubernetes\_size) | How much of the data disk (in percent) is reserved for the kubernetes runtime storage (i.e. ephemeral storage). OTC default is 10 | `number` | `null` | no |
| <a name="input_node_storage_remainder_path"></a> [node\_storage\_remainder\_path](#input\_node\_storage\_remainder\_path) | If the runtime & kubernetes sizes do not add up to 100(%), otc wants to know where/how to mount the remaining space. Note that there are forbidden paths, see otc-documentation for which paths are forbidden. | `string` | `null` | no |
| <a name="input_node_storage_runtime_size"></a> [node\_storage\_runtime\_size](#input\_node\_storage\_runtime\_size) | How much of the data disk (in percent) is reserved for the node runtime storage (i.e. docker images). OTC default is 90 | `number` | `null` | no |
| <a name="input_node_storage_size"></a> [node\_storage\_size](#input\_node\_storage\_size) | Size of the node system disk in GB | `number` | `100` | no |
| <a name="input_node_storage_type"></a> [node\_storage\_type](#input\_node\_storage\_type) | Type of node storage SATA, SAS or SSD | `string` | `"SATA"` | no |
| <a name="input_node_taints"></a> [node\_taints](#input\_node\_taints) | Node taints for the node pool | <pre>list(object({<br/>    effect = string<br/>    key    = string<br/>    value  = string<br/>  }))</pre> | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Common tag set for CCE resources | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster"></a> [cluster](#output\_cluster) | Complete configuration of the created CCE cluster. |
| <a name="output_cluster_credentials"></a> [cluster\_credentials](#output\_cluster\_credentials) | Collection of access credentials for the API server. (Some or all values will be an empty string if cluster\_ignore\_certificate\_clusters\_data or cluster\_ignore\_certificate\_users\_data is true) |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | UUID of the created CCE cluster. |
| <a name="output_cluster_lb_public_ip"></a> [cluster\_lb\_public\_ip](#output\_cluster\_lb\_public\_ip) | Public EIP address of the cluster API server. (will be an empty string if cluster\_public\_access is false or cluster\_ignore\_certificate\_clusters\_data is true) |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the created CCE cluster. |
| <a name="output_cluster_private_ip"></a> [cluster\_private\_ip](#output\_cluster\_private\_ip) | Private IP address of the cluster API server. (will be an empty string if cluster\_ignore\_certificate\_clusters\_data is true) |
| <a name="output_cluster_public_ip"></a> [cluster\_public\_ip](#output\_cluster\_public\_ip) | Public EIP address of the cluster API server. (will be an empty string if cluster\_public\_access is false or cluster\_ignore\_certificate\_clusters\_data is true) |
| <a name="output_kubeconfig"></a> [kubeconfig](#output\_kubeconfig) | Cluster credentials for the created CCE cluster in kubeconfig YAML format. (Some or all values will be an empty string if cluster\_ignore\_certificate\_clusters\_data or cluster\_ignore\_certificate\_users\_data is true) |
| <a name="output_kubeconfig_json"></a> [kubeconfig\_json](#output\_kubeconfig\_json) | Cluster credentials for the created CCE cluster in kubeconfig JSON format. (Some or all values will be an empty string if cluster\_ignore\_certificate\_clusters\_data or cluster\_ignore\_certificate\_users\_data is true) |
| <a name="output_kubeconfig_yaml"></a> [kubeconfig\_yaml](#output\_kubeconfig\_yaml) | Cluster credentials for the created CCE cluster in kubeconfig YAML format. (Some or all values will be an empty string if cluster\_ignore\_certificate\_clusters\_data or cluster\_ignore\_certificate\_users\_data is true) |
| <a name="output_node_pool_ids"></a> [node\_pool\_ids](#output\_node\_pool\_ids) | UUIDs of the cluster node pools. |
| <a name="output_node_pool_keypair_name"></a> [node\_pool\_keypair\_name](#output\_node\_pool\_keypair\_name) | Name of the keypair resource created in OTC for worker node pools. |
| <a name="output_node_pool_keypair_private_key"></a> [node\_pool\_keypair\_private\_key](#output\_node\_pool\_keypair\_private\_key) | Private key of the keypair resource created in OTC for worker node pools. |
| <a name="output_node_pool_keypair_public_key"></a> [node\_pool\_keypair\_public\_key](#output\_node\_pool\_keypair\_public\_key) | Public key of the keypair resource created in OTC for worker node pools. |
| <a name="output_node_pools"></a> [node\_pools](#output\_node\_pools) | Complete configurations of the created node pools. |
| <a name="output_node_pools_names"></a> [node\_pools\_names](#output\_node\_pools\_names) | Names of the cluster node pools. |
| <a name="output_node_sg_id"></a> [node\_sg\_id](#output\_node\_sg\_id) | UUID of the security group for worker nodes. |
<!-- END_TF_DOCS -->
