@isTest
public class LegalCaseNoteHandlerTest {
    
    @testSetup
    static void setup() {
        LegalCase__c testCase = new LegalCase__c();
        insert testCase;
    }
    
    @isTest
    static void testHtmlStrippedOnInsert() {
        LegalCase__c testCase = [SELECT Id FROM LegalCase__c LIMIT 1];
        
        LegalCaseNote__c note = new LegalCaseNote__c(
            LegalCase__c = testCase.Id,
            NoteDetail__c = '<p><b>Outstanding Items</b></p><ul><li>Item one</li><li>Item two</li></ul>'
        );
        
        Test.startTest();
        insert note;
        Test.stopTest();
        
        LegalCaseNote__c result = [SELECT NoteDetailSearch__c FROM LegalCaseNote__c WHERE Id = :note.Id];
        System.assert(!result.NoteDetailSearch__c.contains('<'), 'HTML tags should be stripped');
        System.assert(result.NoteDetailSearch__c.contains('Outstanding Items'), 'Text content should be preserved');
    }
    
    @isTest
    static void testHtmlStrippedOnUpdate() {
        LegalCase__c testCase = [SELECT Id FROM LegalCase__c LIMIT 1];
        
        LegalCaseNote__c note = new LegalCaseNote__c(
            LegalCase__c = testCase.Id,
            NoteDetail__c = '<p>Original content</p>'
        );
        insert note;
        
        Test.startTest();
        note.NoteDetail__c = '<p><i>Updated</i> content with <b>formatting</b></p>';
        update note;
        Test.stopTest();
        
        LegalCaseNote__c result = [SELECT NoteDetailSearch__c FROM LegalCaseNote__c WHERE Id = :note.Id];
        System.assert(!result.NoteDetailSearch__c.contains('<'), 'HTML tags should be stripped on update');
        System.assert(result.NoteDetailSearch__c.contains('Updated'), 'Updated text should be preserved');
    }
    
    @isTest
    static void testNullNoteDetail() {
        LegalCase__c testCase = [SELECT Id FROM LegalCase__c LIMIT 1];
        
        LegalCaseNote__c note = new LegalCaseNote__c(
            LegalCase__c = testCase.Id,
            NoteDetail__c = null
        );
        
        Test.startTest();
        insert note;
        Test.stopTest();
        
        LegalCaseNote__c result = [SELECT NoteDetailSearch__c FROM LegalCaseNote__c WHERE Id = :note.Id];
        System.assertEquals(null, result.NoteDetailSearch__c, 'Search field should be null when detail is null');
    }
}