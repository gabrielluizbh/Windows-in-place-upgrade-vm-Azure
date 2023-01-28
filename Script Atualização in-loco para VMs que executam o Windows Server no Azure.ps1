# Script Atualização in-loco para VMs que executam o Windows Server no Azure - Créditos Gabriel Luiz - www.gabrielluiz.com #


# Observação: Para execução no Azure Powershell.


# Parâmetros específicos do cliente.


# Grupo de recursos da VM de origem.

$resourceGroup = "WindowsServerUpgrades"


# Localização da VM de origem.

$location = "BrazilSouth"


# Zona da VM de origem, se houver.

$zone = "" 


# Nome do disco para o que será criado

$diskName = "WindowsServer2022UpgradeDisk"


# Versão de destino para a atualização - deve ser server2022Upgrade ou server2019Upgrade.

$sku = "server2022Upgrade"


# Parâmetros comuns

$publisher = "MicrosoftWindowsServer"
$offer = "WindowsServerUpgrade"
$managedDiskSKU = "Standard_LRS"


# Obter a versão mais recente da Imagem de VM especial (oculta) do Azure Marketplace.

$versions = Get-AzVMImage -PublisherName $publisher -Location $location -Offer $offer -Skus $sku | sort-object -Descending {[version] $_.Version	}
$latestString = $versions[0].Version



# Obter a Imagem de VM especial (oculta) do Azure Marketplace por versão - a imagem é usada para criar um disco para atualizar para a nova versão.


$image = Get-AzVMImage -Location $location `
                       -PublisherName $publisher `
                       -Offer $offer `
                       -Skus $sku `
                       -Version $latestString

#
# Criar um Grupo de Recursos se ele não existir.
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

Referências:

https://learn.microsoft.com/en-us/azure/virtual-machines/windows-in-place-upgrade?WT.mc_id=5003815

https://learn.microsoft.com/pt-br/powershell/azure/?view=azps-9.3.0&WT.mc_id=5003815

#>
