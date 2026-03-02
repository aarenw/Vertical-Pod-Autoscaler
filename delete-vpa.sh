#!/bin/bash

# 脚本功能：删除指定 OpenShift/Kubernetes 命名空间下的所有 Vertical Pod Autoscaler (VPA)。

# 检查 oc/kubectl 命令是否存在
if command -v oc &> /dev/null
then
    CMD="oc"
elif command -v kubectl &> /dev/null
then
    CMD="kubectl"
else
    echo "错误：未找到 'oc' 或 'kubectl' 命令。请确保已安装并配置好 Kubernetes 命令行工具。"
    exit 1
fi

NAMESPACE=""

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -n|--namespace)
        NAMESPACE="$2"
        shift # past argument
        shift # past value
        ;;
        *)
        echo "未知参数: $1"
        exit 1
        ;;
    esac
done

# 检查是否提供了命名空间
if [ -z "$NAMESPACE" ]; then
    echo "用法: $0 -n <命名空间>"
    echo "示例: $0 -n my-project"
    exit 1
fi

echo "开始删除命名空间 '$NAMESPACE' 下的所有 VPA..."

# 获取所有 VPA 资源名称
VPAS=$($CMD get vpa -n "$NAMESPACE" -o name 2>/dev/null)

if [ -z "$VPAS" ]; then
    echo "在命名空间 '$NAMESPACE' 中没有找到任何 VPA。"
    exit 0
fi

for VPA in $VPAS;
do
    VPA_NAME=$(echo $VPA | cut -d'/' -f2)
    echo "- 正在删除 VPA: $VPA_NAME"
    $CMD delete vpa "$VPA_NAME" -n "$NAMESPACE"
    if [ $? -ne 0 ]; then
        echo "  错误：删除 VPA '$VPA_NAME' 失败。"
    else
        echo "  成功删除 VPA '$VPA_NAME'。"
    fi
done

echo "\n所有 VPA 删除操作已完成。"
