// Seeds 25 varied-length, gibberish-topic dummy notes on case a6sAK000000079ZYAQ for
// exercising search/highlight/sort/truncation in the legalCaseNoteFeed LWC.
// Run with: sf apex run --file scripts/apex/seedLegalCaseNotesV2.apex --target-org KHRCSandbox
//
// Search-testing cheat sheet (all matches are in the note body, not the subject):
//   "gavel"          -> several notes (filler group A)
//   "ledger"         -> several notes (filler group B)
//   "confederation"  -> several notes (filler group C)
//   "gravitational"  -> exactly 2 notes (Personal Injury Claim + Small Claims Dispute)
//   "quantum toaster" -> exactly 1 note (Patent Infringement)
//   "phantom easement" -> exactly 1 note (Zoning Appeal)

Id legalCaseId = 'a6sAK000000079ZYAQ';

List<String> fillers = new List<String>{
    'The tribunal gavel echoed through the chamber as counsel debated the merits of the underlying claim. Witnesses shuffled their notes while the clerk recorded each objection with mechanical precision. ',
    'A dusty ledger of transactions was produced as evidence, each entry scrutinized for signs of irregularity. Opposing counsel argued the figures had been altered sometime after the fiscal quarter closed. ',
    'Representatives of the regional confederation submitted a joint brief outlining their interpretation of the disputed clause. The panel requested additional briefing before scheduling oral argument. '
};

List<String> lengthTiers = new List<String>{ 'short', 'medium', 'long', 'medium', 'veryLong' };

List<Map<String, String>> topics = new List<Map<String, String>>{
    new Map<String, String>{ 'subject' => 'Contract Dispute', 'phrase' => 'widget confederation accord' },
    new Map<String, String>{ 'subject' => 'Zoning Appeal', 'phrase' => 'phantom easement claim' },
    new Map<String, String>{ 'subject' => 'Custody Hearing', 'phrase' => 'moonlight visitation clause' },
    new Map<String, String>{ 'subject' => 'Patent Infringement', 'phrase' => 'quantum toaster prototype' },
    new Map<String, String>{ 'subject' => 'Employment Dispute', 'phrase' => 'sabbatical grievance protocol' },
    new Map<String, String>{ 'subject' => 'Landlord Tenant Matter', 'phrase' => 'spectral leasehold agreement' },
    new Map<String, String>{ 'subject' => 'Immigration Case', 'phrase' => 'wandering visa anomaly' },
    new Map<String, String>{ 'subject' => 'Tax Fraud Investigation', 'phrase' => 'invisible ledger discrepancy' },
    new Map<String, String>{ 'subject' => 'Personal Injury Claim', 'phrase' => 'gravitational slip incident' },
    new Map<String, String>{ 'subject' => 'Divorce Settlement', 'phrase' => 'asteroid alimony formula' },
    new Map<String, String>{ 'subject' => 'Bankruptcy Filing', 'phrase' => 'phoenix reorganization plan' },
    new Map<String, String>{ 'subject' => 'Trademark Dispute', 'phrase' => 'singing logo controversy' },
    new Map<String, String>{ 'subject' => 'Environmental Violation', 'phrase' => 'glowing river anomaly' },
    new Map<String, String>{ 'subject' => 'Insurance Claim', 'phrase' => 'teleporting vehicle claim' },
    new Map<String, String>{ 'subject' => 'Criminal Defense', 'phrase' => 'midnight burglary testimony' },
    new Map<String, String>{ 'subject' => 'Contract Renewal', 'phrase' => 'eternal handshake agreement' },
    new Map<String, String>{ 'subject' => 'Arbitration Hearing', 'phrase' => 'silent gavel proceeding' },
    new Map<String, String>{ 'subject' => 'Class Action Suit', 'phrase' => 'thousand voices petition' },
    new Map<String, String>{ 'subject' => 'Regulatory Compliance', 'phrase' => 'purple tape audit' },
    new Map<String, String>{ 'subject' => 'Whistleblower Complaint', 'phrase' => 'echo chamber disclosure' },
    new Map<String, String>{ 'subject' => 'Merger Review', 'phrase' => 'unicorn acquisition clause' },
    new Map<String, String>{ 'subject' => 'Data Breach Incident', 'phrase' => 'shadow server incident' },
    new Map<String, String>{ 'subject' => 'Discrimination Claim', 'phrase' => 'backwards promotion policy' },
    new Map<String, String>{ 'subject' => 'Small Claims Dispute', 'phrase' => 'borrowed lawnmower dispute, echoing the earlier gravitational slip incident' },
    new Map<String, String>{ 'subject' => 'Appeal Brief', 'phrase' => 'final gavel echo' }
};

Map<String, Integer> repeatsByTier = new Map<String, Integer>{
    'short' => 2,
    'medium' => 10,
    'long' => 35,
    'veryLong' => 65
};

List<LegalCaseNote__c> notesToInsert = new List<LegalCaseNote__c>();
Integer totalNotes = topics.size();

for (Integer i = 0; i < totalNotes; i++) {
    Map<String, String> topic = topics[i];
    String filler = fillers[Math.mod(i, fillers.size())];
    String tier = lengthTiers[Math.mod(i, lengthTiers.size())];
    Integer repeatCount = repeatsByTier.get(tier);

    String body = '';
    for (Integer r = 0; r < repeatCount; r++) {
        body += '<p>' + filler + '</p>';
    }
    body += '<p>Case notes reference the ' + topic.get('phrase') + ' as a central point of contention.</p>';

    notesToInsert.add(
        new LegalCaseNote__c(
            LegalCase__c = legalCaseId,
            Author__c = UserInfo.getUserId(),
            Subject__c = topic.get('subject'),
            NoteDate__c = Date.today().addDays(-(totalNotes - i) * 2),
            NoteDetail__c = body
        )
    );
}

insert notesToInsert;
System.debug('Inserted ' + notesToInsert.size() + ' dummy LegalCaseNote__c records on case ' + legalCaseId);
