# Deb Downloader
This is a tool used for downloading .deb packages and their dependencies, and extracting them to a specified folder.
## Installation
```
make build-docker-ubuntu2204
```
## Usage
### Download .deb Package and Its Dependencies
Please replace `xxx` with the name of the .deb package you wish to download.
```
make PACKAGE_NAME=xxx download
```
### Extract the .deb Package
This command will extract the aforementioned .deb package into the `output/sysroot` folder.
```
make unpack
```
### Cleanup
```
make clean
```
