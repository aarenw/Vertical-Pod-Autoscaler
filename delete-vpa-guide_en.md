# `delete-vpa.sh` Script Usage Guide
[中文版本](delete-vpa-guide.md)

This script aims to simplify the process of deleting Vertical Pod Autoscalers (VPA) in an OpenShift/Kubernetes cluster. It can delete all VPA resources in a specified namespace.

## Script Purpose

*   **Batch Delete VPA**: Quickly delete all VPA resources in a specified namespace.

## Usage

```bash
./delete-vpa.sh -n <namespace>
```

### Parameter Description

*   `-n` or `--namespace` (Required)
    *   **Description**: Specifies the target OpenShift/Kubernetes namespace from which VPA resources are to be deleted.
    *   **Example**: `-n my-project`

## Examples

1.  **Delete all VPAs in the `my-project` namespace:**
    ```bash
    ./delete-vpa.sh -n my-project
    ```

## Notes

*   **CLI Tools**: The script relies on `oc` (OpenShift CLI) or `kubectl` (Kubernetes CLI) commands. Ensure that one of these tools is installed and configured in your environment.
*   **Permissions**: The user running the script needs permissions to list and delete `VerticalPodAutoscaler` resources in the target namespace.
*   **Irreversible Operation**: Deleting VPAs is an irreversible operation. Please confirm the VPA resources you intend to delete before execution.
