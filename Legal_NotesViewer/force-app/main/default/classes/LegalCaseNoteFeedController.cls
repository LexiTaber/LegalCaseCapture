public with sharing class LegalCaseNoteFeedController {
  private static final Integer DEFAULT_PAGE_SIZE = 10;
  private static final Integer MAX_PAGE_SIZE = 100;
  // NoteDetailSearch__c and the raw Author__c lookup field are deliberately excluded here -
  // neither is FLS-visible to the running user, and unlike Author__r.Name/Author__r.Id
  // (relationship traversal onto standard User fields, which doesn't require FLS on the
  // Author__c lookup field itself), selecting either directly throws under
  // WITH SECURITY_ENFORCED. The LWC derives its search preview from NoteDetail__c instead.
  private static final String QUERY_FIELDS = 'Id, Subject__c, NoteDate__c, NoteDetail__c, CreatedDate, Author__r.Id, Author__r.Name';

  @AuraEnabled(cacheable=true)
  public static NoteFeedPage getNotes(
    Id legalCaseId,
    String searchTerm,
    Integer pageSize,
    Integer pageOffset,
    String sortDirection
  ) {
    Integer effectivePageSize = normalizePageSize(pageSize);
    Integer effectivePageOffset = normalizePageOffset(pageOffset);
    Boolean sortAscending = normalizeSortAscending(sortDirection);

    List<LegalCaseNote__c> notes = String.isNotBlank(searchTerm)
      ? searchNotes(
          legalCaseId,
          searchTerm,
          effectivePageSize,
          effectivePageOffset,
          sortAscending
        )
      : listNotes(
          legalCaseId,
          effectivePageSize,
          effectivePageOffset,
          sortAscending
        );

    NoteFeedPage result = new NoteFeedPage();
    result.notes = notes;
    result.hasMore = notes.size() == effectivePageSize;
    return result;
  }

  private static List<LegalCaseNote__c> listNotes(
    Id legalCaseId,
    Integer pageSize,
    Integer pageOffset,
    Boolean sortAscending
  ) {
    if (sortAscending) {
      return [
        SELECT
          Id,
          Subject__c,
          NoteDate__c,
          NoteDetail__c,
          CreatedDate,
          Author__r.Id,
          Author__r.Name
        FROM LegalCaseNote__c
        WHERE LegalCase__c = :legalCaseId
        WITH SECURITY_ENFORCED
        ORDER BY NoteDate__c ASC NULLS FIRST, CreatedDate ASC
        LIMIT :pageSize
        OFFSET :pageOffset
      ];
    }
    return [
      SELECT
        Id,
        Subject__c,
        NoteDate__c,
        NoteDetail__c,
        CreatedDate,
        Author__r.Id,
        Author__r.Name
      FROM LegalCaseNote__c
      WHERE LegalCase__c = :legalCaseId
      WITH SECURITY_ENFORCED
      ORDER BY NoteDate__c DESC NULLS LAST, CreatedDate DESC
      LIMIT :pageSize
      OFFSET :pageOffset
    ];
  }

  // NoteDetailSearch__c is a Long Text Area field, which SOQL cannot filter on in a WHERE
  // clause at all - SOSL is the platform-supported way to keyword-search it (the same
  // mechanism Chatter/global search use). WITH SECURITY_ENFORCED isn't valid in SOSL, so
  // FLS is enforced afterward via Security.stripInaccessible instead.
  private static List<LegalCaseNote__c> searchNotes(
    Id legalCaseId,
    String searchTerm,
    Integer pageSize,
    Integer pageOffset,
    Boolean sortAscending
  ) {
    String soslSearchTerm = buildSoslSearchTerm(searchTerm);
    if (String.isBlank(soslSearchTerm)) {
      return new List<LegalCaseNote__c>();
    }

    // sortAscending is a Boolean, so direction/nullsClause can only ever be one of these two
    // fixed literals - safe to concatenate into the dynamic SOSL string below.
    String direction = sortAscending ? 'ASC' : 'DESC';
    String nullsClause = sortAscending ? 'NULLS FIRST' : 'NULLS LAST';

    String soslQuery =
      'FIND \'' +
      soslSearchTerm +
      '\' IN ALL FIELDS ' +
      'RETURNING LegalCaseNote__c(' +
      QUERY_FIELDS +
      ' WHERE LegalCase__c = \'' +
      legalCaseId +
      '\'' +
      ' ORDER BY NoteDate__c ' +
      direction +
      ' ' +
      nullsClause +
      ', CreatedDate ' +
      direction +
      ' LIMIT ' +
      pageSize +
      ' OFFSET ' +
      pageOffset +
      ')';

    List<List<SObject>> searchResults = Search.query(soslQuery);
    List<LegalCaseNote__c> notes = (List<LegalCaseNote__c>) searchResults[0];

    SObjectAccessDecision decision = Security.stripInaccessible(
      AccessType.READABLE,
      notes
    );
    return (List<LegalCaseNote__c>) decision.getRecords();
  }

  // legalCaseId and pageSize/pageOffset are strongly-typed (Id/Integer) so they can't carry
  // injected SOSL syntax. searchTerm is free-text user input, so it's reduced to alphanumeric
  // word tokens (each turned into a prefix wildcard) rather than escaped, since SOSL special
  // characters aren't needed for a plain keyword search.
  private static String buildSoslSearchTerm(String rawSearchTerm) {
    List<String> wildcardWords = new List<String>();
    for (String word : rawSearchTerm.trim().split('\\s+')) {
      String alphanumericWord = word.replaceAll('[^a-zA-Z0-9]', '');
      if (String.isNotBlank(alphanumericWord)) {
        wildcardWords.add(alphanumericWord + '*');
      }
    }
    return String.join(wildcardWords, ' AND ');
  }

  private static Integer normalizePageSize(Integer pageSize) {
    if (pageSize == null || pageSize <= 0) {
      return DEFAULT_PAGE_SIZE;
    }
    return Math.min(pageSize, MAX_PAGE_SIZE);
  }

  private static Integer normalizePageOffset(Integer pageOffset) {
    if (pageOffset == null || pageOffset < 0) {
      return 0;
    }
    return pageOffset;
  }

  private static Boolean normalizeSortAscending(String sortDirection) {
    return sortDirection != null && sortDirection.equalsIgnoreCase('ASC');
  }

  public class NoteFeedPage {
    @AuraEnabled
    public List<LegalCaseNote__c> notes;
    @AuraEnabled
    public Boolean hasMore;
  }
}
