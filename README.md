
### About Shoreline
The Shoreline platform provides real-time monitoring, alerting, and incident automation for cloud operations. Use Shoreline to detect, debug, and automate repairs across your entire fleet in seconds with just a few lines of code.

Shoreline Agents are efficient and non-intrusive processes running in the background of all your monitored hosts. Agents act as the secure link between Shoreline and your environment's Resources, providing real-time monitoring and metric collection across your fleet. Agents can execute actions on your behalf -- everything from simple Linux commands to full remediation playbooks -- running simultaneously across all the targeted Resources.

Since Agents are distributed throughout your fleet and monitor your Resources in real time, when an issue occurs Shoreline automatically alerts your team before your operators notice something is wrong. Plus, when you're ready for it, Shoreline can automatically resolve these issues using Alarms, Actions, Bots, and other Shoreline tools that you configure. These objects work in tandem to monitor your fleet and dispatch the appropriate response if something goes wrong -- you can even receive notifications via the fully-customizable Slack integration.

Shoreline Notebooks let you convert your static runbooks into interactive, annotated, sharable web-based documents. Through a combination of Markdown-based notes and Shoreline's expressive Op language, you have one-click access to real-time, per-second debug data and powerful, fleetwide repair commands.

### What are Shoreline Op Packs?
Shoreline Op Packs are open-source collections of Terraform configurations and supporting scripts that use the Shoreline Terraform Provider and the Shoreline Platform to create turnkey incident automations for common operational issues. Each Op Pack comes with smart defaults and works out of the box with minimal setup, while also providing you and your team with the flexibility to customize, automate, codify, and commit your own Op Pack configurations.

# Kubernetes HPA Status Incident
---

A Kubernetes HPA (Horizontal Pod Autoscaler) Status Incident refers to an issue where the autoscaling feature of Kubernetes, which automatically scales the number of pods in a replication controller, deployment, replica set or stateful set based on observed CPU utilization, is not functioning as expected. This can result in insufficient resources being provisioned to handle incoming load and potentially lead to service disruptions.

### Parameters
```shell
# Environment Variables
export NAMESPACE="PLACEHOLDER"
export HPA_NAME="PLACEHOLDER"
export POD_NAME="PLACEHOLDER"
export MAX_PODS="PLACEHOLDER"
export DEPLOYMENT_NAME="PLACEHOLDER"
export CLUSTER_NAME="PLACEHOLDER"
export RESOURCE_NAME="PLACEHOLDER"
export RESOURCE_TYPE="PLACEHOLDER"
export METRIC_THRESHOLD="PLACEHOLDER"
export METRIC_NAME="PLACEHOLDER"
```

## Debug

### Check the status of all HorizontalPodAutoscalers in the namespace
```shell
kubectl get hpa -n ${NAMESPACE}
```

### Check the status of a specific HorizontalPodAutoscaler in the namespace
```shell
kubectl describe hpa/${HPA_NAME} -n ${NAMESPACE}
```

### Check the status of all pods in the namespace
```shell
kubectl get pods -n ${NAMESPACE}
```

### Check the CPU and memory usage of a specific pod in the namespace
```shell
kubectl top pod ${POD_NAME} -n ${NAMESPACE}
```

### Check the logs of a specific pod in the namespace
```shell
kubectl logs ${POD_NAME} -n ${NAMESPACE}
```

### Check the status of the Kubernetes cluster metrics server
```shell
kubectl get deployment metrics-server -n kube-system
```

### Insufficient resources available in the cluster to support the desired number of pods.
```shell

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

```
## Repair
---
### Verify that the HPA is correctly configured for the deployment or stateful set in question, and that the minimum and maximum number of pods are set appropriately.
```shell
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

```

### Check the metrics used by the HPA to determine whether to scale up or down the number of pods. Ensure that the metrics are correctly defined and that they reflect the actual resource utilization of the pods.
```shell
bash
#!/bin/bash

# Define the variables
NAMESPACE=${NAMESPACE}
HPA_NAME=${HPA_NAME}
METRIC_NAME=${METRIC_NAME}
METRIC_THRESHOLD=${METRIC_THRESHOLD}

# Get the current status of the HPA
HPA_STATUS=$(kubectl get hpa $HPA_NAME -n $NAMESPACE -o jsonpath='{.status.conditions[0].status}')

# Check if the HPA is scaled up or down
if [[ "$HPA_STATUS" == "True" ]]; then
  echo "The HPA is scaled up."
else
  echo "The HPA is scaled down."
fi

# Get the current metrics used by the HPA
METRIC_VALUE=$(kubectl get hpa $HPA_NAME -n $NAMESPACE -o jsonpath="{.status.currentMetrics[?(@.type=='Object')].currentValue}")

# Check if the metrics are above the threshold
if (( $(echo "$METRIC_VALUE > $METRIC_THRESHOLD" | bc -l) )); then
  echo "The $METRIC_NAME metric is above the threshold."
else
  echo "The $METRIC_NAME metric is below the threshold."
fi

```

### If the metrics are not available or not working as expected, consider using alternative metrics to determine scaling. For example, you can use custom metrics or metrics from external monitoring systems.
```shell

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

```