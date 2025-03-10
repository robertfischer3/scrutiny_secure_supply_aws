#!/usr/bin/env python3
"""
Terragrunt VPC Module Test Script

This script automates testing of Terragrunt VPC module deployment.
It performs initialization, validation, planning, and optional apply/destroy
operations with proper logging and error handling.
"""

import argparse
import datetime
import json
import logging
import os
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Union

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(f"terragrunt_vpc_test_{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.log")
    ]
)
logger = logging.getLogger(__name__)

class TerragruntTester:
    """Class to handle terragrunt testing operations"""
    
    def __init__(
        self, 
        module_path: str, 
        environment: str = "dev", 
        clear_cache: bool = True,
        output_dir: str = "test_output"
    ):
        """
        Initialize the tester
        
        Args:
            module_path: Path to the terragrunt module directory
            environment: Environment to test (dev, staging, prod)
            clear_cache: Whether to clear the terragrunt cache before testing
            output_dir: Directory to store test outputs
        """
        self.module_path = Path(module_path)
        self.environment = environment
        self.clear_cache = clear_cache
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        self.plan_file = self.output_dir / f"vpc_{environment}_plan.tfplan"
        
        # Verify the module directory exists
        if not self.module_path.exists() or not self.module_path.is_dir():
            raise ValueError(f"Module path {self.module_path} does not exist or is not a directory")
        
        # Check if terragrunt is installed
        self._check_terragrunt_installed()
    
    def _check_terragrunt_installed(self) -> None:
        """Check if terragrunt is installed and available in PATH"""
        try:
            subprocess.run(
                ["terragrunt", "--version"], 
                capture_output=True, 
                check=True
            )
        except (subprocess.SubprocessError, FileNotFoundError):
            logger.error("Terragrunt is not installed or not found in PATH")
            raise RuntimeError("Terragrunt is required but not installed")
    
    def _run_command(
        self, 
        cmd: List[str], 
        capture_output: bool = True
    ) -> Tuple[bool, Optional[str], Optional[str]]:
        """
        Run a shell command and handle errors
        
        Args:
            cmd: Command to run as a list of strings
            capture_output: Whether to capture command output
            
        Returns:
            Tuple of (success, stdout, stderr)
        """
        logger.info(f"Running command: {' '.join(cmd)}")
        
        try:
            result = subprocess.run(
                cmd,
                cwd=self.module_path,
                capture_output=capture_output,
                text=True,
                check=False
            )
            success = result.returncode == 0
            
            if not success:
                logger.error(f"Command failed with exit code {result.returncode}")
                if capture_output:
                    logger.error(f"STDERR: {result.stderr}")
            
            return success, result.stdout if capture_output else None, result.stderr if capture_output else None
        
        except Exception as e:
            logger.error(f"Error executing command: {e}")
            return False, None, str(e)
    
    def clear_terragrunt_cache(self) -> bool:
        """Clear the terragrunt cache directory"""
        if self.clear_cache:
            cache_dir = self.module_path / ".terragrunt-cache"
            
            if cache_dir.exists():
                logger.info(f"Clearing terragrunt cache at {cache_dir}")
                try:
                    # Using subprocess for better cross-platform compatibility with complex directory structures
                    rm_cmd = ["rm", "-rf", str(cache_dir)]
                    success, _, _ = self._run_command(rm_cmd)
                    return success
                except Exception as e:
                    logger.error(f"Error clearing terragrunt cache: {e}")
                    return False
            else:
                logger.info("No terragrunt cache found to clear")
                return True
        return True
    
    def init(self) -> bool:
        """Initialize terragrunt"""
        logger.info("Initializing terragrunt")
        
        # Clear cache first if enabled
        self.clear_terragrunt_cache()
        
        # Run terragrunt init
        init_cmd = ["terragrunt", "init", "--terragrunt-non-interactive"]
        success, stdout, stderr = self._run_command(init_cmd)
        
        if success:
            logger.info("Terragrunt initialization successful")
        
        return success
    
    def validate(self) -> bool:
        """Validate terragrunt configuration"""
        logger.info("Validating terragrunt configuration")
        
        validate_cmd = ["terragrunt", "validate"]
        success, stdout, stderr = self._run_command(validate_cmd)
        
        if success:
            logger.info("Terragrunt validation successful")
        
        return success
    
    def plan(self, detailed_exitcode: bool = True) -> Tuple[bool, bool]:
        """
        Run terragrunt plan
        
        Args:
            detailed_exitcode: Use detailed exit code (0=success, 1=error, 2=success with changes)
            
        Returns:
            Tuple of (success, has_changes)
        """
        logger.info("Running terragrunt plan")
        
        plan_cmd = ["terragrunt", "plan", "-out", str(self.plan_file)]
        
        if detailed_exitcode:
            plan_cmd.append("-detailed-exitcode")
        
        success, stdout, stderr = self._run_command(plan_cmd)
        
        # With detailed_exitcode, an exit code of 2 means success with changes
        has_changes = False
        if detailed_exitcode and not success:
            # Rerun the command to check if it's error code 2 (success with changes)
            result = subprocess.run(
                plan_cmd,
                cwd=self.module_path,
                capture_output=True,
                text=True,
                check=False
            )
            if result.returncode == 2:
                logger.info("Terragrunt plan successful (with changes)")
                has_changes = True
                success = True
        
        if success and not has_changes:
            logger.info("Terragrunt plan successful (no changes)")
        
        # Save the plan output to a file
        if stdout:
            plan_output_file = self.output_dir / f"vpc_{self.environment}_plan.txt"
            try:
                with open(plan_output_file, 'w') as f:
                    f.write(stdout)
                logger.info(f"Saved plan output to {plan_output_file}")
            except Exception as e:
                logger.error(f"Error saving plan output: {e}")
        
        return success, has_changes
    
    def apply(self, auto_approve: bool = False) -> bool:
        """
        Apply terragrunt plan
        
        Args:
            auto_approve: Whether to auto-approve the apply
            
        Returns:
            Whether the apply was successful
        """
        logger.info("Applying terragrunt plan")
        
        apply_cmd = ["terragrunt", "apply"]
        
        if auto_approve:
            apply_cmd.append("--auto-approve")
        else:
            # Use the saved plan file
            apply_cmd.append(str(self.plan_file))
        
        success, stdout, stderr = self._run_command(apply_cmd, capture_output=False)
        
        if success:
            logger.info("Terragrunt apply successful")
        
        return success
    
    def destroy(self, auto_approve: bool = False) -> bool:
        """
        Destroy terragrunt resources
        
        Args:
            auto_approve: Whether to auto-approve the destroy
            
        Returns:
            Whether the destroy was successful
        """
        logger.info("Destroying terragrunt resources")
        
        destroy_cmd = ["terragrunt", "destroy"]
        
        if auto_approve:
            destroy_cmd.append("--auto-approve")
        
        success, stdout, stderr = self._run_command(destroy_cmd, capture_output=False)
        
        if success:
            logger.info("Terragrunt destroy successful")
        
        return success
    
    def output(self) -> Optional[Dict]:
        """
        Get terragrunt outputs
        
        Returns:
            Dictionary of terragrunt outputs or None if failed
        """
        logger.info("Getting terragrunt outputs")
        
        output_cmd = ["terragrunt", "output", "-json"]
        success, stdout, stderr = self._run_command(output_cmd)
        
        if success and stdout:
            try:
                outputs = json.loads(stdout)
                logger.info(f"Retrieved {len(outputs)} outputs")
                
                # Save the outputs to a file
                output_file = self.output_dir / f"vpc_{self.environment}_output.json"
                try:
                    with open(output_file, 'w') as f:
                        json.dump(outputs, f, indent=2)
                    logger.info(f"Saved outputs to {output_file}")
                except Exception as e:
                    logger.error(f"Error saving outputs: {e}")
                
                return outputs
            except json.JSONDecodeError:
                logger.error("Failed to parse terragrunt outputs as JSON")
                return None
        
        return None
    
    def run_test(self, apply_changes: bool = False) -> bool:
        """
        Run complete test flow
        
        Args:
            apply_changes: Whether to apply changes if plan has changes
            
        Returns:
            Overall success status
        """
        logger.info(f"Starting terragrunt VPC module test for environment: {self.environment}")
        
        # Step 1: Initialize
        if not self.init():
            logger.error("Initialization failed, aborting test")
            return False
        
        # Step 2: Validate
        if not self.validate():
            logger.error("Validation failed, aborting test")
            return False
        
        # Step 3: Plan
        plan_success, has_changes = self.plan()
        if not plan_success:
            logger.error("Plan failed, aborting test")
            return False
        
        # Step 4: Apply (if requested and there are changes)
        if apply_changes and has_changes:
            if not self.apply(auto_approve=True):
                logger.error("Apply failed")
                return False
            
            # Get outputs after successful apply
            self.output()
        
        logger.info(f"Terragrunt VPC module test completed successfully for environment: {self.environment}")
        return True

