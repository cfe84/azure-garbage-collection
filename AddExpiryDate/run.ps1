param($Timer)
$date=Get-Date
$defaultExpiryDays=[int]$env:DEFAULT_EXPIRY_DAYS
$expiryDate=$date.AddDays($defaultExpiryDays).ToString("yyyy-MM-dd")

Write-Host "Expiry date fixing triggered at $date"
Select-AzSubscription -Subscription $env:SUBSCRIPTION
$untouchedResources = Get-AzResourceGroup | Where-Object { ($_.Tags.purpose -eq 'experiment' -or $_.Tags.purpose -eq 'demo') -and ! $_.Tags.expiry }
Foreach ($resourceGroup in $untouchedResources) {
    Write-Host "Adding expiry to $($resourceGroup.ResourceGroupName), set to $expiryDate"
    $tags = $resourceGroup.Tags
    $tags.Add("expiry", $expiryDate)
    Set-AzResourceGroup -Tag $tags -Name $resourceGroup.ResourceGroupName
    $evt = [ordered]@{
        type="expiryAdded"
        group=$resourceGroup.ResourceGroupName
        expiry=$expiryDate
        date=$date
    }
    $jsonEvent = $evt | ConvertTo-Json -Depth 10
    Push-OutputBinding -Name "eventsQueue" -Value $jsonEvent
}
Write-Host "Done adding expiry date"