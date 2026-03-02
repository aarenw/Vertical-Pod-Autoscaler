# `create-vpa.sh` 脚本使用指南
[English Version](create-vpa-guide_en.md)

该脚本旨在简化在 OpenShift/Kubernetes 集群中创建 Vertical Pod Autoscaler (VPA) 的过程。它能够为指定命名空间下的所有 `Deployment`、`StatefulSet` 和 `DaemonSet` 自动生成并应用 VPA 资源。

## 脚本目的

*   **自动化 VPA 创建**: 为多种类型的工作负载（Deployment, StatefulSet, DaemonSet）批量创建 VPA。
*   **灵活的更新模式**: 支持多种 VPA 更新策略，默认为 `Off` 模式，即仅提供资源建议而不自动修改 Pod。
*   **本地 YAML 保存**: 允许将生成的 VPA YAML 文件保存到本地目录，以便进行审查或手动应用。

## 使用方法

```bash
./create-vpa.sh -n <命名空间> [-m <UpdateMode>] [-o <输出目录>]
```

### 参数说明

*   `-n` 或 `--namespace` (必填)
    *   **描述**: 指定要在其中创建 VPA 资源的目标 OpenShift/Kubernetes 命名空间。
    *   **示例**: `-n my-project`

*   `-m` 或 `--mode` (可选)
    *   **描述**: 定义 VPA 的资源更新策略。这将直接映射到 VPA 资源的 `spec.updatePolicy.updateMode` 字段。
    *   **可选值**:
        *   `Off` (默认): VPA 仅计算并提供资源建议，但不会对 Pod 进行任何修改。**推荐初次使用或观察阶段使用。**
        *   `Auto`: VPA 会在运行时根据建议自动调整 Pod 的资源请求和限制。这可能导致 Pod 重启以应用新的资源配置。
        *   `Initial`: VPA 仅在 Pod 首次创建时应用建议的资源请求和限制，之后不再进行自动更新。
    *   **示例**: `-m Auto`

*   `-o` 或 `--output` (可选)
    *   **描述**: 指定一个本地目录路径。如果提供此参数，脚本将把所有生成的 VPA YAML 文件保存到该目录，而不是直接将其应用到集群。这对于在应用之前审查 VPA 配置非常有用。
    *   **示例**: `-o ./vpa-configs`

## 示例

1.  **为 `my-project` 命名空间中的所有工作负载创建 VPA (默认 `Off` 模式):**
    ```bash
    ./create-vpa.sh -n my-project
    ```

2.  **为 `my-project` 命名空间中的工作负载创建 `Auto` 模式的 VPA，并将 YAML 文件保存到 `./vpa-configs` 目录:**
    ```bash
    ./create-vpa.sh -n my-project -m Auto -o ./vpa-configs
    ```

3.  **为 `production` 命名空间中的工作负载创建 `Initial` 模式的 VPA:**
    ```bash
    ./create-vpa.sh -n production -m Initial
    ```

## 注意事项

*   **CLI 工具**: 脚本依赖 `oc` (OpenShift CLI) 或 `kubectl` (Kubernetes CLI) 命令。请确保您的环境中已安装并配置好其中一个工具。
*   **权限**: 运行脚本的用户需要具备在目标命名空间中创建和列出 `Deployment`、`StatefulSet`、`DaemonSet` 以及 `VerticalPodAutoscaler` 资源的权限。
*   **资源限制**: 脚本生成的 VPA 默认包含 `resourcePolicy`，为容器设置了 `cpu: 50m - 2` 和 `memory: 64Mi - 2Gi` 的建议范围。您可以根据实际需求调整这些默认值。
