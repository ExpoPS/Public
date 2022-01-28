<#
.DESCRIPTION 
This script will pull the latest compatibility file from github -  https://github.com/tfitzmac/resource-capabilities/blob/master/move-support-resources-with-regions.csv
Allows you to check each Azure resource in a tenant to discover if it is supported for Resource Group or Subscription moves

.NOTES
Stuart Fordham
Change Log
V1.0, 20/11/2018 Initial Version
V1.1, 04/12/2018 Updated Menu Layout
V2.0, 08/04/2020 Updated script to use source CSV 
V2.1, 20/01/2022 Added Move by Region, updated CSV to invoke
#>

#Region Checks
#Check for PS 7.2
if ((Get-Host).Version -lt "7.2"){
	throw "PowerShell version 7.2 or above is not running, please install and use the correct version of PowerShell"}

#Install Az Module
$Mod = $Mod = Get-Module -ListAvailable -Name "Az"
If (!$Mod){
    Write-Host "`nAz module is not installed, attempting to install it"
    Install-Module -Name Az -Scope CurrentUser -Force
	Import-Module Az -ErrorAction SilentlyContinue
}

#EndRegion

$logpath = "C:\Temp\AzureMigrationCompatibility"
if(!(Test-Path -Path $logpath )){
    New-Item -ItemType directory -Path $logpath
	Write-Host "Log folder created" -ForegroundColor Yellow
}
else
{Write-Host "Log folder already exists" -ForegroundColor Yellow}

Write-Host "Starting Transcript" -ForegroundColor Yellow
Start-Transcript -Path "C:\Temp\AzureMigrationCompatibility\transcript.txt" -Append

$url = "https://raw.githubusercontent.com/tfitzmac/resource-capabilities/master/move-support-resources-with-regions.csv"
$output = "$($logpath)\resourcerawdata.csv"
Invoke-WebRequest -Uri $url -OutFile $output


# Sign in to your Azure account 
Write-Host "
----------------------------------------------
Please enter the Azure Portal Details to check
----------------------------------------------" -ForegroundColor Yellow

Connect-AzAccount
Get-AzSubscription | Format-List
Start-Sleep -s 3

[BOOLEAN]$global:xExitSession=$false
function LoadMenuSystem(){
	do{
	[INT]$xMenu1 = 0
	while ( $xMenu1 -lt 1 -or $xMenu1 -gt 5 ){
		Clear-Host
		#… Present the Menu Options
		Write-Host "`n`tAzure Migration Compatibility Check - Version 2.1`n" -ForegroundColor Yellow
		Write-Host "`t`tPlease select the task you wish to run`n" -Fore Green
		Write-Host "`t`t1. Check migration by Resource Group" -Fore Green
		Write-Host "`t`t2. Check migration by Subscription" -Fore Green
		Write-Host "`t`t3. Check migration by Region Move" -Fore Green
		Write-Host "`t`t4. Quit`n" -Fore Red
		#… Retrieve the response from the user
		[int]$xMenu1 = Read-Host "`t`tEnter Menu Option Number"}
	Switch ($xMenu1){    #… User has selected a valid entry.. load next menu
        1 {Write-Host "`n`t`tYou selected 'Check migration by Resource Group'" -ForegroundColor Yellow
        Start-Sleep -s 3
        ResourceGroupCheck}
		2 {Write-Host "`n`t`tYou selected 'Check migration by Subscription'" -ForegroundColor Yellow
        Start-Sleep -s 3
        SubscriptionCheck}
		3 {Write-Host "`n`t`tYou selected 'Check migration by Region Move'" -ForegroundColor Yellow
        Start-Sleep -s 3
        RegionCheck}
		4 {Write-Host "`n`t`tYou selected Quit, closing script." -ForegroundColor Red
        Start-Sleep -s 3
        Exit}
	}
} while ( $userMenuChoice -ne 5 )
}

