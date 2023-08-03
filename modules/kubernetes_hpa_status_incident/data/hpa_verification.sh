bash
#!/bin/bash

# Define variables
CLUSTER_NAME=${CLUSTER_NAME}
NAMESPACE=${NAMESPACE}
RESOURCE_TYPE=${RESOURCE_TYPE}
RESOURCE_NAME=${RESOURCE_NAME}

# Verify that the HPA is correctly configured for the deployment or stateful set
HPA_MIN=$(kubectl -n $NAMESPACE get hpa -l "app.kubernetes.io/name=$RESOURCE_NAME" -o jsonpath='{.items[0].spec.minReplicas}')
HPA_MAX=$(kubectl -n $NAMESPACE get hpa -l "app.kubernetes.io/name=$RESOURCE_NAME" -o jsonpath='{.items[0].spec.maxReplicas}')

if [[ -z $HPA_MIN || -z $HPA_MAX ]]; then
  echo "Error: HPA is not configured for $RESOURCE_TYPE $RESOURCE_NAME in namespace $NAMESPACE"
  exit 1
fi

if (( $HPA_MIN < 1 || $HPA_MAX < $HPA_MIN )); then
  echo "Error: Invalid HPA configuration for $RESOURCE_TYPE $RESOURCE_NAME in namespace $NAMESPACE"
  exit 1
fi

echo "HPA is correctly configured for $RESOURCE_TYPE $RESOURCE_NAME in namespace $NAMESPACE. Min replicas: $HPA_MIN, Max replicas: $HPA_MAX"
exit 0