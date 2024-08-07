function Set-CIPPAssignedPolicy {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        $GroupName,
        $PolicyId,
        $Type,
        $TenantFilter,
        $PlatformType,
        $APIName = 'Assign Policy',
        $ExecutingUser
    )
    if (!$PlatformType) { $PlatformType = 'deviceManagement' }
    try {
        $assignmentsObject = switch ($GroupName) {
            'allLicensedUsers' {
                @(
                    @{
                        target = @{
                            '@odata.type' = '#microsoft.graph.allLicensedUsersAssignmentTarget'
                        }
                    }
                )
                break
            }
            'AllDevices' {
                @(
                    @{
                        target = @{
                            '@odata.type' = '#microsoft.graph.allDevicesAssignmentTarget'
                        }
                    }
                )
                break
            }
            'AllDevicesAndUsers' {
                @(
                    @{
                        target = @{
                            '@odata.type' = '#microsoft.graph.allDevicesAssignmentTarget'
                        }
                    },
                    @{
                        target = @{
                            '@odata.type' = '#microsoft.graph.allLicensedUsersAssignmentTarget'
                        }
                    }
                )
            }
            default {
                $GroupNames = $GroupName.Split(',')
                $GroupIds = New-GraphGetRequest -uri 'https://graph.microsoft.com/beta/groups' -tenantid $TenantFilter | ForEach-Object {
                    $Group = $_
                    foreach ($SingleName in $GroupNames) {
                        if ($_.displayname -like $SingleName) {
                            $group.id
                        }
                    }
                }
                foreach ($Group in $GroupIds) {
                    @{
                        target = @{
                            '@odata.type' = '#microsoft.graph.groupAssignmentTarget'
                            groupId       = $Group
                        }
                    }
                }
            }
        }
        $assignmentsObject = [PSCustomObject]@{
            assignments = @($assignmentsObject)
        }
        if ($PSCmdlet.ShouldProcess($GroupName, "Assigning policy $PolicyId")) {
            Write-Host "https://graph.microsoft.com/beta/$($PlatformType)/$Type('$($PolicyId)')/assign"
            $null = New-GraphPOSTRequest -uri "https://graph.microsoft.com/beta/$($PlatformType)/$Type('$($PolicyId)')/assign" -tenantid $tenantFilter -type POST -body ($assignmentsObject | ConvertTo-Json -Depth 10)
            Write-LogMessage -user $ExecutingUser -API $APIName -message "Assigned Policy to $($GroupName)" -Sev 'Info' -tenant $TenantFilter
        }

        return "Assigned policy to $($GroupName) Policy ID is $($PolicyId)."
    } catch {
        $ErrorMessage = Get-CippException -Exception $_
        Write-LogMessage -user $ExecutingUser -API $APIName -message "Failed to assign Policy to $GroupName. Policy ID is $($PolicyId)." -Sev 'Error' -tenant $TenantFilter -LogData $ErrorMessage
        return "Could not assign policy to $GroupName. Policy ID is $($PolicyId). Error: $($ErrorMessage.NormalizedError)"
    }
}
