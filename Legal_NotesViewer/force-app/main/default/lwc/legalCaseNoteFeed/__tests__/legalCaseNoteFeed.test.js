import { createElement } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import LegalCaseNoteFeed from "c/legalCaseNoteFeed";
import getNotes from "@salesforce/apex/LegalCaseNoteFeedController.getNotes";

jest.mock(
  "@salesforce/apex/LegalCaseNoteFeedController.getNotes",
  () => ({ default: jest.fn() }),
  {
    virtual: true
  }
);

// The default lightning/navigation jest stub defines NavigationMixin.Navigate as an
// inherited, non-writable method, which jest.spyOn can't reassign directly (it throws
// "Cannot assign to read only property"). Object.defineProperty on the component's own
// prototype shadows the inherited method regardless, so a plain jest.fn() is used instead.
const navigateMock = jest.fn();
Object.defineProperty(LegalCaseNoteFeed.prototype, NavigationMixin.Navigate, {
  value: navigateMock,
  writable: true,
  configurable: true
});

const SEARCH_DEBOUNCE_MS = 300;

const NOTE_1 = {
  Id: "a001",
  Subject__c: "Initial intake call",
  NoteDate__c: "2026-07-01",
  NoteDetail__c: "<p>Discussed timeline.</p>",
  Author__r: { Id: "005000000000001", Name: "Jane Attorney" }
};

const NOTE_2 = {
  Id: "a002",
  Subject__c: "Court filing",
  NoteDate__c: "2026-07-05",
  NoteDetail__c: "<p>Filed motion.</p>",
  Author__r: { Id: "005000000000002", Name: "Jane Attorney" }
};

const LONG_PLAIN_TEXT = Array.from({ length: 310 }, (_, i) => `word${i}`).join(
  " "
);

const LONG_NOTE = {
  Id: "a003",
  Subject__c: "Lengthy note",
  NoteDate__c: "2026-07-10",
  NoteDetail__c: `<p>${LONG_PLAIN_TEXT}</p>`,
  Author__r: null
};

const SETTLEMENT_NOTE = {
  Id: "a004",
  Subject__c: "Follow-up",
  NoteDate__c: "2026-07-11",
  NoteDetail__c: "<p>We discussed a settlement offer today.</p>",
  Author__r: null
};

function flushPromises() {
  // eslint-disable-next-line @lwc/lwc/no-async-operation
  return new Promise((resolve) => window.setTimeout(resolve, 0));
}

function createFeedElement() {
  const element = createElement("c-legal-case-note-feed", {
    is: LegalCaseNoteFeed
  });
  element.recordId = "a00CaseId";
  document.body.appendChild(element);
  return element;
}

