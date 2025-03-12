# Harbor Infrastructure with S2C2F Compliance

by Robert Fischer, [fischer3.net](https://fischer3.net)

A production-ready deployment of Harbor container registry on AWS, built with Terragrunt. This infrastructure-as-code implementation follows Security, Scalability, Compliance, Continuity, and Flexibility (S2C2F) principles to deliver an enterprise-grade container registry. The architecture features multi-environment support, KMS encryption, WAF protection, high availability with multi-AZ deployments, and comprehensive audit capabilities—all orchestrated through modular Terraform configurations that ensure consistent and repeatable deployments across development, staging, and production environments.

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

## Quick Start

1. Clone this repository:

   ```bash
   git clone <repository-url>
   cd harbor-infrastructure
   ```

2. Initialize the repository:

   ```bash
   make init
   ```

3. Deploy to the development environment:

   ```bash
   make apply-dev
   ```

## Deployment Layers

The infrastructure is deployed in sequential layers to manage dependencies:

1. **Foundation Layer**: Identity, KMS, and VPC networking
2. **Storage Layer**: S3, EFS, and RDS database
3. **Compute Layer**: EKS cluster and WAF protection
4. **Application Layer**: Harbor registry and Cloudflare integration

## Security Features

- KMS encryption for all data at rest
- S3 bucket with randomized names and versioning
- WAF rules to protect against common attacks
- Private subnets with controlled access
- IAM roles with least-privilege permissions
- VPC endpoints for secure AWS service access

## Customization

Modify environment-specific variables in:

- `environments/{env}/terragrunt.hcl`
- `environments/{env}/{module}/terragrunt.hcl`

## Documentation

For detailed documentation, please see:

- [Deployment Guide](docs/deployment.md)
- [Architecture Overview](docs/architecture.md)
- [Security Considerations](docs/security.md)
- [Harbor Configuration](docs/harbor-config.md)

## License

MIT License. See [LICENSE](license.txt) for details.

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