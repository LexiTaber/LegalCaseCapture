// Deletes the 24 dummy LegalCaseNote__c records created by seedLegalCaseNotes.apex on
// case a6sAK000000079ZYAQ. Targets explicit Ids (not a broad query) so it can't touch the
// pre-existing "Test Note" record or anything else on the case.
// Run with: sf apex run --file scripts/apex/deleteSeedLegalCaseNotes.apex --target-org KHRCSandbox

List<Id> seedNoteIds = new List<Id>{
    'a6qAK0000003x3ZYAQ',
    'a6qAK0000003x3aYAA',
    'a6qAK0000003x3bYAA',
    'a6qAK0000003x3cYAA',
    'a6qAK0000003x3dYAA',
    'a6qAK0000003x3eYAA',
    'a6qAK0000003x3fYAA',
    'a6qAK0000003x3gYAA',
    'a6qAK0000003x3hYAA',
    'a6qAK0000003x3iYAA',
    'a6qAK0000003x3jYAA',
    'a6qAK0000003x3kYAA',
    'a6qAK0000003x3lYAA',
    'a6qAK0000003x3mYAA',
    'a6qAK0000003x3nYAA',
    'a6qAK0000003x3oYAA',
    'a6qAK0000003x3pYAA',
    'a6qAK0000003x3qYAA',
    'a6qAK0000003x3rYAA',
    'a6qAK0000003x3sYAA',
    'a6qAK0000003x3tYAA',
    'a6qAK0000003x3uYAA',
    'a6qAK0000003x3vYAA',
    'a6qAK0000003x3wYAA'
};

List<LegalCaseNote__c> notesToDelete = [
    SELECT Id
    FROM LegalCaseNote__c
    WHERE Id IN :seedNoteIds
];

System.debug('Deleting ' + notesToDelete.size() + ' seed notes (expected 24).');
delete notesToDelete;
System.debug('Delete complete.');
