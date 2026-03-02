# Product Context
[中文版本](README.md)

Using the **Vertical Pod Autoscaler (VPA)** Operator in OpenShift automatically adjusts Pod resource requests (Requests) and limits (Limits), thereby improving cluster resource utilization and preventing applications from crashing due to out-of-memory (OOM) errors.

The complete process for using VPA is as follows:

---

## 1. Install VPA Operator

In OpenShift, the simplest method is to install it via **OperatorHub**:

1. Log in to the OpenShift Web Console.
2. Navigate to **Operators** -> **OperatorHub**.
3. Search for **"VerticalPodAutoscaler"**.
4. Click Install, keeping the default settings (usually installed in the `openshift-vertical-pod-autoscaler` namespace).
5. **Key Step**: After installation, you need to create a **VerticalPodAutoscalerController** instance to start VPA's three core components (Recommender, Updater, Admission Plugin).
* Find the VPA Operator in **Installed Operators**.
* Click **Create Instance** on the **VerticalPodAutoscalerController** tab.
* Use the default name `default` and click **Create**.

---

## 2. Configure VPA Resource (CR)

After installation, you need to create a `VerticalPodAutoscaler` resource for the application you want to optimize.

### Example YAML Configuration

Suppose you have a Deployment named `my-app`:

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: my-app-vpa
  namespace: my-project
spec:
  # Specify the target object to monitor
  targetRef:
    apiVersion: "apps/v1"
    kind: Deployment
    name: my-app
  # Update policy
  updatePolicy:
    updateMode: "Auto" 
  # Resource constraints (optional)
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

### Three `updateMode` Modes:

* **`Auto` (Default)**: VPA allocates resources upon creation, and if resource mismatches are found during Pod runtime, it will **restart** the Pod to apply new resource recommendations.
* **`Recreate`**: Recommendations are only applied when the Pod restarts (e.g., manual restart or deployment update).
* **`Initial`**: Recommended resources are only allocated when the Pod is first created, and no further changes are made thereafter.
* **`Off`**: Provides only recommendations (Recommendations), without automatically changing any resources. **Recommended to enable this mode first for observation.**

---

## 3. Verify and View Recommendations

After applying the VPA resource, you can view its resource optimization recommendations via the command line:

```bash
oc get vpa my-app-vpa -n my-project -o yaml

```

In the `status.recommendation` section of the output, you will see four metrics:

* **Target**: The recommended optimal resource value.
* **Lower Bound**: The suggested minimum resource value (below which performance may be affected).
* **Upper Bound**: The suggested maximum resource value.
* **Uncapped Target**: The value recommended by VPA without considering `resourcePolicy` limits.

---

## 4. Usage Notes

* **Conflict with HPA**: Do not use VPA and Horizontal Pod Autoscaler (HPA) simultaneously for **CPU or memory** on the same Pod. If you must use both, ensure HPA is based on custom metrics (e.g., requests per second), while VPA handles resource adjustments.
* **Pod Restart**: In `Auto` mode, VPA adjusting resources will cause Pod restarts. Ensure your application has high availability (multiple replicas) and is configured with an appropriate `PodDisruptionBudget`.
* **Monitoring Data**: VPA relies on `Metrics Server`. If the cluster monitoring plugin is not working correctly, VPA will not be able to obtain data to provide recommendations.
* In a production environment, enabling **Observation Mode** (`updateMode: "Off"`) first allows you to analyze your application`s true resource profile through VPA`s data without triggering Pod restarts.
---

## 5. Helper Scripts

To simplify the process of creating and deleting VPA, we provide two helper scripts. You can click the links below to view detailed usage guides:

*   [`create-vpa.sh` - Create VPA Script Usage Guide](create-vpa-guide_en.md)
*   [`delete-vpa.sh` - Delete VPA Script Usage Guide](delete-vpa-guide_en.md)
