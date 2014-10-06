@isTest (seeAllData=true)
private class PopulateCostBasedOnOppCurrencyTest{
   static testMethod void testPopulateCostBasedOnOppCurrency(){    

    //set up Product record
    string ProductName = 'Lotus 123';
    string ProductDescription = 'Lotus Notes Description';     
      Product2 Prod = new Product2(Name=ProductName, Description=ProductDescription, Cost__c = 100);
      Insert Prod;

    //insert standard price for product      
      Pricebook2 standardPB = [select id from Pricebook2 where isStandard=true limit 1];
      Decimal StdPrice = 10.00;
      PriceBookEntry PBEntry1 = new PriceBookEntry( UnitPrice=StdPrice, PriceBook2Id=standardPB.Id, Product2ID=Prod.Id, IsActive = true, UseStandardPrice = false);
      Insert PBEntry1;      
      
      //insert Product Costs
      Product_Costs__c ProdCost = new Product_Costs__c(Product__c = Prod.Id, Cost__c = 50.00, CurrencyIsoCode = 'USD');
      Insert ProdCost;
      
      //insert Account
      Account Acct = new Account(Name = 'Sony Test Acct', CurrencyIsoCode = 'USD');
      Insert Acct;
      
      //insert contact and tie it to account
      Contact Cntc = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = Acct.Id);
      Insert Cntc;
      
      //insert Opportunity
      Opportunity Opp = new Opportunity(Name = 'New Opportunity Name Test', AccountId = Acct.Id,  Estimated_Budget__c = '5000.00', ForecastCategoryName = 'Pipeline', Configuration__c = 'EC800', Quoted__c = 'No', StageName = 'Prospecting', CloseDate = system.today(), Amount = 500.00);
      Insert Opp;
            
      //insert OpportunityLineItem
      OpportunityLineItem OppLineItem = new OpportunityLineItem(OpportunityId=Opp.Id, PricebookEntryId=PBEntry1.Id, UnitPrice=StdPrice, Quantity = 10.00);
      insert OppLineItem;
      
      
      //insert Quote
      Quote QuoteObj = new Quote(OpportunityId=Opp.Id, Pricebook2Id=standardPB.Id, ContactId=Cntc.Id, Name = 'Sample Quote', ExpirationDate = Date.today());
      insert QuoteObj;
      
      //insert QuoteLineItem;
      QuoteLineItem QuoteLI = new QuoteLineItem(QuoteId=QuoteObj.Id, Product2Id=Prod.Id, PricebookEntryId=PBEntry1.Id, Quantity=10.00, UnitPrice=StdPrice);
      insert QuoteLI;
      //Attempt to insert another record with same combination
   //   Product_Costs__c ProdCost1 = new Product_Costs__c(Product__c = Prod.Id, Cost__c = 50.00, CurrencyIsoCode = 'USD');
   //   Insert ProdCost1;
   }
  }