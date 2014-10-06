trigger PopulateCostBasedOnOppCurrency on QuoteLineItem (before insert, before update) {
/*
Objective of this trigger is to retrieve product cost in same currency as Opportunity from Product Cost object and populate it into Cost__c custom field in QuoteLineItem
1. Read Quote ID, Product2ID From QuoteLineItem and prepare set
2. Get a list of all quotes and respective Opportunity IDs
3. Prepare a set of Opportunity
4. Get a list of Opportunity Currency
5. Prepare a map of opportunity to its currency
6. Get a list of Product2 records with associated Product2IDs
7. Get a list of data from Product_Cost object
8. Build a Map based on ProductIDCurrency to associated cost.
9. Pass ProductIDOppCurrency in map in #8 above and populate returned value in Cost__c
10. Exception handling when no cost is returned in #9 above, read it from Product>Cost field.
11. Add a validation rule to not allow save of product without entering cost value in Corporate Currency.

*/

Set <ID> QuoteIDSet = new Set<ID>();
Set <ID> ProductIDSet = new Set<ID>();
Map <ID, ID> QuoteLineItemToPriceBookEntryIDMap = new Map <ID, ID>();
for (QuoteLineItem QLI: trigger.new){
    ProductIDSet.add(QLI.Product2ID);
    QuoteIDSet.add(QLI.QuoteID);
    QuoteLineItemToPriceBookEntryIDMap.put(QLI.ID, QLI.PricebookEntryId);
}
List <Quote> QuoteList = new List<Quote> ([Select ID, OpportunityID From Quote Where ID In :QuoteIDSet]);
Map <ID, ID> QuoteToOpportunityID = new Map<ID, ID>();
Set<ID> OppIDSet = new Set<ID>();
for(Quote QL : QuoteList){
    QuoteToOpportunityID.put(QL.ID, QL.OpportunityID);
    OppIDSet.add(QL.OpportunityID);
}
List<Opportunity> OpportunityList = new List<Opportunity>([Select ID, CurrencyIsoCode From Opportunity Where ID In :OppIDSet]);
Map <ID, string> OpportunityCurrencyMap = new Map <ID, string>();
for (Opportunity OppList : OpportunityList){
    OpportunityCurrencyMap.put(OppList.ID, OppList.CurrencyIsoCode);
}
List<Product_Costs__c> ProductCostList = new List<Product_Costs__c>([Select Id, CurrencyIsoCode, Product__c, Cost__c From Product_Costs__c Where Product__c In :ProductIDSet]);
Map <String, decimal> ProductCostInCurrencyMap = new Map<String, decimal>();
for (Product_Costs__c PCL : ProductCostList) {
    ProductCostInCurrencyMap.put(PCL.Product__c + PCL.CurrencyIsoCode, PCL.Cost__c);
}
List<Product2> Product = new List<Product2>([Select ID, Cost__c From Product2 Where ID In :ProductIDSet]);
Map<ID, decimal> ProductCostInCorporateCurrencyMap = new Map<ID, decimal>();
for (Product2 Prod : Product){
    ProductCostInCorporateCurrencyMap.put(Prod.ID, Prod.Cost__c);
}

string ProductCostCurrencyString;
for (QuoteLineItem QLItem: trigger.new){
    ProductCostCurrencyString = QLItem.Product2Id + OpportunityCurrencyMap.get(QuoteToOpportunityID.get(QLItem.QuoteId));
    system.debug(' Comparison String ' + ProductCostCurrencyString);
    If (ProductCostInCurrencyMap.containsKey(ProductCostCurrencyString)){
        QLItem.Cost__c = ProductCostInCurrencyMap.get(ProductCostCurrencyString);
    } Else {
        QLItem.Cost__c = ProductCostInCorporateCurrencyMap.get(QLItem.Product2ID);
    }
}
}