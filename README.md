# Product Context
[English Version](README_en.md)

在 OpenShift 中使用 **Vertical Pod Autoscaler (VPA)** Operator 可以自动调整 Pod 的资源请求（Requests）和限制（Limits），从而提高集群资源利用率并防止应用因内存不足（OOM）而崩溃。

以下是使用 VPA 的完整流程：

---

## 1. 安装 VPA Operator

在 OpenShift 中，最简单的方法是通过 **OperatorHub** 进行安装：

1. 登录 OpenShift Web 控制台。
2. 导航至 **Operators** -> **OperatorHub**。
3. 搜索 **"VerticalPodAutoscaler"**。
4. 点击安装（Install），保持默认设置（通常安装在 `openshift-vertical-pod-autoscaler` 命名空间）。
5. **关键步骤**：安装完成后，你需要创建一个 **VerticalPodAutoscalerController** 实例来启动 VPA 的三个核心组件（Recommender, Updater, Admission Plugin）。
* 在 **Installed Operators** 中找到 VPA Operator。
* 在 **VerticalPodAutoscalerController** 页签下点击 **Create Instance**。
* 使用默认名称 `default` 并点击 **Create**。



---

## 2. 配置 VPA 资源 (CR)

安装完成后，你需要为你想要优化的应用创建一个 `VerticalPodAutoscaler` 资源。

### 示例 YAML 配置

假设你有一个名为 `my-app` 的 Deployment：

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: my-app-vpa
  namespace: my-project
spec:
  # 指定要监控的目标对象
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: my-app
  # 更新策略
  updatePolicy:
    updateMode: "Auto" 
  # 资源约束（可选）
  resourcePolicy:
    containerPolicies:
      - containerName: 
        minAllowed:
          cpu: 100m
          memory: 128Mi
        maxAllowed:
          cpu: 1
          memory: 512Mi

```

### `updateMode` 的三种模式：

* **`Auto`（默认）**：VPA 会在创建时分配资源，并在 Pod 运行期间如果发现资源不匹配，会**重启** Pod 以应用新的资源建议。
* **`Recreate`**：只有在 Pod 重启（如手动重启或部署更新）时才会应用建议。
* **`Initial`**：仅在 Pod 第一次创建时分配建议的资源，之后不再更改。
* **`Off`**：仅提供建议（Recommendations），不自动更改任何资源。**推荐初次使用时先开启此模式观察。**

---

## 3. 验证与查看建议

应用 VPA 资源后，你可以通过命令行查看它给出的资源优化建议：

```bash
oc get vpa my-app-vpa -n my-project -o yaml

```

在输出的 `status.recommendation` 部分，你会看到四种指标：

* **Target**: 推荐的最佳资源值。
* **Lower Bound**: 建议的最小资源值（低于此值可能会影响性能）。
* **Upper Bound**: 建议的最大资源值。
* **Uncapped Target**: 如果不考虑 `resourcePolicy` 限制，VPA 推荐的值。

---

## 4. 使用注意事项

* **与 HPA 冲突**：不要在同一个 Pod 上同时针对 **CPU 或内存** 使用 VPA 和 Horizontal Pod Autoscaler (HPA)。如果非要同时使用，请确保 HPA 基于自定义指标（如每秒请求数），而 VPA 负责资源调整。
* **Pod 重启**：在 `Auto` 模式下，VPA 调整资源会导致 Pod 重启。请确保你的应用具备高可用性（多副本）且配置了合理的 `PodDisruptionBudget`。
* **监控数据**：VPA 依赖 `Metrics Server`。如果集群监控插件未正常工作，VPA 将无法获取数据提供建议。
* 在生产环境中，先开启 **观察模式**（updateMode: "Off"）可以让你在不触发 Pod 重启的情况下，通过 VPA 的数据分析找出应用真实的资源画像。
* VPA 需要大约 1-5 分钟 的时间来收集 Metrics Server 的历史数据并生成初步建议。
* VPA默认查看过去 8 天的 Prometheus/Metrics-server 历史数据。如果你的应用刚刚启动，建议运行 24 小时后再观察，这样数据会更精准（包含业务高峰期）。
* **唯一性原则**：一个 Pod 集合只能被一个 VPA 观察/控制。不要为同一个 Deployment 创建两个 VPA。
---

## 5. 辅助脚本 (Helper Scripts)

为了简化 VPA 的创建和删除过程，我们提供了两个辅助脚本。您可以点击以下链接查看详细使用指南：

*   [`create-vpa.sh` - 创建 VPA 脚本使用指南](create-vpa-guide.md)
*   [`delete-vpa.sh` - 删除 VPA 脚本使用指南](delete-vpa-guide.md)
