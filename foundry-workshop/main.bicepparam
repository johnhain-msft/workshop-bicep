using 'main.bicep'

var projectsCountValue = readEnvironmentVariable('PROJECTS_COUNT', '')
param projectsCount = empty(projectsCountValue) ? null : int(projectsCountValue)

// Parameters for the main Bicep template
var principalIdValue = readEnvironmentVariable('AZURE_PRINCIPAL_ID', '')
param deployerPrincipalId = empty(principalIdValue) ? null : principalIdValue

var groupPrincipalIdValue = readEnvironmentVariable('AZURE_GROUP_PRINCIPAL_ID', '')
param groupPrincipalId = empty(groupPrincipalIdValue) ? null : groupPrincipalIdValue

var studentsInitialsValue = readEnvironmentVariable('STUDENTS_INITIALS', '')
param studentsInitials = empty(studentsInitialsValue) ? null : studentsInitialsValue

var subnetForStoragePeResourceIdValue = readEnvironmentVariable('SUBNET_FOR_STORAGE_PE_RESOURCE_ID', '')
param subnetForStoragePeResourceId = empty(subnetForStoragePeResourceIdValue) ? null : subnetForStoragePeResourceIdValue

var blobPrivateDnsZoneResourceIdValue = readEnvironmentVariable('BLOB_PRIVATE_DNS_ZONE_RESOURCE_ID', '')
param blobPrivateDnsZoneResourceId = empty(blobPrivateDnsZoneResourceIdValue) ? null : blobPrivateDnsZoneResourceIdValue

