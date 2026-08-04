// One-off dummy data seed for previewing the legalCaseNoteFeed LWC.
// Run with: sf apex run --file scripts/apex/seedLegalCaseNotes.apex --target-org KHRCSandbox
// Inserts ~24 varied-length notes (roughly 400-2900 words each, mirroring realistic
// note sizes) on a single case, spread across the last ~7 weeks, with two notes
// carrying a distinctive body-only phrase to verify keyword search hits note content
// (not just the subject).

Id legalCaseId = 'a6sAK000000079ZYAQ';

String paragraph =
    'Reviewed case file materials in preparation for the next procedural step. ' +
    'Discussed key facts and strategic considerations with the client and confirmed next actions. ' +
    'Noted potential risks and documented follow-up items for the team to track before the next deadline. ' +
    'Coordinated with support staff to ensure all relevant documents are organized and accessible. ';

List<String> subjects = new List<String>{
    'Initial client intake',
    'Discovery request drafted',
    'Deposition scheduled',
    'Settlement conference notes',
    'Court filing acknowledged',
    'Opposing counsel correspondence',
    'Case status review',
    'Evidence review',
    'Witness interview summary',
    'Motion hearing prep',
    'Client check-in call',
    'Document production received',
    'Expert witness consultation',
    'Mediation session summary',
    'Appeal strategy discussion',
    'Deadline extension request',
    'Trial preparation notes',
    'Post-hearing follow-up',
    'Financial hardship review',
    'Case closure summary',
    'Deposition transcript received',
    'Client hardship documentation',
    'Follow-up settlement discussion',
    'Case timeline review'
};

Integer totalNotes = subjects.size();
List<LegalCaseNote__c> notesToInsert = new List<LegalCaseNote__c>();

for (Integer i = 0; i < totalNotes; i++) {
    Integer repeatCount = 8 + Math.mod(i * 5, 46);
    String body = '';
    for (Integer r = 0; r < repeatCount; r++) {
        body += '<p>' + paragraph + '</p>';
    }

    // Plant a body-only phrase on two notes so search can be verified against
    // NoteDetailSearch__c content, not just Subject__c.
    if (i == 3 || i == 15) {
        body += '<p>The parties discussed a confidential settlement offer of forty five thousand dollars during this conversation.</p>';
    }

    notesToInsert.add(
        new LegalCaseNote__c(
            LegalCase__c = legalCaseId,
            Author__c = UserInfo.getUserId(),
            Subject__c = subjects[i],
            NoteDate__c = Date.today().addDays(-(totalNotes - i) * 2),
            NoteDetail__c = body
        )
    );
}

insert notesToInsert;
System.debug('Inserted ' + notesToInsert.size() + ' dummy LegalCaseNote__c records on case ' + legalCaseId);
