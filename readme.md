# 四川航空人力资源系统

## 分支说明

- develop 合并了开发特性的分支
- master 稳定的部署分支
- featrues_name 特性分支，feature是特性的名称
- refactor_feature 重构分支，feature是功能的名称

## 下次部署要运行的rake列表和说明

## 部署慢的原因

- 加载 master-slave 包
- 运行 rake init:permission 没有检测 permission.yml 文件是否改变
- 前端每次都需要编译替换，不论是否源代码是否真的修改