def main():
    """Main function to parse args and run the test"""
    parser = argparse.ArgumentParser(description="Test Terragrunt VPC module deployment")
    parser.add_argument("--module-path", required=True,
                        help="Path to the terragrunt VPC module directory")
    parser.add_argument("--environment", default="dev",
                        help="Environment to test (dev, staging, prod)")
    parser.add_argument("--apply", action="store_true",
                        help="Apply changes if plan has changes")
    parser.add_argument("--destroy", action="store_true",
                        help="Destroy resources after apply (only if --apply is also set)")
    parser.add_argument("--no-clear-cache", action="store_true",
                        help="Don't clear terragrunt cache before testing")
    parser.add_argument("--output-dir", default="test_output",
                        help="Directory to store test outputs")
    
    args = parser.parse_args()
    
    try:
        tester = TerragruntTester(
            module_path=args.module_path,
            environment=args.environment,
            clear_cache=not args.no_clear_cache,
            output_dir=args.output_dir
        )
        
        success = tester.run_test(apply_changes=args.apply)
        
        if success and args.apply and args.destroy:
            logger.info("Test successful, now destroying resources as requested")
            tester.destroy(auto_approve=True)
        
        sys.exit(0 if success else 1)
    
    except Exception as e:
        logger.exception(f"Unhandled exception: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()