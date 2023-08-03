
#!/bin/bash

# Define the necessary variables
NAMESPACE=${NAMESPACE}
DEPLOYMENT=${DEPLOYMENT_NAME}
METRIC=${METRIC_NAME}

# Check if the metrics are available
if kubectl top pods -n $NAMESPACE | grep $DEPLOYMENT | awk '{print $2}' | grep -qE '[0-9]'; then
  echo "Metrics for $DEPLOYMENT in namespace $NAMESPACE are available."
else
  echo "Metrics for $DEPLOYMENT in namespace $NAMESPACE are not available."
fi

# Check if the metrics are working as expected
if kubectl get hpa -n $NAMESPACE | grep $DEPLOYMENT | awk '{print $5}' | grep -qE '[0-9]'; then
  echo "Metrics for $DEPLOYMENT in namespace $NAMESPACE are working as expected."
else
  echo "Metrics for $DEPLOYMENT in namespace $NAMESPACE are not working as expected. Consider using alternative metrics."
  
  # Check if custom metrics are available
  if kubectl get --raw /apis/custom.metrics.k8s.io/v1beta1/ | grep -qE "$METRIC"; then
    echo "Custom metrics are available. Consider using these metrics for scaling."
  else
    echo "Custom metrics are not available. Consider using metrics from external monitoring systems."
  fi
fi