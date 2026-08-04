public class LegalCaseNoteHandler {
    public static void stripNoteHtml(List<LegalCaseNote__c> notes) {
        for (LegalCaseNote__c note : notes) {
            if (note.NoteDetail__c != null) {
                note.NoteDetailSearch__c = note.NoteDetail__c
                    .replaceAll('<[^>]+>', ' ')
                    .replaceAll('&nbsp;', ' ')
                    .replaceAll('&amp;', '&')
                    .replaceAll('&lt;', '<')
                    .replaceAll('&gt;', '>')
                    .replaceAll('\\s+', ' ')
                    .trim();
            } else {
                note.NoteDetailSearch__c = null;
            }
        }
    }
}