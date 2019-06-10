param($Timer)
$date=Get-Date
$defaultTag=$env:DEFAULT_TAG

Write-Host "Trying to auto-determine purpose at $date"
Select-AzSubscription -Subscription $env:SUBSCRIPTION
$untaggedResources = Get-AzResourceGroup | Where-Object { ! $_.Tags.purpose }
Foreach ($resourceGroup in $untaggedResources) {
    $tagToApply = $defaultTag
    $groupName = $resourceGroup.ResourceGroupName
    if ($resourceGroup.ResourceGroupName -match 'MC_*') {
        $mainResourceGroupName = $groupName.Substring(3)
        $indexOfBase = $mainResourceGroupName.IndexOf("_")
        if ($indexOfBase -ge 0) {
            $mainResourceGroupName = $mainResourceGroupName.Substring(0, $indexOfBase)
        }
        $mainResourceGroup = Get-AzResourceGroup -Name $mainResourceGroupName
        if ($mainResourceGroup) {
            $tagToApply = $mainResourceGroup.Tags.purpose
        } else {
            Write-Host "Ignoring $groupName - no main resource group found"
            continue
        }
    } elseif ($groupName -match 'prod*' `
        -or $groupName -match 'keep*' `
        -or $groupName -match 'Vsts*' `
        -or $groupName -match 'NetworkWatcherRG' `
        -or $groupName -match 'cloud-shell-storage*') {
        $tagToApply = "production"
    } elseif ($groupName -match 'exp*' `
        -or $groupName -match 'garbage*') {
        $tagToApply = "experiment"
    }
    Write-Host "Apply tag $tagToApply to group $groupName"
    $tags = $resourceGroup.Tags
    if (! $tags) {
        $tags = @{ purpose=$tagToApply }
    } else {
        $tags.Add("purpose", $tagToApply)
    }
    Set-AzResourceGroup -Tag $tags -Name $resourceGroup.ResourceGroupName
    $evt = [ordered]@{
        type="purposeAdded"
        group=$resourceGroup.ResourceGroupName
        purpose=$tagToApply
        date=$date
    }
    $jsonEvent = $evt | ConvertTo-Json -Depth 10
    Push-OutputBinding -Name "eventsQueue" -Value $jsonEvent
}
Write-Host "Done adding tags"