# Stop VMs based on the tags parameter
Param (
    [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()]
    [String]
    $VMTag="Development",
    [Parameter(Mandatory=$true)][ValidateSet("Start","Stop")]
    [String]
    $Action
  )

try
{
    # Run as accounts must be setup within the Azure account setup
    $connectionName = "AzureRunAsConnection"

    # Get the connection "AzureRunAsConnection"
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName

    Write-Output "LOG: Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "ERROR: Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

# Collect all VMs with Names similar to the value passed
$VMs = Get-AzureRmVm
# TODO: Parse the VM tag inputted! Both environment set within Azure and the parameter being passed in.
# $ParsedVMTag = $VMTag.

# Check if we have found any VMs before continuing
if($VMs)
{
  # Loop over each VM object returned
  foreach ($vm in $VMs) {
    # If the VM's Environment tag equals the parameter set
    if ($_.Tags['Environment'] -eq $VMTag) {
      # If the action parameter is stop, stop the current VM
      if ($Action -eq "Stop") {
        Write-Output "LOG: Stopping $_.Name"
        Stop-AzureRmVm -ResourceGroupName $_.ResourceGroupName -Name $_.Name -Force -ErrorAction SilentlyContinue
      } else {
        Write-Output "LOG: Starting $_.Name"
        Start-AzureRmVm -ResourceGroupName $_.ResourceGroupName -Name $_.Name -Force -ErrorAction SilentlyContinue
      }
    } else {
      Write-Output "LOG: $_ does not have tags containing $VMTag therefore not stopping..."
    }
  }
} else {
  Write-Output "LOG: No VMs were found in your subscription."
}