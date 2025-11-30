# /// script
# dependencies = ["pyyaml", "jinja2", "rich"]
# ///
"""TulaCMake Test Matrix Runner

Test-centric design: Each test is a first-class entity that can involve
any combination of packages. This decouples tests from packages and enables
multi-package integration tests.

Uses uv for dependency management (PEP 723).
"""

import argparse
import os
import subprocess
import sys
import yaml
from pathlib import Path
from datetime import datetime
from typing import List, Tuple, Dict, Optional
import json
from jinja2 import Environment, FileSystemLoader
from rich.console import Console


class TestRunner:
    """Manages test execution and result tracking."""
    
    def __init__(self, config_file: Path, verbose: bool = False):
        self.verbose = verbose
        self.console = Console()  # Rich console for colored output
        with open(config_file) as f:
            self.config = yaml.safe_load(f)
        
        self.test_dir = Path(__file__).parent
        self.tula_cmake_dir = self.test_dir.parent
        self.results_dir = self.test_dir / "results"
        self.timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.run_dir = self.results_dir / f"test_run_{self.timestamp}"
        self.logs_dir = self.run_dir / "logs"
        
        # Setup Jinja2 environment
        self.jinja_env = Environment(
            loader=FileSystemLoader(self.test_dir / "templates"),
            trim_blocks=True,
            lstrip_blocks=True
        )
        # Create results directory
        self.run_dir.mkdir(parents=True, exist_ok=True)
        self.logs_dir.mkdir(exist_ok=True)
        
        # Create symlink to latest
        latest_link = self.results_dir / "latest"
        if latest_link.exists():
            latest_link.unlink()
        latest_link.symlink_to(self.run_dir.name)
        
        self.results = []
    
    def get_enabled_tests(self) -> List[str]:
        """Get list of enabled tests from config."""
        return [
            test_id for test_id, test_info in self.config["tests"].items()
            if test_info.get("enabled", True)  # Enabled by default
        ]
    
    def get_test_info(self, test_id: str) -> dict:
        """Get test configuration."""
        return self.config["tests"].get(test_id, {})
    
    def get_test_timeout(self, test_id: str) -> int:
        """Get timeout for a test."""
        test_info = self.get_test_info(test_id)
        return test_info.get("timeout_seconds", 
                           self.config["global"]["timeout_seconds"])
    
    def get_test_packages(self, test_id: str) -> Dict[str, str]:
        """Get packages and their modes for a test."""
        test_info = self.get_test_info(test_id)
        return test_info.get("packages", {})
    
    def get_test_cmake_vars(self, test_id: str) -> Dict[str, str]:
        """Get CMake variables for a test."""
        test_info = self.get_test_info(test_id)
        return test_info.get("cmake_vars", {})
    
    def get_tests_in_group(self, group_name: str) -> List[str]:
        """Get list of tests in a test group."""
        group_info = self.config.get("test_groups", {}).get(group_name, {})
        tests = group_info.get("tests", [])
        
        if tests == "all":
            return self.get_enabled_tests()
        return tests
    
    def generate_test_project(self, test_id: str, build_config: str) -> Path:
        """Generate a test project for the given test."""
        test_info = self.get_test_info(test_id)
        packages = self.get_test_packages(test_id)
        
        # Use test_id as project name (sanitize for filesystem)
        project_name = test_id.replace("-", "_")
        # Include build_config in project directory to avoid conflicts between Debug/Release
        test_project_dir = self.logs_dir / f"{test_id}_{build_config.lower()}" / "project"
        test_project_dir.mkdir(parents=True, exist_ok=True)
        
        # Determine primary package (first one) for test template selection
        primary_package = list(packages.keys())[0] if packages else "generic"
        
        # Build package-specific variables for templates
        # For compatibility with single-package templates that use PACKAGE_NAME, PACKAGE_LOWER
        package_vars = {}
        for pkg_name in packages.keys():
            package_vars[f"{pkg_name}_LOWER"] = pkg_name.lower()
            package_vars[f"{pkg_name}_UPPER"] = pkg_name.upper()
        
        # Template context
        context = {
            "TEST_ID": test_id,
            "TEST_NAME": test_info.get("name", test_id),
            "PROJECT_NAME": project_name,
            "PROJECT_UPPER": project_name.upper(),
            "PACKAGES": packages,
            "PRIMARY_PACKAGE": primary_package,
            "BUILD_CONFIG": build_config,
            "CMAKE_VARS": self.get_test_cmake_vars(test_id),
            # For single-package compatibility (when only one package)
            "PACKAGE_NAME": primary_package,
            "PACKAGE_LOWER": primary_package.lower(),
            "PACKAGE_UPPER": primary_package.upper(),
        }
        # Merge package-specific vars
        context.update(package_vars)
        
        # Generate CMakeLists.txt
        cmake_template = self.jinja_env.get_template("package.cmake.j2")
        cmake_content = cmake_template.render(context)
        with open(test_project_dir / "CMakeLists.txt", 'w') as f:
            f.write(cmake_content)
        
        # Generate conanfile.py
        conan_template = self.jinja_env.get_template("conanfile.py.j2")
        conan_content = conan_template.render(context)
        with open(test_project_dir / "conanfile.py", 'w') as f:
            f.write(conan_content)
        
        # Generate test_main.cpp
        main_template = self.jinja_env.get_template("test_main.cpp.j2")
        main_content = main_template.render(context)
        with open(test_project_dir / "test_main.cpp", 'w') as f:
            f.write(main_content)
        
        return test_project_dir
    
    def run_test(self, test_id: str, build_config: str) -> Tuple[str, str, float]:
        """
        Run a single test case.
        
        Args:
            test_id: Test identifier
            build_config: Build configuration (Debug, Release)
        
        Returns: (status, error_message, duration)
        """
        test_info = self.get_test_info(test_id)
        packages = self.get_test_packages(test_id)
        
        self.console.print(f"[bold]Test:[/bold] {test_info.get('name', test_id)}")
        self.console.print(f"[bold]ID:[/bold] {test_id}")
        self.console.print(f"[bold]Packages:[/bold] {', '.join(f'{k} ({v})' for k, v in packages.items())}")
        
        start_time = datetime.now()
        # Include build_config in log directory path to avoid conflicts
        log_dir = self.logs_dir / f"{test_id}_{build_config.lower()}"
        log_dir.mkdir(parents=True, exist_ok=True)
        
        try:
            # Generate test project
            self.console.print("  [1/5] Generating test project...")
            project_dir = self.generate_test_project(test_id, build_config)
            
            # Create build directory (keeps Conan files separate from source)
            build_dir = project_dir / "cmake-build"
            build_dir.mkdir(exist_ok=True)
            
            # Conan install
            self.console.print("  [2/5] Running conan install...")
            
            # Build conan install command with package mode options
            # Use default-debug or default-release profile based on build config
            profile_name = f"default-{build_config.lower()}"
            profile_path = self.tula_cmake_dir / "profiles" / profile_name
            conan_cmd = [
                "conan", "install", str(project_dir),
                f"--profile:all={profile_path}",
                "--output-folder=.",  # Put generated files in current dir (build_dir)
            ]
            
            # Add package mode options
            for package, mode in packages.items():
                conan_cmd.extend(["-o", f"&:{package}={mode}"])
            
            conan_cmd.append("--build=missing")
            
            result = self._run_command(
                conan_cmd,
                cwd=build_dir,  # Run from build directory
                log_file=log_dir / "conan.log",
                timeout=self.get_test_timeout(test_id)
            )
            if not result:
                return "FAIL", "Conan install failed", self._duration(start_time)
            
            # CMake configure
            self.console.print("  [3/5] Running cmake configure...")
            
            # Use Conan-generated preset which contains CMAKE_BUILD_TYPE from profile
            preset_name = f"conan-clang-{build_config.lower()}"
            cmake_cmd = [
                "cmake", str(project_dir),
                "--preset", preset_name,
            ]
            
            # Add test-specific CMake variables
            for var_name, var_value in self.get_test_cmake_vars(test_id).items():
                cmake_cmd.append(f"-D{var_name}={var_value}")
            
            result = self._run_command(
                cmake_cmd,
                cwd=build_dir,
                log_file=log_dir / "cmake.log",
                timeout=60
            )
            if not result:
                return "FAIL", "CMake configure failed", self._duration(start_time)
            
            # CMake build
            self.console.print("  [4/5] Running cmake build...")
            result = self._run_command(
                ["cmake", "--build", ".", "-j", 
                 str(self.config["global"]["parallel_jobs"])],
                cwd=build_dir,
                log_file=log_dir / "build.log",
                timeout=self.get_test_timeout(test_id)
            )
            if not result:
                return "FAIL", "Build failed", self._duration(start_time)
            
            # Run executable
            self.console.print("  [5/5] Running test executable...")
            exe_name = f"test_{test_id.replace('-', '_')}"
            exe_path = build_dir / exe_name
            if not exe_path.exists():
                # Try with .exe extension on Windows
                exe_path = build_dir / f"{exe_name}.exe"
            
            if exe_path.exists():
                result = self._run_command(
                    [str(exe_path)],
                    cwd=build_dir,
                    log_file=log_dir / "run.log",
                    timeout=30
                )
                if not result:
                    return "FAIL", "Execution failed", self._duration(start_time)
            else:
                return "FAIL", f"Executable not found: {exe_path}", self._duration(start_time)
            
            duration = self._duration(start_time)
            self.console.print(f"  [green]✓ PASS[/green] [cyan]({duration:.1f}s)[/cyan]")
            return "PASS", "", duration
            
        except subprocess.TimeoutExpired:
            self.console.print("  [yellow]⏱ TIMEOUT[/yellow]")
            return "TIMEOUT", "Test exceeded timeout", self._duration(start_time)
        except Exception as e:
            self.console.print(f"  [red]✗ ERROR:[/red] {e}")
            return "FAIL", str(e), self._duration(start_time)
    
    def _run_command(self, cmd: List[str], cwd: Path, log_file: Path,
                    timeout: int) -> bool:
        """Run a command and log output."""
        # Force color output from build tools (CMake respects CLICOLOR_FORCE)
        env = dict(os.environ)
        env['CLICOLOR_FORCE'] = '1'
        
        try:
            with open(log_file, 'w') as f:
                if self.verbose:
                    # Tee output to both file and stdout
                    process = subprocess.Popen(
                        cmd,
                        cwd=cwd,
                        env=env,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.STDOUT,
                        text=True,
                        bufsize=1
                    )
                    assert process.stdout is not None
                    for line in process.stdout:
                        print(line, end='')
                        f.write(line)
                    
                    process.wait(timeout=timeout)
                    return process.returncode == 0
                else:
                    # Write only to file
                    result = subprocess.run(
                        cmd,
                        cwd=cwd,
                        env=env,
                        stdout=f,
                        stderr=subprocess.STDOUT,
                        timeout=timeout,
                        check=False
                    )
                    return result.returncode == 0
        except subprocess.TimeoutExpired:
            raise
        except Exception as e:
            with open(log_file, 'a') as f:
                f.write(f"\n\nException: {e}\n")
            return False
    
    def _duration(self, start_time: datetime) -> float:
        """Calculate duration in seconds."""
        return (datetime.now() - start_time).total_seconds()
    
    def run_matrix(self, test_ids: Optional[List[str]] = None,
                  build_configs: Optional[List[str]] = None) -> bool:
        """Run the test matrix."""
        # Get test list
        test_list: List[str] = test_ids if test_ids is not None else self.get_enabled_tests()
        
        # Get build config list
        config_list: List[str] = (
            build_configs if build_configs is not None 
            else self.config["global"]["build_configs"]
        )
        
        total_tests = len(test_list) * len(config_list)
        
        self.console.rule("[bold blue]TulaCMake Test Matrix[/bold blue]")
        self.console.print(f"[bold]Tests:[/bold] {len(test_list)}")
        self.console.print(f"[bold]Build configs:[/bold] {', '.join(config_list)}")
        self.console.print(f"[bold]Total tests:[/bold] {total_tests}")
        if self.verbose:
            self.console.print("[yellow]Mode:[/yellow] VERBOSE (showing all command output)")
        self.console.print(f"[bold]Results:[/bold] {self.run_dir}")
        self.console.rule()
        
        test_num = 0
        for test_id in test_list:
            for build_config in config_list:
                test_num += 1
                self.console.print(f"\n[cyan][{test_num}/{total_tests}][/cyan]")
                
                status, error, duration = self.run_test(test_id, build_config)
                
                test_info = self.get_test_info(test_id)
                self.results.append({
                    "test_id": test_id,
                    "test_name": test_info.get("name", test_id),
                    "packages": self.get_test_packages(test_id),
                    "config": build_config,
                    "status": status,
                    "error": error,
                    "duration": duration,
                })
                
                if not self.config["global"]["continue_on_failure"] and status == "FAIL":
                    self.console.print("\n[red]✗ Stopping on failure[/red]")
                    self._write_results()
                    return False
        
        self._write_results()
        return self._summarize_results()
    
    def _write_results(self):
        """Write test results to files."""
        # JSON results
        json_file = self.run_dir / "results.json"
        with open(json_file, 'w') as f:
            json.dump(self.results, f, indent=2)
        
        # CSV matrix
        csv_file = self.run_dir / "matrix.csv"
        with open(csv_file, 'w') as f:
            f.write("Test ID,Test Name,Packages,Config,Status,Duration(s),Error\n")
            for r in self.results:
                packages_str = "; ".join(f"{k}:{v}" for k, v in r['packages'].items())
                f.write(f"{r['test_id']},{r['test_name']},\"{packages_str}\","
                       f"{r['config']},{r['status']},{r['duration']:.1f},{r['error']}\n")
        
        # Summary text
        summary_file = self.run_dir / "summary.txt"
        with open(summary_file, 'w') as f:
            self._write_summary(f)
    
    def _summarize_results(self) -> bool:
        """Print and return summary of results."""
        self._write_summary(sys.stdout)
        
        # Return success if all tests passed
        return all(r["status"] == "PASS" for r in self.results)
    
    def _write_summary(self, file):
        """Write summary to file handle."""
        total = len(self.results)
        passed = sum(1 for r in self.results if r["status"] == "PASS")
        failed = sum(1 for r in self.results if r["status"] == "FAIL")
        timeout = sum(1 for r in self.results if r["status"] == "TIMEOUT")
        
        # Use Rich console for colored output to stdout, plain text for files
        if file == sys.stdout:
            self.console.rule("[bold blue]Test Summary[/bold blue]")
            self.console.print(f"[bold]Total tests:[/bold] {total}")
            pass_pct = 100*passed/total
            fail_pct = 100*failed/total
            timeout_pct = 100*timeout/total
            self.console.print(f"[green]✓ Passed:[/green]   {passed} [cyan]({pass_pct:.1f}%)[/cyan]")
            self.console.print(f"[red]✗ Failed:[/red]   {failed} [cyan]({fail_pct:.1f}%)[/cyan]")
            self.console.print(f"[yellow]⏱ Timeout:[/yellow]  {timeout} [cyan]({timeout_pct:.1f}%)[/cyan]")
            self.console.rule()
            
            if failed > 0:
                self.console.print("\n[bold red]Failed tests:[/bold red]")
                for r in self.results:
                    if r["status"] == "FAIL":
                        self.console.print(f"  - {r['test_name']} ({r['config']}): {r['error']}")
            
            if timeout > 0:
                self.console.print("\n[bold yellow]Timeout tests:[/bold yellow]")
                for r in self.results:
                    if r["status"] == "TIMEOUT":
                        self.console.print(f"  - {r['test_name']} ({r['config']})")
            
            self.console.print(f"\n[dim]Detailed logs: {self.logs_dir}[/dim]")
            self.console.print(f"[dim]Full results: {self.run_dir}[/dim]")
        else:
            # Plain text for files
            file.write(f"\n{'='*60}\n")
            file.write("Test Summary\n")
            file.write(f"{'='*60}\n")
            file.write(f"Total tests: {total}\n")
            file.write(f"Passed:   {passed} ({100*passed/total:.1f}%)\n")
            file.write(f"Failed:   {failed} ({100*failed/total:.1f}%)\n")
            file.write(f"Timeout:  {timeout} ({100*timeout/total:.1f}%)\n")
            file.write(f"{'='*60}\n")
            
            if failed > 0:
                file.write("\nFailed tests:\n")
                for r in self.results:
                    if r["status"] == "FAIL":
                        file.write(f"  - {r['test_name']} ({r['config']}): {r['error']}\n")
            
            if timeout > 0:
                file.write("\nTimeout tests:\n")
                for r in self.results:
                    if r["status"] == "TIMEOUT":
                        file.write(f"  - {r['test_name']} ({r['config']})\n")
            
            file.write(f"\nDetailed logs: {self.logs_dir}\n")
            file.write(f"Full results: {self.run_dir}\n")