function ResourceGroupCheck(){
$logfile = "ResourceGroup-Compatibility-log.csv"
Write-Output "Name,ResourceType,SubscriptionID,Supported" | Out-File "$($logpath)\$($logfile)" -Encoding UTF8
$csvrawdata = Import-Csv "$($logpath)\resourcerawdata.csv"
$subscriptions = Get-AzSubscription
$resources = Get-AzResource
foreach ($resource in $resources){
$resourceitem = $csvrawdata | Where-Object {$_.Resource -eq $resource.ResourceType}
foreach($subscription in $subscriptions){if($resource.ResourceId -like "*$($subscription.Id)*"){$SubID = $subscription.Id}}
if ($resourceitem."Move Resource Group" -eq "1") {
Write-Host "The resource '$($resource.Name)' is supported for migration by ResourceGroup" -ForegroundColor Green
Write-Output "$($resource.Name),$($resource.ResourceType),$($SubID),Yes" | Out-File "$($logpath)\$($logfile)" -append -Encoding UTF8
}elseif ($resourceitem."Move Resource Group" -eq "0") {
Write-Host "The resource '$($resource.Name)' is NOT supported for migration by ResourceGroup" -ForegroundColor Red
Write-Output "$($resource.Name),$($resource.ResourceType),$($SubID),Yes" | Out-File "$($logpath)\$($logfile)" -append -Encoding UTF8
}
}
Write-Host "
Log created. Please review the log in '$($logpath)\$($logfile)'

For any items that are not supported, please check 'https://docs.microsoft.com/en-us/azure/azure-resource-manager/move-support-resources'" -ForegroundColor Green

$Continue = Read-Host -Prompt "`nWould you like to go back to the menu? Choose Y for menu or N to exit"
If ($Continue -ne "y")
{
exit
}
}
function SubscriptionCheck(){
$logfile = "Subscription-Compatibility-log.csv"
Write-Output "Name,ResourceType,SubscriptionID,Supported" | Out-File "$($logpath)\$($logfile)" -Encoding UTF8
$csvrawdata = Import-Csv "$($logpath)\resourcerawdata.csv"
$subscriptions = Get-AzSubscription
$resources = Get-AzResource
foreach ($resource in $resources){
$resourceitem = $csvrawdata | Where-Object {$_.Resource -eq $resource.ResourceType}
foreach($subscription in $subscriptions){if($resource.ResourceId -like "*$($subscription.Id)*"){$SubID = $subscription.Id}}
if ($resourceitem."Move Subscription" -eq "1") {
Write-Host "The resource '$($resource.Name)' is supported for migration by Subscription" -ForegroundColor Green
Write-Output "$($resource.Name),$($resource.ResourceType),$($SubID),Yes" | Out-File "$($logpath)\$($logfile)" -append -Encoding UTF8
}elseif ($resourceitem."Move Subscription" -eq "0") {
Write-Host "The resource '$($resource.Name)' is NOT supported for migration by Subscription" -ForegroundColor Red
Write-Output "$($resource.Name),$($resource.ResourceType),$($SubID),No" | Out-File "$($logpath)\$($logfile)" -append -Encoding UTF8
}
}
Write-Host "
Log created. Please review the log in '$($logpath)\$($logfile)'

For any items that are not supported, please check 'https://docs.microsoft.com/en-us/azure/azure-resource-manager/move-support-resources'" -ForegroundColor Green

$Continue = Read-Host -Prompt "`nWould you like to go back to the menu? Choose Y for menu or N to exit"
If ($Continue -ne "y")
{
exit
}
}

function RegionCheck(){
	$logfile = "RegionMove-Compatibility-log.csv"
	Write-Output "Name,ResourceType,SubscriptionID,Supported" | Out-File "$($logpath)\$($logfile)" -Encoding UTF8
	$csvrawdata = Import-Csv "$($logpath)\resourcerawdata.csv"
	$subscriptions = Get-AzSubscription
	$resources = Get-AzResource
	foreach ($resource in $resources){
	$resourceitem = $csvrawdata | Where-Object {$_.Resource -eq $resource.ResourceType}
	foreach($subscription in $subscriptions){if($resource.ResourceId -like "*$($subscription.Id)*"){$SubID = $subscription.Id}}
	if ($resourceitem."Move Region" -eq "1") {
	Write-Host "The resource '$($resource.Name)' is supported for migration by Region" -ForegroundColor Green
	Write-Output "$($resource.Name),$($resource.ResourceType),$($SubID),Yes" | Out-File "$($logpath)\$($logfile)" -append -Encoding UTF8
	}elseif ($resourceitem."Move Subscription" -eq "0") {
	Write-Host "The resource '$($resource.Name)' is NOT supported for migration by Region" -ForegroundColor Red
	Write-Output "$($resource.Name),$($resource.ResourceType),$($SubID),No" | Out-File "$($logpath)\$($logfile)" -append -Encoding UTF8
	}
	}
	Write-Host "
	Log created. Please review the log in '$($logpath)\$($logfile)'
	
	For any items that are not supported, please check 'https://docs.microsoft.com/en-us/azure/azure-resource-manager/move-support-resources'" -ForegroundColor Green
	
	$Continue = Read-Host -Prompt "`nWould you like to go back to the menu? Choose Y for menu or N to exit"
	If ($Continue -ne "y")
	{
	exit
	}
	}
LoadMenuSystem
