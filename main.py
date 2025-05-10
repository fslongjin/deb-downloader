import argparse
import re
import subprocess
import time
import os

OUT_DIR = "output"
DEB_DIR = f"{OUT_DIR}/debs"
SYSROOT_DIR = f"{OUT_DIR}/sysroot"

def resolve_packages(package_name: str):
    print("Resolving all packages...")
    
    # Run the apt-rdepends command and capture its output
    result = subprocess.run(['apt-rdepends', '-d', package_name], capture_output=True, text=True)
    
    # Check if the command was successful
    if result.returncode != 0:
        print(f"Error resolving dependencies for {package_name}")
        return {}

    apt_rdepends_output = result.stdout
    
    # apt_rdepends_output = f"""
    # Reading package lists... Done
    # Building dependency tree... Done
    # Reading state information... Done
    # digraph packages {{
    # concentrate=true;
    # size="30,40";
    # "libc6" [shape=box];
    # "libc6" -> "libcrypt1";
    # "libc6" -> "libgcc-s1";
    # "libcrypt1" [shape=box];
    # "libcrypt1" -> "libc6";
    # "libgcc-s1" [shape=box];
    # "libgcc-s1" -> "gcc-12-base";
    # "libgcc-s1" -> "libc6";
    # "gcc-12-base" [shape=box];
    # }}
    # """
    
    # Regular expression to match package names
    package_pattern = re.compile(r'"([a-zA-Z0-9_-]+)"')
    
    # Find all package names in the output
    packages = package_pattern.findall(apt_rdepends_output)
    
    # 将 package_name 添加到数组开头
    packages.insert(0, package_name)

    # 对packages去重
    packages = list(set(packages))
    
    return packages

def download(args: argparse.Namespace):
    '''
    Download deb and its dependencies
    
    '''
    package_name = args.name
    print(f"package_name: {package_name}")
    
    # resolve all packages
    packages = resolve_packages(package_name)
    print(f"packages: {packages}")
    
    # update
    subprocess.run(['apt', 'update'], check=True)
    # Download the packages using apt-
    packages_str = ' '.join(packages)
    try:
        subprocess.run('apt install --reinstall --download-only -y ' + packages_str, check=True, shell=True)
        print(f"Downloaded {packages_str}")
    except subprocess.CalledProcessError as e:
        print(f"Failed to download {packages_str}: {e}")

    # Move the downloaded packages to the DEB_DIR
    subprocess.run(['mkdir', '-p', DEB_DIR], check=True)
    
    subprocess.run('mv /var/cache/apt/archives/*.deb ' + DEB_DIR, check=True, shell=True)
    
    print(f"Downloaded {len(packages)} packages to {DEB_DIR}")

def unpack(args: argparse.Namespace):
    print("Executing unpack command")
    
    # 获取 DEB_DIR 下的所有 deb 文件列表
    deb_files = [f for f in os.listdir(DEB_DIR) if f.endswith('.deb')]
    
    for deb_file in deb_files:
        deb_path = os.path.join(DEB_DIR, deb_file)
        subprocess.run(['dpkg', '-x', deb_path, SYSROOT_DIR], check=True)

    print(f"Unpacked {len(deb_files)} packages to {SYSROOT_DIR}")

def clean(args: argparse.Namespace):
    print("Executing clean command")
    subprocess.run(['rm', '-rf', OUT_DIR], check=True)
    print(f"Cleaned up {OUT_DIR}")

def help_command(args: argparse.Namespace):
    print("""
Usage: main.py [options]

Options:
  --download  Download deb and its dependencies
  --unpack    Unpack downloaded files
  --clean     Clean up temporary files
  --help      Show this help message and exit
""")

def main():
    parser = argparse.ArgumentParser(description="deb downloader")
    subparsers = parser.add_subparsers(dest="command")

    # Subcommand: download
    download_parser = subparsers.add_parser("download", help="Download package")
    download_parser.add_argument("name", help="Name of the deb package")
    download_parser.set_defaults(func=download)

    # Subcommand: unpack
    unpack_parser = subparsers.add_parser("unpack", help="Unpack downloaded files")
    unpack_parser.set_defaults(func=unpack)

    # Subcommand: clean
    clean_parser = subparsers.add_parser("clean", help="Clean up temporary files")
    clean_parser.set_defaults(func=clean)

    # Subcommand: help
    help_parser = subparsers.add_parser("help", help="Show help message")
    help_parser.set_defaults(func=help_command)

    args = parser.parse_args()

    if args.command:
        args.func(args)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
