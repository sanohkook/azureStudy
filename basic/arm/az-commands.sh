az group create --name examplegroup --location "Korea Central"
# az group deployment create --resource-group examplegroup --template-file azuredeploy.json
az group deployment create --resource-group examplegroup --template-file azuredeploy.json --parameters storageSKU=Standard_RAGRS storageNamePrefix=newstore
az group deployment create --resource-group examplegroup --template-file azuredeploy.json --parameters storageSKU=Standard_RAGRS storageNamePrefix=storesecure