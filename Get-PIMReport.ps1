# Get-PIMReport.ps1
# Pulls eligible + active Entra role assignments and flags long-running active ones

$ThresholdHours = 4

# Get eligible role assignments (who *can* activate what)
$eligible = Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -All

# Get active role assignments (who currently *has* an active assignment)
$active = Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance -All

# Build a readable report for active assignments
$report = foreach ($a in $active) {
    $principal = Get-MgDirectoryObject -DirectoryObjectId $a.PrincipalId
    $roleDef   = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $a.RoleDefinitionId

    $startTime = $a.StartDateTime
    $hoursActive = if ($startTime) { [math]::Round(((Get-Date) - $startTime).TotalHours, 2) } else { $null }

    [PSCustomObject]@{
        PrincipalId   = $a.PrincipalId
        PrincipalName = $principal.AdditionalProperties["displayName"]
        Role          = $roleDef.DisplayName
        StartTime     = $startTime
        HoursActive   = $hoursActive
        FlaggedLong   = if ($hoursActive -gt $ThresholdHours) { $true } else { $false }
    }
}

$report | Format-Table -AutoSize

$report | Export-Csv -Path ".\PIM-Active-Report.csv" -NoTypeInformation
Write-Host "`nReport exported to PIM-Active-Report.csv"