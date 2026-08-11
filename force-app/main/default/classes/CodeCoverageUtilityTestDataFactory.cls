@isTest
public class CodeCoverageUtilityTestDataFactory {
    public static Org__c createOrg(){
        Org__c org = New Org__c();
        org.Name = 'TestOrg123';
        org.Access_Token__c = '8764ynfafif9r3rny23099hiknefprfu920r';
        org.Domain_URL__c='https://cloudfulcrum.copadodev.com';
        org.Password__c ='123456677';
        org.Username__c = 'tejaamere@cloudfulcrum.com.copadodev';
        org.Security_Token__c = '8w3ornsk.fjniafy89aufosdnfidy9q093798iunofnk';
        org.Next_Schedule_On__c = System.now();
        org.Status__c = 'Completed';
        org.Next_Run__c = System.now();
        org.Desired_Timezone__c = 'Asia/Tokyo';
        org.Email_Id_s__c='test1@testorg.com,test2@testorg.com';
        org.IsTestRunning__c = true;
        insert org;
        return org;
    }
    /*public static Org__c createOrgInProgressStatus(){
        Org__c org = New Org__c();
        org.Name = 'OrgProg';
        org.Access_Token__c = '8764ynfafif9r3rny23099hiknefprfu920r';
        org.Domain_URL__c='https://cloudfulcrum.copadodev.com';
        org.Password__c ='S7654567';
        org.Username__c = 'testuser@cloudfulcrum.com';
        org.Security_Token__c = '8w3ornsk.fjniafy89aufosdnfidy9q093798iunofnk';
        org.Next_Schedule_On__c = System.now().addDays(1);
        org.Status__c = 'In Progress';
        org.Next_Run__c = System.now().addDays(1);
        org.IsTestRunning__c = true;
        insert org;
        return org;
    }
    
    public static Org__c creatProdOrg(){
        Org__c objOrg1 = new Org__c(Name = 'TestProd', Org_Type__c = 'Production',IsTestRunning__c = true);
        insert objOrg1;
        return objOrg1;
    } 
    
    public static List<Org__c> multipleOrgsCreation(){
        creatProdOrg();
        List<Org__c> multipleOrgs = New List<Org__c>();
        Org__c objOrg1 = [Select Id from Org__c Where name = 'TestProd' Limit 1];
        Recordtype rt = [select id,developername from Recordtype where developername='Sandbox' limit 1];
        Org__c objsandOrg1 = new Org__c(Name = 'TestSand1',Production_Org__c =objOrg1.Id,Org_Type__c='Sandbox',Recordtypeid=rt.id,IsTestRunning__c = true);
        multipleOrgs.add(objsandOrg1);
        Org__c objsandOrg2 = new Org__c(Name = 'TestSand2',Production_Org__c =objOrg1.Id,Org_Type__c='Sandbox',Recordtypeid=rt.id,IsTestRunning__c = true);
        multipleOrgs.add(objsandOrg2);
        Org__c objsandOrg3 = new Org__c(Name = 'TestSand3',Production_Org__c =objOrg1.Id,Org_Type__c='Sandbox',Recordtypeid=rt.id,IsTestRunning__c = true);
        multipleOrgs.add(objsandOrg3);
        Org__c objsandOrg4 = new Org__c(Name = 'TestSand4',Production_Org__c =objOrg1.Id,Org_Type__c='Sandbox',Recordtypeid=rt.id,IsTestRunning__c = true);
        multipleOrgs.add(objsandOrg4);
        Org__c objsandOrg5 = new Org__c(Name = 'TestSand5',Production_Org__c =objOrg1.Id,Org_Type__c='Sandbox',Recordtypeid=rt.id,IsTestRunning__c = true);
        multipleOrgs.add(objsandOrg5);
        insert multipleOrgs;
        return multipleOrgs;
        
    }
    public static Apex_Class_Trigger__c apexCreation(){
        Apex_Class_Trigger__c objApex = new Apex_Class_Trigger__c(Name__c = 'ApexTest', Name='ApexTest');
        insert objApex;
        return objApex;
    } 
    public static List<Code_Coverage__c> multipleCodeCoverageCreation(){
        Org__c org1 = [Select Id, Name from Org__c Where Name = 'TestSand1' Limit 1];
        Org__c org2 = [Select Id, Name from Org__c Where Name = 'TestSand2' Limit 1]; 
        Org__c org3 = [Select Id, Name from Org__c Where Name = 'TestSand3' Limit 1]; 
        Org__c org4 = [Select Id, Name from Org__c Where Name = 'TestSand4' Limit 1];
        Org__c org5 = [Select Id, Name from Org__c Where Name = 'TestSand5' Limit 1]; 
        
        Apex_Class_Trigger__c apex = [Select Id, Name__c from Apex_Class_Trigger__c Where Name__c = 'ApexTest'];
        
        List<Code_Coverage__c> coverageList = new List<Code_Coverage__c>();
        Code_Coverage__c objCC1 = new Code_Coverage__c(Name = 'CC1',Org__c =org1.Id, Apex_Class_Trigger_Name__c =apex.Id, Total_Code_Coverage__c = 90);
        coverageList.add(objCC1);
        Code_Coverage__c objCC2 = new Code_Coverage__c(Name = 'CC2',Org__c =org2.Id, Apex_Class_Trigger_Name__c =apex.Id, Total_Code_Coverage__c = 80);
        coverageList.add(objCC2);
        Code_Coverage__c objCC3 = new Code_Coverage__c(Name = 'CC3',Org__c =org3.Id, Apex_Class_Trigger_Name__c =apex.Id, Total_Code_Coverage__c = 85);
        coverageList.add(objCC3);
        Code_Coverage__c objCC4 = new Code_Coverage__c(Name = 'CC4',Org__c =org4.Id, Apex_Class_Trigger_Name__c =apex.Id, Total_Code_Coverage__c = 65);
        coverageList.add(objCC4);
        Code_Coverage__c objCC5 = new Code_Coverage__c(Name = 'CC5',Org__c =org5.Id, Apex_Class_Trigger_Name__c =apex.Id, Total_Code_Coverage__c = 55);
        coverageList.add(objCC5);
        insert coverageList;
        
        return [select id,Name,Org__c,Org__r.Name,Apex_Class_Trigger_Name__c,Apex_Class_Trigger_Name__r.Name from Code_Coverage__c];
    }
    public static void createEmailTemplate(){
        Folder fol = new Folder(Name = 'Test Folder',DeveloperName='TestFolder', Type='Email',AccessType = 'public', isReadOnly = true);
        EmailTemplate e = new EmailTemplate (developerName = 'test', FolderId = fol.Id, TemplateType= 'Text', Name = 'Latest_Coverage_Report_Generated');
    }
    public static Comparison_Report_History__c createComparisonHistory5(){
        creatProdOrg();
		multipleOrgsCreation();
        Comparison_Report_History__c crh = New Comparison_Report_History__c();
        Code_Comparison_Labels__c ccl = New Code_Comparison_Labels__c();
        ccl.Name = 'TestSand1vsTestSand2vsTestSand3vsTestSand4vsTestSand5';
            insert ccl;
        crh.Name = 'TestSand1vsTestSand2vsTestSand3vsTestSand4vsTestSand5';
        crh.Code_Comparison_Label__c = ccl.Id;
        crh.Org_1__c = 'TestSand1';
        crh.Org_2__c = 'TestSand2';
        crh.Org_3__c = 'TestSand3';
        crh.Org_4__c = 'TestSand4';
        crh.Org_5__c = 'TestSand5';
        crh.Overall_Org1_Coverage__c = 75;
        crh.Overall_Org2_Coverage__c = 90;
        crh.Overall_Org3_Coverage__c = 65;
        crh.Overall_Org4_Coverage__c = 82;
        crh.Overall_Org5_Coverage__c = 91;
        insert crh;
        return crh;
    }
    public static Comparison_Report_History__c createComparisonHistory4(){
        creatProdOrg();
		multipleOrgsCreation();
        Comparison_Report_History__c crh = New Comparison_Report_History__c();
        Code_Comparison_Labels__c ccl = New Code_Comparison_Labels__c();
        ccl.Name = 'TestSand1vsTestSand2vsTestSand3vsTestSand4';
            insert ccl;
        crh.Name = 'TestSand1vsTestSand2vsTestSand3vsTestSand4';
        crh.Code_Comparison_Label__c = ccl.Id;
        crh.Org_1__c = 'TestSand1';
        crh.Org_2__c = 'TestSand2';
        crh.Org_3__c = 'TestSand3';
        crh.Org_4__c = 'TestSand4';
        crh.Overall_Org1_Coverage__c = 75;
        crh.Overall_Org2_Coverage__c = 90;
        crh.Overall_Org3_Coverage__c = 65;
        crh.Overall_Org4_Coverage__c = 82;
        insert crh;
        return crh;
    }
    public static Comparison_Report_History__c createComparisonHistory(){
        creatProdOrg();
		multipleOrgsCreation();
        Comparison_Report_History__c crh = New Comparison_Report_History__c();
        Code_Comparison_Labels__c ccl = New Code_Comparison_Labels__c();
        ccl.Name = 'TestSand1vsTestSand2vsTestSand3';
            insert ccl;
        crh.Name = 'TestSand1vsTestSand2vsTestSand3';
        crh.Code_Comparison_Label__c = ccl.Id;
        crh.Org_1__c = 'TestSand1';
        crh.Org_2__c = 'TestSand2';
        crh.Org_3__c = 'TestSand3';
        crh.Overall_Org1_Coverage__c = 75;
        crh.Overall_Org2_Coverage__c = 90;
        crh.Overall_Org3_Coverage__c = 65;
        insert crh;
        return crh;
    }
    public static Comparison_Report_History__c createComparisonHistoryWith2Orgs(){
        creatProdOrg();
		multipleOrgsCreation();
        Comparison_Report_History__c crh = New Comparison_Report_History__c();
        Code_Comparison_Labels__c ccl = New Code_Comparison_Labels__c();
        ccl.Name = 'TestSand1vsTestSand2';
            insert ccl;
        crh.Name = 'TestSand1vsTestSand2';
        crh.Code_Comparison_Label__c = ccl.Id;
        crh.Org_1__c = 'TestSand1';
        crh.Org_2__c = 'TestSand2';
        crh.Org_3__c = '';
        crh.Overall_Org1_Coverage__c = 75;
        crh.Overall_Org2_Coverage__c = 90;
        insert crh;
        return crh;
    }
    public static List<Code_Comparison_Labels__c> createLabels(){
        List<Code_Comparison_Labels__c> cLList = New List<Code_Comparison_Labels__c>();
        for(Integer i=0; i<=4; i++){
            Code_Comparison_Labels__c cL = New Code_Comparison_Labels__c();
            cL.Name = 'TestSand1vsTestSand2vsTestSand3'+i;
            cLList.add(cL);
        }
        insert cLList;
        return cLList;
    }
    public static Org__c creatProdOrgShort(){
        Org__c objOrg1 = new Org__c(Name = 'TestProd', Org_Type__c = 'Production',IsTestRunning__c = true);
        insert objOrg1;
        return objOrg1;
    }
     
    public static List<Org__c> multipleOrgsCreationShort(){
        List<Org__c> multipleOrgs = New List<Org__c>();
        Org__c objOrg1 = [Select Id from Org__c Where name = 'TestProd' Limit 1];
        Recordtype rt = [select id,developername from Recordtype where developername='Sandbox' limit 1];
        Org__c objsandOrg1 = new Org__c(Name = 'TestSand1',Production_Org__c =objOrg1.Id,Org_Type__c='Sandbox',Recordtypeid=rt.id,IsTestRunning__c = true);
        multipleOrgs.add(objsandOrg1);
        Org__c objsandOrg2 = new Org__c(Name = 'TestSand2',Production_Org__c =objOrg1.Id,Org_Type__c='Sandbox',Recordtypeid=rt.id,IsTestRunning__c = true);
        multipleOrgs.add(objsandOrg2);
        Org__c objsandOrg3 = new Org__c(Name = 'TestSand3',Production_Org__c =objOrg1.Id,Org_Type__c='Sandbox',Recordtypeid=rt.id,IsTestRunning__c = true);
        multipleOrgs.add(objsandOrg3);
        Org__c objsandOrg4 = new Org__c(Name = 'TestSand4',Production_Org__c =objOrg1.Id,Org_Type__c='Sandbox',Recordtypeid=rt.id,IsTestRunning__c = true);
        multipleOrgs.add(objsandOrg4);
        Org__c objsandOrg5 = new Org__c(Name = 'TestSand5',Production_Org__c =objOrg1.Id,Org_Type__c='Sandbox',Recordtypeid=rt.id,IsTestRunning__c = true);
        multipleOrgs.add(objsandOrg5);
        insert multipleOrgs;
        return multipleOrgs;
    }
    public static Comparison_Report_History__c createComparisonHistory5Short(){
        creatProdOrg();
		multipleOrgsCreationShort();
        Comparison_Report_History__c crh = New Comparison_Report_History__c();
        Code_Comparison_Labels__c ccl = New Code_Comparison_Labels__c();
        ccl.Name = 'TestSand1vsTestSand2vsTestSand3vsTestSand4vsTestSand5';
            insert ccl;
        crh.Name = 'TestSand1vsTestSand2vsTestSand3vsTestSand4vsTestSand5';
        crh.Code_Comparison_Label__c = ccl.Id;
        crh.Org_1__c = 'TestSand1';
        crh.Org_2__c = 'TestSand2';
        crh.Org_3__c = 'TestSand3';
        crh.Org_4__c = 'TestSand4';
        crh.Org_5__c = 'TestSand5';
        crh.Overall_Org1_Coverage__c = 75;
        crh.Overall_Org2_Coverage__c = 90;
        crh.Overall_Org3_Coverage__c = 65;
        crh.Overall_Org4_Coverage__c = 82;
        crh.Overall_Org5_Coverage__c = 91;
        insert crh;
        return crh;
    }
    public static List<Code_Coverage__c> multipleCodeCoverageCreationShort(){
        Org__c org1 = [Select Id, Name from Org__c Where Name = 'TestSand1' Limit 1];
        Org__c org2 = [Select Id, Name from Org__c Where Name = 'TestSand2' Limit 1]; 
        Org__c org3 = [Select Id, Name from Org__c Where Name = 'TestSand3' Limit 1]; 
        Org__c org4 = [Select Id, Name from Org__c Where Name = 'TestSand4' Limit 1];
        Org__c org5 = [Select Id, Name from Org__c Where Name = 'TestSand5' Limit 1]; 
        
        Apex_Class_Trigger__c apex = [Select Id, Name__c from Apex_Class_Trigger__c Where Name__c = 'ApexTest'];
        
        List<Code_Coverage__c> coverageList = new List<Code_Coverage__c>();
        Code_Coverage__c objCC1 = new Code_Coverage__c(Name = 'CC1',Org__c =org1.Id, Apex_Class_Trigger_Name__c =apex.Id, Total_Code_Coverage__c = 90.00);
        coverageList.add(objCC1);
        Code_Coverage__c objCC2 = new Code_Coverage__c(Name = 'CC2',Org__c =org2.Id, Apex_Class_Trigger_Name__c =apex.Id, Total_Code_Coverage__c = 80.00);
        coverageList.add(objCC2);
        Code_Coverage__c objCC3 = new Code_Coverage__c(Name = 'CC3',Org__c =org3.Id, Apex_Class_Trigger_Name__c =apex.Id, Total_Code_Coverage__c = 85.00);
        coverageList.add(objCC3);
        Code_Coverage__c objCC4 = new Code_Coverage__c(Name = 'CC4',Org__c =org4.Id, Apex_Class_Trigger_Name__c =apex.Id, Total_Code_Coverage__c = 75.00);
        coverageList.add(objCC4);
        Code_Coverage__c objCC5 = new Code_Coverage__c(Name = 'CC5',Org__c =org5.Id, Apex_Class_Trigger_Name__c =apex.Id, Total_Code_Coverage__c = 79.00);
        coverageList.add(objCC5);
        insert coverageList;
        
        return [select id,Name,Org__c,Org__r.Name,Apex_Class_Trigger_Name__c,Apex_Class_Trigger_Name__r.Name from Code_Coverage__c];
    }*/
    public static void createCustomSetting(){
       createOrg();
        Org__c org = [Select Id,Name from Org__c Where Name = 'TestOrg123' Limit 1];
        OrgId__c orgId = orgId__c.getInstance();
        orgId.Id__c = org.Id;
        upsert orgId;
    }
    public static void createCredsCustomSetting(){
       //createOrg();
        ConnectedAppCredentials__c creds = ConnectedAppCredentials__c.getInstance();
        creds.Key__c = 'iuhddiuayd98doqwhd98xsidpsd';
        creds.Secret__c = 'dwdu8wd8hopwndi9w8yd9a8sndoasyud';
        creds.CallbackUrl__c = 'https://cloudfulcrum.copadodev.com';
        upsert creds;
    }
    public static Org__c createLastNextOrg(){
        Org__c org = New Org__c();
        org.Name = 'TestOrgLN';
        org.Access_Token__c = '8764ynfafif9r3rny23099hiknefprfu920r';
        org.Domain_URL__c='https://cloudfulcrum.copadodev.com';
        org.Password__c ='123456677';
        org.Username__c = 'tejaamere@cloudfulcrum.com.copadodev';
        org.Security_Token__c = '8w3ornsk.fjniafy89aufosdnfidy9q093798iunofnk';
        DateTime dt = DateTime.newInstance(2023, 6, 25, 18, 0, 0);
        org.Next_Schedule_On__c = dt;
        org.Status__c = 'Completed';
        org.Next_Run__c = dt;
        org.Desired_Timezone__c = 'Asia/Tokyo';
        org.Email_Id_s__c='test1@testorg.com,test2@testorg.com';
        org.IsTestRunning__c = true;
        insert org;
        return org;
    }
}