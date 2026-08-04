@isTest
private class LegalCaseNoteFeedControllerTest {
  @TestSetup
  static void setupData() {
    LegalCase__c targetCase = new LegalCase__c();
    LegalCase__c otherCase = new LegalCase__c();
    insert new List<LegalCase__c>{ targetCase, otherCase };

    insert new List<LegalCaseNote__c>{
      new LegalCaseNote__c(
        LegalCase__c = targetCase.Id,
        Subject__c = 'Initial intake call',
        NoteDetail__c = '<p>Discussed eviction timeline with client.</p>',
        NoteDate__c = Date.today().addDays(-5)
      ),
      new LegalCaseNote__c(
        LegalCase__c = targetCase.Id,
        Subject__c = 'Court filing',
        NoteDetail__c = '<p>Filed motion to dismiss.</p>',
        NoteDate__c = Date.today().addDays(-3)
      ),
      new LegalCaseNote__c(
        LegalCase__c = targetCase.Id,
        Subject__c = 'Follow-up',
        NoteDetail__c = '<p>Client mentioned a potential settlement offer from opposing counsel.</p>',
        NoteDate__c = Date.today().addDays(-1)
      ),
      new LegalCaseNote__c(
        LegalCase__c = otherCase.Id,
        Subject__c = 'Unrelated case note',
        NoteDetail__c = '<p>Should never show up in the target case feed.</p>',
        NoteDate__c = Date.today()
      )
    };
  }

  @isTest
  static void testNoSearchTermReturnsAllNotesOrderedByDateDesc() {
    Id targetCaseId = getCaseIdForNoteSubject('Initial intake call');

    Test.startTest();
    LegalCaseNoteFeedController.NoteFeedPage page = LegalCaseNoteFeedController.getNotes(
      targetCaseId,
      null,
      null,
      null,
      null
    );
    Test.stopTest();

    System.assertEquals(
      3,
      page.notes.size(),
      'Expected all 3 notes returned in a single page'
    );
    System.assertEquals(
      false,
      page.hasMore,
      'A partial page means there is nothing more to load'
    );
    System.assertEquals(
      'Follow-up',
      page.notes[0].Subject__c,
      'Most recent note should be first'
    );
    System.assertEquals(
      'Court filing',
      page.notes[1].Subject__c,
      'Second most recent note should be second'
    );
    System.assertEquals(
      'Initial intake call',
      page.notes[2].Subject__c,
      'Oldest note should be last'
    );
  }

  @isTest
  static void testAscendingSortReturnsOldestFirst() {
    Id targetCaseId = getCaseIdForNoteSubject('Initial intake call');

    Test.startTest();
    LegalCaseNoteFeedController.NoteFeedPage page = LegalCaseNoteFeedController.getNotes(
      targetCaseId,
      null,
      null,
      null,
      'ASC'
    );
    Test.stopTest();

    System.assertEquals(3, page.notes.size());
    System.assertEquals(
      'Initial intake call',
      page.notes[0].Subject__c,
      'Oldest note should be first'
    );
    System.assertEquals('Court filing', page.notes[1].Subject__c);
    System.assertEquals(
      'Follow-up',
      page.notes[2].Subject__c,
      'Most recent note should be last'
    );
  }

  @isTest
  static void testSearchTermMatchingSubjectReturnsOnlyThatNote() {
    Id targetCaseId = getCaseIdForNoteSubject('Initial intake call');
    Id courtFilingNoteId = getNoteId('Court filing');
    Test.setFixedSearchResults(new List<Id>{ courtFilingNoteId });

    Test.startTest();
    LegalCaseNoteFeedController.NoteFeedPage page = LegalCaseNoteFeedController.getNotes(
      targetCaseId,
      'filing',
      null,
      null,
      null
    );
    Test.stopTest();

    System.assertEquals(
      1,
      page.notes.size(),
      'Expected exactly one note matching the subject keyword'
    );
    System.assertEquals('Court filing', page.notes[0].Subject__c);
  }

