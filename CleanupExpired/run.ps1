param($Timer)
$date=Get-Date

Write-Host "Garbage collection triggered at $date"
Select-AzSubscription -Subscription $env:SUBSCRIPTION
$expiredResources = Get-AzResourceGroup | Where-Object { $_.Tags.expiry -and [DateTime] $_.Tags.expiry -lt $date }
Foreach ($resourceGroup in $expiredResources) {
    Write-Host "Collecting $($resourceGroup.ResourceGroupName)"
    Remove-AzResourceGroup -Name $resourceGroup.ResourceGroupName -Force
    $evt = [ordered]@{
        type="groupCollected"
        group=$resourceGroup.ResourceGroupName
        date=$date
    }
    $jsonEvent = $evt | ConvertTo-Json -Depth 10
    Push-OutputBinding -Name "eventsQueue" -Value $jsonEvent
}
Write-Host "Done collecting"

Write-Host "Warning about tomorrow's collection"
$defaultWarningDays=[int]$env:DEFAULT_WARNING_DAYS
$tomorrow=$date.AddDays(-$defaultWarningDays)
$resourcesAlmostExpired = Get-AzResourceGroup | Where-Object { $_.Tags.expiry -and [DateTime] $_.Tags.expiry -lt $tomorrow }
Foreach ($resourceGroup in $resourcesAlmostExpired) {
    $evt = [ordered]@{
        type="groupAboutToBeCollected"
        group=$resourceGroup.ResourceGroupName
        expiry=$resourceGroup.Tags.expiry
        date=$date
    }
    $jsonEvent = $evt | ConvertTo-Json -Depth 10
    Push-OutputBinding -Name "eventsQueue" -Value $jsonEvent
}
Write-Host "Done warning"