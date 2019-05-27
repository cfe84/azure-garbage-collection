param($Timer)
$date=Get-Date
$expiryDate=$date.AddDays(14).ToString("yyyy-MM-dd")

Write-Host "Expiry date fixing triggered at $date"
$untouchedResources = Get-AzResourceGroup | Where-Object { $_.Tags.purpose -eq 'experiment' -and ! $_.Tags.expiry }
Foreach ($resourceGroup in $untouchedResources) {
    Write-Host "Adding expiry to $($resourceGroup.ResourceGroupName), set to $expiryDate"
    $tags = $resourceGroup.Tags
    $tags.Add("expiry", $expiryDate)
    Set-AzResourceGroup -Tag $tags -Name $resourceGroup.ResourceGroupName
}
Write-Host "Done adding expiry date"