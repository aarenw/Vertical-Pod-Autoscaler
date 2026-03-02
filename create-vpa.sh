#!/bin/bash

# Script purpose: Create Vertical Pod Autoscalers (VPAs) for all Deployments, StatefulSets, and DaemonSets
# in a specified OpenShift/Kubernetes namespace.
# By default, VPA will use the 'Off' update mode, providing resource recommendations without automatically modifying Pods.
# The update mode can be specified as 'Auto' or 'Initial' via parameters.
# Optionally, generated VPA YAML files can be saved to a local directory instead of being applied directly to the cluster.

# Check if oc/kubectl command exists
if command -v oc &> /dev/null
then
    CMD="oc"
elif command -v kubectl &> /dev/null
then
    CMD="kubectl"
else
    echo "Error: Neither 'oc' nor 'kubectl' command found. Please ensure Kubernetes CLI tools are installed and configured."
    exit 1
fi

NAMESPACE=""
VPA_UPDATE_MODE="Off" # Default VPA update mode is Off
OUTPUT_DIR="" # Output directory; if specified, VPA YAML files will be saved locally.

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -n|--namespace)
        NAMESPACE="$2"
        shift # past argument
        shift # past value
        ;;
        -m|--mode)
        VPA_UPDATE_MODE="$2"
        shift # past argument
        shift # past value
        ;;
        -o|--output)
        OUTPUT_DIR="$2"
        shift # past argument
        shift # past value
        ;;
        *)
        echo "Unknown parameter: $1"
        exit 1
        ;;
    esac
done

# Check if a namespace was provided
if [ -z "$NAMESPACE" ]; then
    echo "Usage: $0 -n <namespace> [-m <UpdateMode>] [-o <output-directory>]"
    echo "Example: $0 -n my-project"
    echo "Example: $0 -n my-project -m Auto -o ./vpa-configs"
    echo "Optional UpdateModes: Off (default), Auto, Initial"
    exit 1
fi

# If an output directory is specified, create it
if [ -n "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create output directory \"$OUTPUT_DIR\". Please check permissions or path."
        exit 1
    fi
    echo "VPA YAML files will be saved to local directory \"$OUTPUT_DIR\"."
else
    echo "Starting VPA creation for workloads in namespace \"$NAMESPACE\" (Update Mode: $VPA_UPDATE_MODE)..."
fi

# Get all Deployments, StatefulSets, and DaemonSets
RESOURCES=$($CMD get deployment,statefulset,daemonset -n "$NAMESPACE" -o name 2>/dev/null)

if [ -z "$RESOURCES" ]; then
    echo "No Deployments, StatefulSets, or DaemonSets found in namespace \"$NAMESPACE\"."
    exit 0
fi

for RESOURCE in $RESOURCES;
do
    # Extract resource type and name from "deployment.apps/nginx"
    # RESOURCE_TYPE: content before the first '.' -> "deployment"
    RESOURCE_TYPE=$(echo $RESOURCE | cut -d"." -f1)
    
    # RESOURCE_NAME: content after the '/' -> "nginx"
    RESOURCE_NAME=$(echo $RESOURCE | cut -d'/' -f2)
    
    # Construct VPA name: type-name-vpa (e.g., deployment-nginx-vpa)
    VPA_NAME="${RESOURCE_TYPE}-${RESOURCE_NAME}-vpa"

    # Map to case-sensitive Kubernetes Kind
    TARGET_KIND=""
    case $RESOURCE_TYPE in
        deployment)
            TARGET_KIND="Deployment"
            ;;
        statefulset)
            TARGET_KIND="StatefulSet"
            ;;
        daemonset)
            TARGET_KIND="DaemonSet"
            ;;
        *)
            # Fallback to capitalize first letter for unknown types (should be rare, but as a safeguard)
            TARGET_KIND="${RESOURCE_TYPE^}"
            ;;
    esac

    echo "- Generating VPA \"$VPA_NAME\" for $RESOURCE_TYPE/$RESOURCE_NAME (Kind: $TARGET_KIND)..."

    # Generate VPA YAML
    VPA_YAML=$(cat <<EOF
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: ${VPA_NAME}
  namespace: ${NAMESPACE}
spec:
  targetRef:
    apiVersion: apps/v1
    kind: ${TARGET_KIND}
    name: ${RESOURCE_NAME}
  updatePolicy:
    updateMode: "${VPA_UPDATE_MODE}"
  resourcePolicy:
    containerPolicies:
      - containerName: '*'
        controlledResources:
          - cpu
          - memory
        minAllowed:
          cpu: 50m
          memory: 64Mi
        maxAllowed:
          cpu: 2
          memory: 2Gi          
EOF
)

    # If an output directory is specified, save the YAML file locally
    if [ -n "$OUTPUT_DIR" ]; then
        FILE_PATH="${OUTPUT_DIR}/${VPA_NAME}.yaml"
        echo "$VPA_YAML" > "$FILE_PATH"
        if [ $? -eq 0 ]; then
            echo "  VPA YAML saved to: $FILE_PATH"
        else
            echo "  Error: Failed to save VPA YAML to file $FILE_PATH."
        fi
    else
        # Otherwise, apply directly to the cluster
        echo "$VPA_YAML" | $CMD apply -f -
        if [ $? -eq 0 ]; then
            echo "  Successfully created/updated VPA \"$VPA_NAME\"."
        else
            echo "  Error: Failed to create/update VPA \"$VPA_NAME\"."
        fi
    fi
done

if [ -n "$OUTPUT_DIR" ]; then
    echo "\nAll VPA YAML files have been saved to directory \"$OUTPUT_DIR\"."
else
    echo "\nAll VPA creation/update operations completed."
fi
