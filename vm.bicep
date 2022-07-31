//https://docs.microsoft.com/en-us/azure/virtual-machines/windows/quick-create-bicep?tabs=CLI
// CREATE - 
//    az deployment group create -f vm.bicep -g sbIndiaServer
// DELETE - 
//    az deployment group create -f vm_delete.bicep -g sbIndiaServer --mode Complete

// VM deployment needs -
// Hardware Profile, Network Proile - Network Interface,
//                    Os Profile, Storage Profile - Image Ref, Disk
// Virtual Network - address space, subnets
// Public IP 
// Network Interface - Subnet and Public IP
// Resource Id: "/subscriptions/0eb97a9f-ed07-42cd-9c65-a0027bddf925/resourceGroups/sbIndiaServer"


param location string = resourceGroup().location
param vnetName string = 'vnetIndiaServer'
param userName string = 'banersau'
param vmName string = 'vmIndia'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnet1'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
      {
        name: 'Subnet-2'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

param dnsLabelPrefix string = toLower('${vmName}-${uniqueString(resourceGroup().id, vmName)}')

resource pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: 'pipIndiaServer'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-11-01' = {
  name: 'nicIndiaServer'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'sbIndiaServeIpConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: '${virtualNetwork.id}/subnets/subnet1'
          }
        }
      }
    ]
  }
}

resource windowsVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v3'
    }
    osProfile: {
      computerName: 'IndiaPC'
      adminUsername: userName
      adminPassword: 'password#123'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-10'
        sku: 'win10-21h2-pro'
        version: 'latest'
      }
      osDisk: {
        name: 'IndiaServerDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
  }
}


