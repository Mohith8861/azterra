function Check-Nodes {
 Write-Host "Checking Kubernetes Nodes..."
 $nodes = kubectl get nodes --no-headers | ForEach-Object {
 $fields = $_ -split '\s+'
 [PSCustomObject]@{
 NodeName = $fields[0]
 Status = $fields[1]
 }
 }
 $allHealthy = $true
 foreach ($node in $nodes) {
     if ($node.Status -ne "Ready") {
 Write-Error "Node $($node.NodeName) is not healthy. Status: $($node.Status)"
 $allHealthy = $false
 } else {
 Write-Host "Node $($node.NodeName) is healthy."
 }
 }
 if (-not $allHealthy) {
 exit 1
 }
}

# Function to check the health of Kubernetes pods
function Check-Pods {
 Write-Host "Checking Kubernetes Pods..."
 $pods = kubectl get pods --all-namespaces --no-headers | ForEach-Object {
 $fields = $_ -split '\s+'
 [PSCustomObject]@{
 PodName = $fields[1]
 Status = $fields[2]
 }
 }
 $allHealthy = $true
 foreach ($pod in $pods) {
 if ($pod.Status -ne "Running" -and $pod.Status -ne "Completed") {
 Write-Error "Pod $($pod.PodName) is not healthy. Status: $($pod.Status)"
 $allHealthy = $false
 } else {
 Write-Host "Pod $($pod.PodName) is healthy."

  }
 }
 if (-not $allHealthy) {
 exit 1
 }
}
# Run the checks
Check-Nodes
Check-Pods
Write-Host "All Kubernetes components are healthy."
exit 0