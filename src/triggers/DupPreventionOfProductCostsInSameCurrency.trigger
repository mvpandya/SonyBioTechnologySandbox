trigger DupPreventionOfProductCostsInSameCurrency on Product_Costs__c (before insert) {
      Map<String, Product_Costs__c> ProductCostMap = new Map<String, Product_Costs__c>();
      List<Product_Costs__c> ProductCostsList = new List<Product_Costs__c>([Select Product__c, CurrencyIsoCode From Product_Costs__c]);
      for(Product_Costs__c PC : ProductCostsList){
          ProductCostMap.put(PC.Product__c + PC.CurrencyIsoCode, PC);
      }
      Set<String> CurrencyCodeStrings = new Set<String>();
      for (Product_Costs__c PCT : System.Trigger.new) {
           
       
              if (ProductCostMap.containsKey(PCT.Product__c + PCT.CurrencyIsoCode) && trigger.isInsert) {
                  PCT.addError('Cost is already defined for Product and Currency selected here. '
                                      + 'Another entry cannot be entered for same combination. Please edit already existing entry.');
              }
      }
}