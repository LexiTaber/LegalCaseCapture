import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getNotes from "@salesforce/apex/LegalCaseNoteFeedController.getNotes";

const PAGE_SIZE = 10;
const SEARCH_DEBOUNCE_MS = 300;
const SCROLL_THRESHOLD_PX = 100;
const PREVIEW_WORD_LIMIT = 300;

const SORT_OPTIONS = [
  { label: "Newest first", value: "DESC" },
  { label: "Oldest first", value: "ASC" }
];

function escapeRegExp(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

// NoteDetailSearch__c (the plain-text mirror maintained server-side) isn't FLS-visible to
// every user, so the preview is derived from NoteDetail__c instead via a simple client-side
// strip. Only ever used to build read-only preview text rendered through safe template
// interpolation, never re-injected as HTML, so a full sanitizer isn't needed here.
function stripHtml(html) {
  if (!html) {
    return "";
  }
  return html
    .replace(/<[^>]*>/g, " ")
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/&quot;/gi, '"')
    .replace(/&#39;/gi, "'")
    .replace(/\s+/g, " ")
    .trim();
}

function buildPreview(plainText) {
  if (!plainText) {
    return { text: "", isTruncated: false };
  }
  const trimmed = plainText.trim();
  const words = trimmed.split(/\s+/);
  if (words.length <= PREVIEW_WORD_LIMIT) {
    return { text: trimmed, isTruncated: false };
  }
  return {
    text: `${words.slice(0, PREVIEW_WORD_LIMIT).join(" ")}…`,
    isTruncated: true
  };
}

function buildHighlightSegments(text, searchTerm) {
  if (!text) {
    return [];
  }
  const words = (searchTerm || "")
    .trim()
    .split(/\s+/)
    .map(escapeRegExp)
    .filter(Boolean);
  if (words.length === 0) {
    return [{ key: "seg-0", text, isMatch: false }];
  }
  const alternation = words.join("|");
  const splitPattern = new RegExp(`(\\b(?:${alternation})\\w*)`, "gi");
  const testPattern = new RegExp(`^(?:${alternation})\\w*$`, "i");
  return text
    .split(splitPattern)
    .filter((part) => part.length > 0)
    .map((part, index) => ({
      key: `seg-${index}`,
      text: part,
      isMatch: testPattern.test(part)
    }));
}

function mapNoteForDisplay(note, searchTerm) {
  const preview = buildPreview(stripHtml(note.NoteDetail__c));
  return {
    ...note,
    authorId: note.Author__r ? note.Author__r.Id : null,
    authorName: note.Author__r ? note.Author__r.Name : "Unknown",
    isExpanded: false,
    isTruncated: preview.isTruncated,
    toggleLabel: "Show more",
    previewSegments: buildHighlightSegments(preview.text, searchTerm)
  };
}

function extractErrorMessage(error) {
  if (error && error.body && error.body.message) {
    return error.body.message;
  }
  return "Something went wrong loading case notes. Please try again.";
}

export default class LegalCaseNoteFeed extends NavigationMixin(
  LightningElement
) {
  @api recordId;

  notes = [];
  searchTerm = "";
  sortDirection = "DESC";
  sortOptions = SORT_OPTIONS;
  hasMore = false;
  isLoading = false;
  isLoadingMore = false;
  errorMessage;

  pageOffset = 0;
  searchDelayTimeout;

  connectedCallback() {
    this.loadNotes({ reset: true });
  }

  get hasNotes() {
    return this.notes.length > 0;
  }

  get showEmptyNoNotes() {
    return !this.isLoading && !this.hasNotes && !this.searchTerm;
  }

  get showEmptyNoMatches() {
    return !this.isLoading && !this.hasNotes && !!this.searchTerm;
  }

  handleSearchInput(event) {
    const value = event.target.value;
    window.clearTimeout(this.searchDelayTimeout);
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.searchDelayTimeout = window.setTimeout(() => {
      this.searchTerm = value;
      this.loadNotes({ reset: true });
    }, SEARCH_DEBOUNCE_MS);
  }

  handleSortChange(event) {
    this.sortDirection = event.detail.value;
    this.loadNotes({ reset: true });
  }

  handleScroll(event) {
    const { scrollTop, scrollHeight, clientHeight } = event.target;
    const nearBottom =
      scrollTop + clientHeight >= scrollHeight - SCROLL_THRESHOLD_PX;
    if (nearBottom && !this.isLoading && !this.isLoadingMore && this.hasMore) {
      this.loadNotes({ reset: false });
    }
  }

  handleToggleExpand(event) {
    const noteId = event.currentTarget.dataset.noteId;
    this.notes = this.notes.map((note) => {
      if (note.Id !== noteId) {
        return note;
      }
      const isExpanded = !note.isExpanded;
      return {
        ...note,
        isExpanded,
        toggleLabel: isExpanded ? "Show less" : "Show more"
      };
    });
  }

  handleAuthorClick(event) {
    event.preventDefault();
    const noteId = event.currentTarget.dataset.noteId;
    const note = this.notes.find((n) => n.Id === noteId);
    if (!note || !note.authorId) {
      return;
    }
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: note.authorId,
        objectApiName: "User",
        actionName: "view"
      }
    });
  }

  handleEditClick(event) {
    event.preventDefault();
    const noteId = event.currentTarget.dataset.noteId;
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: noteId,
        objectApiName: "LegalCaseNote__c",
        actionName: "edit"
      }
    });
  }

  loadNotes({ reset }) {
    if (reset) {
      this.pageOffset = 0;
      this.isLoading = true;
    } else {
      this.isLoadingMore = true;
    }
    this.errorMessage = undefined;

    getNotes({
      legalCaseId: this.recordId,
      searchTerm: this.searchTerm,
      pageSize: PAGE_SIZE,
      pageOffset: this.pageOffset,
      sortDirection: this.sortDirection
    })
      .then((result) => {
        const mapped = (result.notes || []).map((note) =>
          mapNoteForDisplay(note, this.searchTerm)
        );
        return this.resolveNoteLinks(mapped).then((notesWithLinks) => {
          this.notes = reset
            ? notesWithLinks
            : this.notes.concat(notesWithLinks);
          this.hasMore = result.hasMore;
          this.pageOffset += mapped.length;
        });
      })
      .catch((error) => {
        this.errorMessage = extractErrorMessage(error);
      })
      .finally(() => {
        this.isLoading = false;
        this.isLoadingMore = false;
      });
  }

  resolveNoteLinks(mappedNotes) {
    const uniqueAuthorIds = [
      ...new Set(
        mappedNotes.filter((note) => note.authorId).map((note) => note.authorId)
      )
    ];

    const authorUrlPromises = uniqueAuthorIds.map((authorId) =>
      this[NavigationMixin.GenerateUrl]({
        type: "standard__recordPage",
        attributes: {
          recordId: authorId,
          objectApiName: "User",
          actionName: "view"
        }
      }).then((url) => [authorId, url])
    );

    const editUrlPromises = mappedNotes.map((note) =>
      this[NavigationMixin.GenerateUrl]({
        type: "standard__recordPage",
        attributes: {
          recordId: note.Id,
          objectApiName: "LegalCaseNote__c",
          actionName: "edit"
        }
      }).then((url) => [note.Id, url])
    );

    return Promise.all([
      Promise.all(authorUrlPromises),
      Promise.all(editUrlPromises)
    ]).then(([authorUrlEntries, editUrlEntries]) => {
      const authorUrlMap = new Map(authorUrlEntries);
      const editUrlMap = new Map(editUrlEntries);
      return mappedNotes.map((note) => ({
        ...note,
        authorUrl: note.authorId ? authorUrlMap.get(note.authorId) : null,
        editUrl: editUrlMap.get(note.Id)
      }));
    });
  }
}