describe("c-legal-case-note-feed", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("loads and renders notes for the record on connect", async () => {
    getNotes.mockResolvedValue({ notes: [NOTE_2, NOTE_1], hasMore: false });

    const element = createFeedElement();
    await flushPromises();

    expect(getNotes).toHaveBeenCalledWith({
      legalCaseId: "a00CaseId",
      searchTerm: "",
      pageSize: 10,
      pageOffset: 0,
      sortDirection: "DESC"
    });

    const cards = element.shadowRoot.querySelectorAll(".note-card");
    expect(cards.length).toBe(2);
  });

  it("debounces search input and reloads with the new term", async () => {
    getNotes.mockResolvedValue({ notes: [NOTE_1], hasMore: false });

    const element = createFeedElement();
    await flushPromises();

    getNotes.mockClear();
    getNotes.mockResolvedValue({ notes: [NOTE_2], hasMore: false });

    const searchInput = element.shadowRoot.querySelector("lightning-input");
    searchInput.value = "court";
    searchInput.dispatchEvent(new CustomEvent("change"));

    expect(getNotes).not.toHaveBeenCalled();

    await new Promise((resolve) =>
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      window.setTimeout(resolve, SEARCH_DEBOUNCE_MS + 50)
    );

    expect(getNotes).toHaveBeenCalledWith({
      legalCaseId: "a00CaseId",
      searchTerm: "court",
      pageSize: 10,
      pageOffset: 0,
      sortDirection: "DESC"
    });
  });

  it("loads more notes on scroll near the bottom, appending and advancing the offset", async () => {
    getNotes.mockResolvedValue({ notes: [NOTE_1], hasMore: true });

    const element = createFeedElement();
    await flushPromises();

    getNotes.mockClear();
    getNotes.mockResolvedValue({ notes: [NOTE_2], hasMore: false });

    const scrollContainer =
      element.shadowRoot.querySelector(".note-feed__scroll");
    Object.defineProperty(scrollContainer, "scrollTop", {
      value: 400,
      configurable: true
    });
    Object.defineProperty(scrollContainer, "scrollHeight", {
      value: 500,
      configurable: true
    });
    Object.defineProperty(scrollContainer, "clientHeight", {
      value: 100,
      configurable: true
    });

    scrollContainer.dispatchEvent(new CustomEvent("scroll"));
    await flushPromises();

    expect(getNotes).toHaveBeenCalledWith({
      legalCaseId: "a00CaseId",
      searchTerm: "",
      pageSize: 10,
      pageOffset: 1,
      sortDirection: "DESC"
    });

    const cards = element.shadowRoot.querySelectorAll(".note-card");
    expect(cards.length).toBe(2);
  });

  it("changing the sort option reloads notes with the new direction and resets to page 0", async () => {
    getNotes.mockResolvedValue({ notes: [NOTE_1], hasMore: true });

    const element = createFeedElement();
    await flushPromises();

    getNotes.mockClear();
    getNotes.mockResolvedValue({ notes: [NOTE_2], hasMore: false });

    const sortCombobox = element.shadowRoot.querySelector("lightning-combobox");
    sortCombobox.dispatchEvent(
      new CustomEvent("change", { detail: { value: "ASC" } })
    );
    await flushPromises();

    expect(getNotes).toHaveBeenCalledWith({
      legalCaseId: "a00CaseId",
      searchTerm: "",
      pageSize: 10,
      pageOffset: 0,
      sortDirection: "ASC"
    });
  });

  it("shows a truncated preview with Show more, expanding to the full rich text on click", async () => {
    getNotes.mockResolvedValue({ notes: [LONG_NOTE], hasMore: false });

    const element = createFeedElement();
    await flushPromises();

    const toggle = element.shadowRoot.querySelector(".note-card__toggle");
    expect(toggle).not.toBeNull();
    expect(toggle.textContent.trim()).toBe("Show more");
    expect(
      element.shadowRoot.querySelector("lightning-formatted-rich-text")
    ).toBeNull();

    toggle.click();
    await flushPromises();

    expect(
      element.shadowRoot.querySelector(".note-card__toggle").textContent.trim()
    ).toBe("Show less");
    expect(
      element.shadowRoot.querySelector("lightning-formatted-rich-text")
    ).not.toBeNull();
  });

  it("highlights the search term within the note preview", async () => {
    getNotes.mockResolvedValue({ notes: [], hasMore: false });

    const element = createFeedElement();
    await flushPromises();

    getNotes.mockClear();
    getNotes.mockResolvedValue({ notes: [SETTLEMENT_NOTE], hasMore: false });

    const searchInput = element.shadowRoot.querySelector("lightning-input");
    searchInput.value = "settlement";
    searchInput.dispatchEvent(new CustomEvent("change"));

    await new Promise((resolve) =>
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      window.setTimeout(resolve, SEARCH_DEBOUNCE_MS + 50)
    );
    await flushPromises();

    const mark = element.shadowRoot.querySelector("mark");
    expect(mark).not.toBeNull();
    expect(mark.textContent.toLowerCase()).toContain("settlement");
  });

  it("clicking the author link navigates to the User record", async () => {
    getNotes.mockResolvedValue({ notes: [NOTE_1], hasMore: false });

    const element = createFeedElement();
    await flushPromises();

    const authorLink = element.shadowRoot.querySelector(
      ".note-card__author-link"
    );
    expect(authorLink).not.toBeNull();
    expect(authorLink.getAttribute("href")).toBe("https://www.example.com");

    authorLink.click();

    expect(navigateMock).toHaveBeenCalledWith({
      type: "standard__recordPage",
      attributes: {
        recordId: NOTE_1.Author__r.Id,
        objectApiName: "User",
        actionName: "view"
      }
    });
  });

  it("clicking the edit link navigates to the note's edit page", async () => {
    getNotes.mockResolvedValue({ notes: [NOTE_1], hasMore: false });

    const element = createFeedElement();
    await flushPromises();

    const editLink = element.shadowRoot.querySelector(".note-card__edit-link");
    expect(editLink).not.toBeNull();
    expect(editLink.getAttribute("href")).toBe("https://www.example.com");

    editLink.click();

    expect(navigateMock).toHaveBeenCalledWith({
      type: "standard__recordPage",
      attributes: {
        recordId: NOTE_1.Id,
        objectApiName: "LegalCaseNote__c",
        actionName: "edit"
      }
    });
  });
});
