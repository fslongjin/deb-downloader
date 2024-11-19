# deb downloader

这是一个用来下载deb包及其依赖项，并解压到指定文件夹的工具

## 安装

```
make build-docker-ubuntu2204
```

## 使用

### 下载deb包及其依赖项

请将xxx替换成你要下载的deb包的名称

```
make PACKAGE_NAME=xxx download
```

### 解压deb包

这个命令将会把上述的deb包解压到`output/sysroot`文件夹中

```
make unpack
```

### 清理

```
make clean
```
