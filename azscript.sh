resourceId='/subscriptions/6dffb2a7-1054-40fe-8ef4-ddcb61d54fe6/resourceGroups/rg-dev-iglooNovus/providers/Microsoft.Web/sites/funApp-dev-iglooNovus-app-article-service'
echo $resourceId
resourceUri="${resourceId}/host/default/listKeys?api-version=2018-11-01"
echo $resourceUri
echo $(az rest --method post --uri $resourceUri)
echo "request result 1: $?"
echo $(az rest --method post --uri $resourceUri | grep -o '"apim-apim-dev-igloonovus-01": "[^"]*' | grep -o '[^"]*$')
echo "request result 2: $?"
data=$(az rest --method post --uri $resourceUri | jq '.functionKeys."apim-apim-dev-igloonovus-01"')
echo "request result 3: $?"
data1=$(az functionapp keys list -g rg-dev-iglooNovus -n funApp-dev-iglooNovus-app-article-service | jq '.functionKeys."apim-apim-dev-igloonovus-01"')
echo "request result 4: $?"
echo $data
echo "{\"Result\": \"$data\", \"Test\": \"$data1\"}" > $AZ_SCRIPTS_OUTPUT_PATH