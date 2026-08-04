trigger LegalCaseNoteTrigger on LegalCaseNote__c (before insert, before update) {
    LegalCaseNoteHandler.stripNoteHtml(Trigger.new);
}