  @isTest
  static void testSearchTermMatchingNoteBodyReturnsThatNote() {
    Id targetCaseId = getCaseIdForNoteSubject('Initial intake call');
    Id followUpNoteId = getNoteId('Follow-up');
    Test.setFixedSearchResults(new List<Id>{ followUpNoteId });

    Test.startTest();
    LegalCaseNoteFeedController.NoteFeedPage page = LegalCaseNoteFeedController.getNotes(
      targetCaseId,
      'settlement offer',
      null,
      null,
      null
    );
    Test.stopTest();

    System.assertEquals(
      1,
      page.notes.size(),
      'Expected the body-text search to match via the NoteDetailSearch__c mirror field'
    );
    System.assertEquals('Follow-up', page.notes[0].Subject__c);
  }

  @isTest
  static void testSearchTermMatchingNothingReturnsEmptyPage() {
    Id targetCaseId = getCaseIdForNoteSubject('Initial intake call');
    Test.setFixedSearchResults(new List<Id>());

    Test.startTest();
    LegalCaseNoteFeedController.NoteFeedPage page = LegalCaseNoteFeedController.getNotes(
      targetCaseId,
      'zzz-no-such-term-zzz',
      null,
      null,
      null
    );
    Test.stopTest();

    System.assertEquals(0, page.notes.size());
    System.assertEquals(false, page.hasMore);
  }

  @isTest
  static void testSearchTermWithOnlyPunctuationReturnsEmptyWithoutSearching() {
    Id targetCaseId = getCaseIdForNoteSubject('Initial intake call');
    // Deliberately do not call Test.setFixedSearchResults: a punctuation-only term should
    // be filtered down to nothing and short-circuit before a SOSL query is ever issued.

    Test.startTest();
    LegalCaseNoteFeedController.NoteFeedPage page = LegalCaseNoteFeedController.getNotes(
      targetCaseId,
      '???',
      null,
      null,
      null
    );
    Test.stopTest();

    System.assertEquals(0, page.notes.size());
  }

  @isTest
  static void testPaginationReturnsCorrectSlices() {
    Id targetCaseId = getCaseIdForNoteSubject('Initial intake call');

    Test.startTest();
    LegalCaseNoteFeedController.NoteFeedPage firstPage = LegalCaseNoteFeedController.getNotes(
      targetCaseId,
      null,
      2,
      0,
      null
    );
    LegalCaseNoteFeedController.NoteFeedPage secondPage = LegalCaseNoteFeedController.getNotes(
      targetCaseId,
      null,
      2,
      2,
      null
    );
    Test.stopTest();

    System.assertEquals(
      2,
      firstPage.notes.size(),
      'First page should be capped at the requested page size'
    );
    System.assertEquals(
      true,
      firstPage.hasMore,
      'A full page means there may be more to load'
    );
    System.assertEquals('Follow-up', firstPage.notes[0].Subject__c);
    System.assertEquals('Court filing', firstPage.notes[1].Subject__c);

    System.assertEquals(
      1,
      secondPage.notes.size(),
      'Second page should contain the remaining note'
    );
    System.assertEquals(
      false,
      secondPage.hasMore,
      'A partial page means there is nothing more to load'
    );
    System.assertEquals('Initial intake call', secondPage.notes[0].Subject__c);
  }

  @isTest
  static void testNotesAreScopedToTheRequestedCase() {
    Id otherCaseId = getCaseIdForNoteSubject('Unrelated case note');

    Test.startTest();
    LegalCaseNoteFeedController.NoteFeedPage page = LegalCaseNoteFeedController.getNotes(
      otherCaseId,
      null,
      null,
      null,
      null
    );
    Test.stopTest();

    System.assertEquals(
      1,
      page.notes.size(),
      'Only the other case\'s own note should be returned'
    );
    System.assertEquals('Unrelated case note', page.notes[0].Subject__c);
  }

  private static Id getCaseIdForNoteSubject(String subject) {
    return [
      SELECT LegalCase__c
      FROM LegalCaseNote__c
      WHERE Subject__c = :subject
      LIMIT 1
    ]
    .LegalCase__c;
  }

  private static Id getNoteId(String subject) {
    return [SELECT Id FROM LegalCaseNote__c WHERE Subject__c = :subject LIMIT 1]
    .Id;
  }
}
