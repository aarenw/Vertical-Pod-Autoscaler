# `delete-vpa.sh` 脚本使用指南
[English Version](delete-vpa-guide_en.md)

该脚本旨在简化在 OpenShift/Kubernetes 集群中删除 Vertical Pod Autoscaler (VPA) 的过程。它能够删除指定命名空间下的所有 VPA 资源。

## 脚本目的

*   **批量删除 VPA**: 快速删除指定命名空间下的所有 VPA 资源。

## 使用方法

```bash
./delete-vpa.sh -n <命名空间>
```

### 参数说明

*   `-n` 或 `--namespace` (必填)
    *   **描述**: 指定要删除 VPA 资源的目标 OpenShift/Kubernetes 命名空间。
    *   **示例**: `-n my-project`

## 示例

1.  **删除 `my-project` 命名空间中的所有 VPA:**
    ```bash
    ./delete-vpa.sh -n my-project
    ```

## 注意事项

*   **CLI 工具**: 脚本依赖 `oc` (OpenShift CLI) 或 `kubectl` (Kubernetes CLI) 命令。请确保您的环境中已安装并配置好其中一个工具。
*   **权限**: 运行脚本的用户需要具备在目标命名空间中列出和删除 `VerticalPodAutoscaler` 资源的权限。
*   **不可逆操作**: 删除 VPA 是一个不可逆的操作。请在执行前确认您要删除的 VPA 资源。
