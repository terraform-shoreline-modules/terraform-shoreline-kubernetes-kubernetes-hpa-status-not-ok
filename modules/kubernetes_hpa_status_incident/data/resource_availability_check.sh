
#!/bin/bash

# Define variables
NAMESPACE=${NAMESPACE}
DEPLOYMENT=${DEPLOYMENT_NAME}
MAX_PODS=${MAX_PODS}

# Get the current number of replicas and pods
CURRENT_REPLICAS=$(kubectl get deployment $DEPLOYMENT -n $NAMESPACE -o=jsonpath='{.spec.replicas}')
CURRENT_PODS=$(kubectl get pods -n $NAMESPACE | grep $DEPLOYMENT | wc -l)

# Calculate the maximum number of pods that can be created based on available resources
MAX_AVAILABLE_PODS=$(kubectl describe nodes | grep "Allocatable pods" | awk '{print $3}')
MAX_AVAILABLE_PODS=$(($MAX_AVAILABLE_PODS/$MAX_PODS))

# Check if the current number of pods exceeds the maximum available pods
if [ $CURRENT_PODS -gt $MAX_AVAILABLE_PODS ]; then
    echo "Error: There are insufficient resources available in the Kubernetes cluster to support the desired number of pods."
    echo "Current replicas: $CURRENT_REPLICAS"
    echo "Current pods: $CURRENT_PODS"
    echo "Max available pods: $MAX_AVAILABLE_PODS"
else
    echo "Everything looks good! Current replicas: $CURRENT_REPLICAS, current pods: $CURRENT_PODS, max available pods: $MAX_AVAILABLE_PODS."
fi