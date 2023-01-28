# Script Atualiza��o in-loco para VMs que executam o Windows Server no Azure - Cr�ditos Gabriel Luiz - www.gabrielluiz.com #


# Observa��o: Para execu��o no Azure Powershell.


# Par�metros espec�ficos do cliente.


# Grupo de recursos da VM de origem.

$resourceGroup = "WindowsServerUpgrades"


# Localiza��o da VM de origem.

$location = "BrazilSouth"


# Zona da VM de origem, se houver.

$zone = "" 


# Nome do disco para o que ser� criado

$diskName = "WindowsServer2022UpgradeDisk"


# Vers�o de destino para a atualiza��o - deve ser server2022Upgrade ou server2019Upgrade.

$sku = "server2022Upgrade"


# Par�metros comuns

$publisher = "MicrosoftWindowsServer"
$offer = "WindowsServerUpgrade"
$managedDiskSKU = "Standard_LRS"


# Obter a vers�o mais recente da Imagem de VM especial (oculta) do Azure Marketplace.

$versions = Get-AzVMImage -PublisherName $publisher -Location $location -Offer $offer -Skus $sku | sort-object -Descending {[version] $_.Version	}
$latestString = $versions[0].Version



# Obter a Imagem de VM especial (oculta) do Azure Marketplace por vers�o - a imagem � usada para criar um disco para atualizar para a nova vers�o.


$image = Get-AzVMImage -Location $location `
                       -PublisherName $publisher `
                       -Offer $offer `
                       -Skus $sku `
                       -Version $latestString

#
# Criar um Grupo de Recursos se ele n�o existir.
#

if (-not (Get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $resourceGroup -Location $location    
}

#
# Criar disco gerenciado a partir do LUN 0.
#

if ($zone){
    $diskConfig = New-AzDiskConfig -SkuName $managedDiskSKU `
                                   -CreateOption FromImage `
                                   -Zone $zone `
                                   -Location $location
} else {
    $diskConfig = New-AzDiskConfig -SkuName $managedDiskSKU `
                                   -CreateOption FromImage `
                                   -Location $location
} 

Set-AzDiskImageReference -Disk $diskConfig -Id $image.Id -Lun 0

New-AzDisk -ResourceGroupName $resourceGroup `
           -DiskName $diskName `
           -Disk $diskConfig


<#

Refer�ncias:

https://learn.microsoft.com/en-us/azure/virtual-machines/windows-in-place-upgrade?WT.mc_id=5003815

https://learn.microsoft.com/pt-br/powershell/azure/?view=azps-9.3.0&WT.mc_id=5003815

#>