def main():
    console = Console()  # Create console for main function
    parser = argparse.ArgumentParser(
        description="Run TulaCMake test matrix (test-centric design)"
    )
    parser.add_argument(
        "--test",
        help="Run specific test by ID"
    )
    parser.add_argument(
        "--group",
        help="Run test group (quick, integration, full, etc.)"
    )
    parser.add_argument(
        "--config",
        choices=["Debug", "Release"],
        help="Test specific build config only"
    )
    parser.add_argument(
        "--list-tests",
        action="store_true",
        help="List all available tests"
    )
    parser.add_argument(
        "--list-groups",
        action="store_true",
        help="List all test groups"
    )
    parser.add_argument(
        "--config-file",
        default="test_config.yaml",
        help="Path to test configuration file"
    )
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Show all command output in real-time (for debugging)"
    )
    
    args = parser.parse_args()
    
    # Get paths
    test_dir = Path(__file__).parent
    config_file = test_dir / args.config_file
    
    if not config_file.exists():
        console.print(f"[red]Error:[/red] Config file not found: {config_file}")
        return 1
    
    # Create test runner
    runner = TestRunner(config_file, verbose=args.verbose)
    
    # List tests or groups if requested
    if args.list_tests:
        console.print("[bold]Available tests:[/bold]")
        for test_id in runner.get_enabled_tests():
            test_info = runner.get_test_info(test_id)
            packages = runner.get_test_packages(test_id)
            pkg_str = ', '.join(f"{k} ({v})" for k, v in packages.items())
            console.print(f"  {test_id:25} - {test_info.get('name', '')} [{pkg_str}]")
        return 0
    
    if args.list_groups:
        console.print("[bold]Available test groups:[/bold]")
        for group_name, group_info in runner.config.get("test_groups", {}).items():
            console.print(f"  {group_name:15} - {group_info.get('description', '')}")
        return 0
    
    # Build test list
    if args.test:
        test_ids = [args.test]
    elif args.group:
        test_ids = runner.get_tests_in_group(args.group)
    else:
        # Default: run all enabled tests
        test_ids = runner.get_enabled_tests()
    
    # Build config list
    build_configs = [args.config] if args.config else None
    
    # Run tests
    success = runner.run_matrix(
        test_ids=test_ids,
        build_configs=build_configs
    )
    
    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
