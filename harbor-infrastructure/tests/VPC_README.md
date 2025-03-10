# Terragrunt VPC Module Test

This Python script automates testing of the Terragrunt VPC module deployment for the Harbor S2C2F infrastructure. It provides a structured approach to validate VPC configurations before applying them to various environments.

## Overview

The `test_terragrunt_vpc.py` script performs a series of operations to validate and test the Terragrunt VPC module:

1. **Initialize** the Terragrunt module
2. **Validate** the configuration
3. **Plan** the infrastructure changes
4. Optionally **apply** the changes
5. Optionally **destroy** the resources after testing
6. Export **outputs** for verification

## Prerequisites

- Python 3.6+
- Terragrunt installed and available in PATH
- AWS credentials configured (via environment variables, AWS CLI profile, etc.)
- Proper permissions to create/destroy AWS VPC resources

## Installation

No special installation is needed beyond the prerequisites. Simply download the script to your local environment or clone the repository.

## Usage

```bash
python test_terragrunt_vpc.py --module-path PATH_TO_VPC_MODULE [options]
```

### Required Arguments

- `--module-path`: Path to the terragrunt VPC module directory (e.g., `harbor-infrastructure/environments/dev/vpc`)

### Optional Arguments

- `--environment`: Environment to test (dev, staging, prod). Default: `dev`
- `--apply`: Apply changes if plan has changes. Default: `False`
- `--destroy`: Destroy resources after apply (only if `--apply` is also set). Default: `False`
- `--no-clear-cache`: Don't clear terragrunt cache before testing. Default: Clear cache
- `--output-dir`: Directory to store test outputs. Default: `test_output`

## Examples

### Validate Configuration Only

```bash
python test_terragrunt_vpc.py --module-path harbor-infrastructure/environments/dev/vpc
```

This will initialize, validate, and plan the VPC module without applying any changes.

### Test with Apply and Cleanup

```bash
python test_terragrunt_vpc.py --module-path harbor-infrastructure/environments/dev/vpc --apply --destroy
```

This will initialize, validate, plan, apply the changes, and then destroy the resources after successful application.

### Test in Staging Environment

```bash
python test_terragrunt_vpc.py --module-path harbor-infrastructure/environments/staging/vpc --environment staging
```

## Output Files

The script generates the following output files in the specified output directory:

- `vpc_ENV_plan.tfplan`: The Terragrunt plan file
- `vpc_ENV_plan.txt`: Human-readable plan output
- `vpc_ENV_output.json`: Outputs from the module (if apply was run)
- `terragrunt_vpc_test_TIMESTAMP.log`: Log file with all operations and results

## Logging

The script logs all operations to both the console and a timestamped log file. This helps with debugging and provides an audit trail of the test run.

## Error Handling

The script includes comprehensive error handling:

- Validates that Terragrunt is installed
- Checks that the module path exists
- Captures and logs all command outputs
- Provides clear error messages for failed operations

## Integration with CI/CD

This script is designed to be easily integrated into CI/CD pipelines. The exit code will be `0` for success and `1` for any failures, making it suitable for automated testing workflows.

## Best Practices

- Run with `--apply --destroy` in development and testing environments to ensure resources are cleaned up
- Save the generated plan files for review before applying in production environments
- Review the log files to understand any failures or unexpected behaviors

## Troubleshooting

If you encounter issues:

1. Check the log file for detailed error messages
2. Verify AWS credentials are correctly configured
3. Ensure you have the necessary permissions in the AWS account
4. Check that the Terragrunt module path is correct and contains valid configuration

## Contributing

Contributions to improve the script are welcome. Please follow these steps:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This script is provided under the MIT License. See the LICENSE file for details.