trigger UpdateProductPriceAndCosts on Conversion_Rate__c (after insert, after update) {
/*
Objective: As the currency conversion rates are updated on a monthly basis, apply it to Product prices and Costs
1. Check from what currency to what currency it is converting into
2. From PriceBookEntry, read all products where price is defined for From Currency
3. Also build a map of all products from PriceBookEntry for all products where price is defined for To Currency
4. Update PriceBookEntry for Price on products in step 3 to be price of product in step 2 times the conversion rate

*/
decimal conversionrate;
string FromCurrency, ToCurrency;

for (Conversion_Rate__c CR : trigger.new){
    If (trigger.isInsert){    
        conversionrate = CR.Conversion_Rate__c;
        FromCurrency = CR.From_Currency__c;
        ToCurrency = CR.To_Currency__c;
    } else If (trigger.isUpdate && (CR.Conversion_Rate__c != trigger.oldMap.get(CR.Id).Conversion_Rate__c || CR.From_Currency__c != trigger.oldMap.get(CR.Id).From_Currency__c || CR.To_Currency__c != trigger.oldMap.get(CR.Id).To_Currency__c)){
        conversionrate = CR.Conversion_Rate__c;
        FromCurrency = CR.From_Currency__c;
        ToCurrency = CR.To_Currency__c;    
    }
}

List<PriceBookEntry> PBEList = new List<PriceBookEntry>([Select Id, Pricebook2Id, Product2Id, CurrencyIsoCode, UnitPrice From PriceBookEntry Where IsActive = true AND Pricebook2.Name != 'Standard Price Book' AND UseStandardPrice = false AND (CurrencyIsoCode =: FromCurrency OR CurrencyIsoCode =: ToCurrency) ]);
MAP<String, PriceBookEntry> PBEFromCurrencyMap = new MAP<String, PriceBookEntry>();
MAP<String, PriceBookEntry> PBEToCurrencyMap = new MAP<String, PriceBookEntry>();
List<PriceBookEntry> PBEListToUpsert = new List<PriceBookEntry>();
String PricebookID;
for(PriceBookEntry PBL : PBEList){

    If(PBL.CurrencyIsoCode == FromCurrency){
        PBEFromCurrencyMap.put(string.ValueOf(PBL.Pricebook2Id) + string.ValueOf(PBL.Product2Id) + PBL.CurrencyIsoCode, PBL);
    } else If(PBL.CurrencyIsoCode == ToCurrency){
        PBEToCurrencyMap.put(string.ValueOf(PBL.Pricebook2Id) + string.ValueOf(PBL.Product2Id) + PBL.CurrencyIsoCode, PBL);
    }
}
Id Product2ID, Pricebook2Id;
for(string FrCurrency : PBEFromCurrencyMap.keyset()){
         Product2ID = PBEFromCurrencyMap.get(FrCurrency).Product2Id;
         Pricebook2Id = PBEFromCurrencyMap.get(FrCurrency).Pricebook2Id;
         system.debug('Product2ID ' + Product2ID);
         If(PBEToCurrencyMap.containsKey(string.ValueOf(Pricebook2Id) + string.ValueOf(Product2ID) + ToCurrency)){
             If(PBEToCurrencyMap.get(string.ValueOf(Pricebook2Id) + string.ValueOf(Product2ID) + ToCurrency).Pricebook2Id == PBEFromCurrencyMap.get(FrCurrency).Pricebook2Id){
                 PBEToCurrencyMap.get(string.ValueOf(Pricebook2Id) + string.ValueOf(Product2ID) + ToCurrency).UnitPrice = PBEFromCurrencyMap.get(FrCurrency).UnitPrice * conversionrate;
                 PBEListToUpsert.add(PBEToCurrencyMap.get(string.ValueOf(Pricebook2Id) + string.ValueOf(Product2ID) + ToCurrency));     
            }
         }
}

If (PBEListToUpsert.size() > 0){
    Upsert PBEListToUpsert;
}
List<Product_Costs__c> ProductCostList = new List<Product_Costs__c>([Select Id, CurrencyIsoCode, Product__c, Cost__c From Product_Costs__c LIMIT 10000]);
MAP<String, Product_Costs__c> PCFromCurrencyMap = new MAP<String, Product_Costs__c>();
MAP<String, Product_Costs__c> PCToCurrencyMap = new MAP<String, Product_Costs__c>();
List<Product_Costs__c> ProductCostListToUpsert = new List<Product_Costs__c>();
for(Product_Costs__c PCList : ProductCostList){
    If(PCList.CurrencyIsoCode == FromCurrency){
        PCFromCurrencyMap.put(string.ValueOf(PCList.Product__c) + PCList.CurrencyIsoCode, PCList);
    } else If(PCList.CurrencyIsoCode == ToCurrency){
        PCToCurrencyMap.put(string.ValueOf(PCList.Product__c) + PCList.CurrencyIsoCode, PCList);
    }
}
ID ProductID;
for(string FrCurrency : PCFromCurrencyMap.keyset()){
    ProductID = PCFromCurrencyMap.get(FrCurrency).Product__c;
    If(PCToCurrencyMap.containsKey(string.ValueOf(ProductId) + ToCurrency)){
         PCToCurrencyMap.get(string.ValueOf(ProductId) + ToCurrency).Cost__c = PCFromCurrencyMap.get(FrCurrency).Cost__c * conversionrate;
         ProductCostListToUpsert.add(PCToCurrencyMap.get(string.ValueOf(ProductId) + ToCurrency));        
}
}
If (ProductCostListToUpsert.size() > 0){
    Upsert ProductCostListToUpsert;
}

}