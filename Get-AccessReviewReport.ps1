# Get-AccessReviewReport.ps1
# Pulls access review decisions and summarises outcomes

$reviewName = "Global-Reader-Group-Membership-Review"

# Find the access review definition by name
$definition = Get-MgIdentityGovernanceAccessReviewDefinition -All |
    Where-Object { $_.DisplayName -eq $reviewName }

if (-not $definition) {
    Write-Host "Review '$reviewName' not found." -ForegroundColor Red
    return
}

# Get the instance(s) of this review (a one-time review has a single instance)
$instances = Get-MgIdentityGovernanceAccessReviewDefinitionInstance -AccessReviewScheduleDefinitionId $definition.Id

foreach ($instance in $instances) {
    Write-Host "`nReview instance: $($instance.Id)"
    Write-Host "Status: $($instance.Status)"

    # Get decisions for this instance
    $decisions = Get-MgIdentityGovernanceAccessReviewDefinitionInstanceDecision `
        -AccessReviewScheduleDefinitionId $definition.Id `
        -AccessReviewInstanceId $instance.Id

    $report = foreach ($d in $decisions) {
        [PSCustomObject]@{
            PrincipalName = $d.Target.UserDisplayName
            Decision      = $d.Decision
            Justification = $d.Justification
            ReviewedBy    = $d.ReviewedBy.DisplayName
            ReviewedDate  = $d.ReviewedDateTime
        }
    }

    $report | Format-Table -AutoSize

    $report | Export-Csv -Path ".\AccessReview-Report.csv" -NoTypeInformation
    Write-Host "`nReport exported to AccessReview-Report.csv"
}