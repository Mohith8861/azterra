function Check-Nodes {
    Write-Host "Checking Kubernetes Nodes..."
    $nodes = kubectl get nodes -o json | ConvertFrom-Json
    $allHealthy = $true

    foreach ($node in $nodes.items) {
        $status = $node.status.conditions | Where-Object { $_.type -eq "Ready" }
        if ($status.status -ne "True") {
            Write-Error "Node $($node.metadata.name) is not Ready."
            $allHealthy = $false
        } else {
            Write-Host "Node $($node.metadata.name) is healthy."
        }
    }

    if (-not $allHealthy) {
        exit 1
    }
}

function Check-Pods {
    Write-Host "Checking Kubernetes Pods..."
    $pods = kubectl get pods --all-namespaces -o json | ConvertFrom-Json
    $allHealthy = $true

    foreach ($pod in $pods.items) {
        $status = $pod.status.phase
        if ($status -ne "Running" -and $status -ne "Succeeded") {
            Write-Error "Pod $($pod.metadata.name) in namespace $($pod.metadata.namespace) is not healthy. Status: $status"
            $allHealthy = $false
        } else {
            Write-Host "Pod $($pod.metadata.name) in namespace $($pod.metadata.namespace) is healthy."
        }
    }

    if (-not $allHealthy) {
        exit 1
    }
}

Check-Nodes
Check-Pods
Write-Host "All Kubernetes components are healthy."
exit 0