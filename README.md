# Harbor Infrastructure Deployment Guide

by Robert Fischer, fischer3.net

This repository contains Terragrunt configurations for deploying Harbor Registry infrastructure with S2C2F compliance. The deployment is structured to minimize dependency errors and Terragrunt crashes during apply and destroy operations.

## Project Structure

```
harbor-infrastructure/
├── environments/
│   ├── dev/
│   │   ├── kms/
│   │   ├── vpc/
│   │   ├── s3/
│   │   ├── efs/
│   │   ├── rds/
│   │   ├── waf/
│   │   ├── eks/
│   │   ├── harbor/
│   │   └── cloudflare/
│   ├── staging/
│   └── prod/
├── modules/
│   ├── kms/
│   ├── vpc/
│   ├── s3/
│   ├── efs/
│   ├── rds/
│   ├── waf/
│   ├── eks/
│   ├── harbor/
│   ├── cloudflare/
│   └── cleanup/
└── scripts/
    ├── deploy.sh
    ├── destroy.sh
    └── update-dependencies.sh
```

## Prerequisites

- Terraform >= 1.3.0
- Terragrunt >= 0.42.0
- AWS CLI configured with appropriate permissions
- kubectl
- helm

## Setup

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd harbor-infrastructure
   ```

2. Initialize the repository:
   ```bash
   make init
   ```

3. Update dependencies for your target environment:
   ```bash
   make update-dependencies ENV=dev
   ```

## Deployment

We've structured the deployment process to follow a sequential approach, ensuring that dependencies are created in the correct order and avoiding Terragrunt crashes. The deployment is split into layers:

- Layer 1: Infrastructure Foundation (KMS, VPC)
- Layer 2: Storage & Database (S3, EFS, RDS)
- Layer 3: Compute & Security (WAF, EKS)
- Layer 4: Application (Harbor, Cloudflare)

### Deploying an Environment

To deploy the complete stack to a specific environment:

```bash
# For dev environment
make apply-dev

# For staging environment
make apply-staging

# For production environment (requires confirmation)
make apply-prod
```

These commands will run the `deploy.sh` script, which handles the layer-by-layer deployment of resources with appropriate wait conditions.

## Destroying Resources

Destruction of resources follows the reverse order of deployment to ensure dependencies are properly handled. The script waits for critical resources like EKS and RDS to be fully terminated before proceeding.

### Destroying an Environment

```bash
# For dev environment
make destroy-dev

# For staging environment (requires confirmation)
make destroy-staging

# For production environment (requires confirmation with specific text)
make destroy-prod
```

### Pre-destroy Cleanup

For EKS clusters, you may want to perform pre-destroy cleanup to remove Kubernetes resources that might block the deletion:

```bash
make cleanup ENV=dev
```

Then run the destroy command:

```bash
make destroy-dev
```

### Emergency Force Destroy

In case of persistent errors during normal destroy operations, you can use the force destroy option (use with caution):

```bash
make force-destroy-dev
```

## Handling Common Issues

### VPC Deletion Failures

If you encounter issues with VPC deletion due to dependencies:

1. Ensure all ELBs and NLBs are deleted
2. Check for any remaining ENIs in the VPC
3. Confirm all NAT Gateways are deleted

### EKS Cluster Deletion Hangs

Create and apply the cleanup module:

```bash
make cleanup ENV=dev
```

This will run a pre-destroy script to clean up Kubernetes resources that may block deletion.

### S3 Bucket Deletion Failures

For non-production environments, buckets have `force_destroy = true`. For production, you'll need to manually empty them before destruction.

## Dependency Management

The dependency graph is explicitly defined in each module's `terragrunt.hcl` file to ensure that resources are created and destroyed in the correct order. The `update-dependencies.sh` script helps manage these dependencies.

If you need to update the dependencies:

```bash
make update-dependencies ENV=dev
```

## Customization

To customize the deployment for your specific needs, modify the relevant environment variables in:

- `environments/{env}/terragrunt.hcl` - Environment-specific variables
- `environments/{env}/{module}/terragrunt.hcl` - Module-specific inputs

## Troubleshooting

Check the deployment and destruction logs in the `logs/` directory for detailed error messages.

### Common Errors

1. **Dependency Cycle**: If you encounter a dependency cycle error, review your terragrunt.hcl files and ensure there are no circular dependencies.

2. **State Lock**: If a terragrunt apply/destroy operation is interrupted, you might need to release the state lock:
   ```bash
   aws dynamodb delete-item --table-name harbor-terraform-locks --key '{"LockID":{"S":"<lock-id>"}}'
   ```

3. **Resource Already Exists**: If resources already exist, you may need to import them into the state:
   ```bash
   cd environments/{env}/{module}
   terragrunt import <resource-address> <resource-id>
   ```

## Security Considerations

- All sensitive information should be managed through AWS Secrets Manager
- KMS keys are used for encryption of data at rest
- VPC endpoints are used for private communication with AWS services
- WAF rules are applied to protect the Harbor registry
- Network ACLs and security groups are configured with least privilege access



## MIT License

Copyright (c) 2025 Robert Fischer

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.