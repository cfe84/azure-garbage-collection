param($Timer)
$date=Get-Date

Write-Host "Garbage collection triggered at $date"
$expiredResources = Get-AzResourceGroup | Where-Object { $_.Tags.expiry -and [DateTime] $_.Tags.expiry -lt $date }
Foreach ($resourceGroup in $expiredResources) {
    Write-Host "Collecting $($resourceGroup.ResourceGroupName)"
    Remove-AzResourceGroup -Name $resourceGroup.ResourceGroupName -Force
}
Write-Host "Done collecting"