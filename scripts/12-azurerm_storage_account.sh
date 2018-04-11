tfp="azurerm_storage_account"
prefixa="stor"
echo $tfp
if [ "$1" != "" ]; then
    rgsource=$1
else
    echo -n "Enter name of Resource Group [$rgsource] > "
    read response
    if [ -n "$response" ]; then
        rgsource=$response
    fi
fi
azr=`az storage account list -g $rgsource`
count=`echo $azr | jq '. | length'`
if [ "$count" -gt "0" ]; then
    count=`expr $count - 1`
    for i in `seq 0 $count`; do
        #echo $i
        name=`echo $azr | jq ".[(${i})].name" | tr -d '"'`
        rg=`echo $azr | jq ".[(${i})].resourceGroup" | tr -d '"'`
 
        id=`echo $azr | jq ".[(${i})].id" | tr -d '"'`

        prefix=`printf "%s_%s" $prefixa $rg`
        satier=`echo $azr | jq ".[(${i})].sku.tier" | tr -d '"'`
        sakind=`echo $azr | jq ".[(${i})].kind" | tr -d '"'`
        sartype=`echo $azr | jq ".[(${i})].sku.name" | cut -f2 -d'_' | tr -d '"'`
        saencrypt=`echo $azr | jq ".[(${i})].encryption.services.blob.enabled" | tr -d '"'`
        sahttps=`echo $azr | jq ".[(${i})].enableHttpsTrafficOnly" | tr -d '"'`
        printf "resource \"%s\" \"%s__%s\" {\n" $tfp $rg $name > $prefix-$name.tf
        printf "\t name = \"%s\"\n" $name >> $prefix-$name.tf
        printf "\t location = \"\${var.loctarget}\"\n" >> $prefix-$name.tf
        #printf "\t resource_group_name = \"\${var.rgtarget}\"\n" >> $prefix-$name.tf
        printf "\t resource_group_name = \"%s\"\n" $rg >> $prefix-$name.tf
        printf "\t account_tier = \"%s\"\n" $satier >> $prefix-$name.tf
        printf "\t account_kind = \"%s\"\n" $sakind >> $prefix-$name.tf
        printf "\t account_replication_type = \"%s\"\n" $sartype >> $prefix-$name.tf
        printf "\t enable_blob_encryption = \"%s\"\n" $saencrypt >> $prefix-$name.tf
        printf "\t enable_https_traffic_only = \"%s\"\n" $sahttps >> $prefix-$name.tf
        #
        printf "}\n" >> $prefix-$name.tf
        #
        cat $prefix-$name.tf
        statecomm=`printf "terraform state rm %s.%s__%s" $tfp $rg $name`
        eval $statecomm
        evalcomm=`printf "terraform import %s.%s__%s %s" $tfp $rg $name $id`
        eval $evalcomm
    done
fi
