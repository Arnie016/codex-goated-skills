const STORAGE_PREFIX = "on-this-day-studio";
const CACHE_PREFIX = `${STORAGE_PREFIX}:cache:`;
const TIME_ZONE = "Asia/Singapore";

const KINDS = [
  { id: "selected", label: "Curated", hint: "Editor-picked anchors" },
  { id: "events", label: "Events", hint: "Broader historical events" },
  { id: "births", label: "Births", hint: "Notable people born" },
  { id: "deaths", label: "Deaths", hint: "Notable people lost" },
  { id: "holidays", label: "Holidays", hint: "Observances on this day" },
];

const initialKind = readValue("kind");

const state = {
  date: readValue("date") || todayInTimeZone(TIME_ZONE),
  activeKind: KINDS.some((kind) => kind.id === initialKind) ? initialKind : "selected",
  limit: clampNumber(Number(readValue("limit") || 6), 3, 10),
  feed: null,
  loading: false,
  sourceMode: "Loading",
  note: "",
  spotlightIndex: 0,
};

const elements = {};

window.addEventListener("DOMContentLoaded", () => {
  bindElements();
  renderKindButtons();
  wireEvents();
  syncControlsFromState();
  fetchAndRender();
});

function bindElements() {
  elements.heroTitle = document.getElementById("hero-title");
  elements.heroSubtitle = document.getElementById("hero-subtitle");
  elements.dataState = document.getElementById("data-state");
  elements.dayProgress = document.getElementById("day-progress");
  elements.dateInput = document.getElementById("date-input");
  elements.todayButton = document.getElementById("today-button");
  elements.randomButton = document.getElementById("random-button");
  elements.previousButton = document.getElementById("previous-button");
  elements.nextButton = document.getElementById("next-button");
  elements.copyButton = document.getElementById("copy-button");
  elements.retryButton = document.getElementById("retry-button");
  elements.shuffleButton = document.getElementById("shuffle-button");
  elements.typeSegmented = document.getElementById("type-segmented");
  elements.limitRange = document.getElementById("limit-range");
  elements.limitValue = document.getElementById("limit-value");
  elements.overviewGrid = document.getElementById("overview-grid");
  elements.storyHeading = document.getElementById("story-heading");
  elements.storyGrid = document.getElementById("story-grid");
  elements.emptyState = document.getElementById("empty-state");
  elements.emptyMessage = document.getElementById("empty-message");
  elements.storyCardTemplate = document.getElementById("story-card-template");
  elements.spotlightTitle = document.getElementById("spotlight-title");
  elements.spotlightText = document.getElementById("spotlight-text");
  elements.spotlightKind = document.getElementById("spotlight-kind");
  elements.spotlightYear = document.getElementById("spotlight-year");
  elements.spotlightLink = document.getElementById("spotlight-link");
  elements.toast = document.getElementById("toast");
}

function wireEvents() {
  elements.todayButton.addEventListener("click", () => {
    state.date = todayInTimeZone(TIME_ZONE);
    state.spotlightIndex = 0;
    syncControlsFromState();
    persistPreferences();
    fetchAndRender();
  });

  elements.randomButton.addEventListener("click", () => {
    state.date = randomIsoDate();
    state.spotlightIndex = 0;
    syncControlsFromState();
    persistPreferences();
    fetchAndRender();
  });

  elements.previousButton.addEventListener("click", () => moveDateBy(-1));
  elements.nextButton.addEventListener("click", () => moveDateBy(1));
  elements.retryButton.addEventListener("click", () => fetchAndRender());

  elements.copyButton.addEventListener("click", async () => {
    const digest = buildDigest();
    try {
      await navigator.clipboard.writeText(digest);
      showToast("Daily brief copied.");
    } catch (error) {
      showToast("Clipboard blocked. You can still copy from the page.");
    }
  });

  elements.shuffleButton.addEventListener("click", () => {
    const items = visibleItems();
    if (!items.length) {
      showToast("No entries to spotlight yet.");
      return;
    }
    state.spotlightIndex = Math.floor(Math.random() * items.length);
    render();
  });

  elements.dateInput.addEventListener("change", (event) => {
    if (!event.target.value) {
      return;
    }
    state.date = event.target.value;
    state.spotlightIndex = 0;
    persistPreferences();
    fetchAndRender();
  });

  elements.limitRange.addEventListener("input", (event) => {
    state.limit = clampNumber(Number(event.target.value), 3, 10);
    elements.limitValue.textContent = String(state.limit);
    persistPreferences();
    render();
  });
}

function renderKindButtons() {
  elements.typeSegmented.innerHTML = "";

  for (const kind of KINDS) {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "segmented-button";
    button.dataset.kind = kind.id;
    button.innerHTML = `
      <span class="segmented-dot"></span>
      <span class="segmented-label">${kind.label}</span>
      <span class="segmented-hint">${kind.hint}</span>
      <span class="status-chip segmented-count">0</span>
    `;
    button.addEventListener("click", () => {
      state.activeKind = kind.id;
      state.spotlightIndex = 0;
      persistPreferences();
      render();
    });
    elements.typeSegmented.append(button);
  }
}

async function fetchAndRender() {
  state.loading = true;
  state.note = "";
  render();

  const requestDate = state.date;
  try {
    const result = await fetchFeed(requestDate);
    if (requestDate !== state.date) {
      return;
    }
    state.feed = result.data;
    state.sourceMode = result.sourceMode;
    state.note = result.note;
  } catch (error) {
    if (requestDate !== state.date) {
      return;
    }
    state.feed = null;
    state.sourceMode = "Error";
    state.note = error instanceof Error ? error.message : "Unable to load feed.";
  } finally {
    state.loading = false;
    render();
  }
}

async function fetchFeed(isoDate) {
  try {
    const response = await fetch(buildApiUrl(isoDate), {
      headers: { Accept: "application/json" },
    });

    if (!response.ok) {
      throw new Error(`Wikimedia returned ${response.status}.`);
    }

    const data = await response.json();
    persistCachedFeed(isoDate, data);
    return {
      data,
      sourceMode: "Live",
      note: "",
    };
  } catch (error) {
    const cached = readCachedFeed(isoDate);
    if (cached) {
      return {
        data: cached,
        sourceMode: "Cached",
        note: "Live request failed, so this view is using the last saved snapshot for the same date.",
      };
    }
    throw new Error(error instanceof Error ? error.message : "Network request failed.");
  }
}

function render() {
  syncControlsFromState();
  renderDataState();
  renderHero();
  renderCounts();
  renderStories();
  renderSpotlight();
}

function renderDataState() {
  elements.dataState.className = "status-chip";

  if (state.loading) {
    elements.dataState.classList.add("status-loading");
    elements.dataState.textContent = "Syncing";
    return;
  }

  if (state.sourceMode === "Live") {
    elements.dataState.classList.add("status-live");
    elements.dataState.textContent = "Live feed";
    return;
  }

  if (state.sourceMode === "Cached") {
    elements.dataState.classList.add("status-cached");
    elements.dataState.textContent = "Cached snapshot";
    return;
  }

  elements.dataState.classList.add("status-error");
  elements.dataState.textContent = "Feed error";
}

function renderHero() {
  elements.heroTitle.textContent = formatDisplayDate(state.date);
  elements.dayProgress.textContent = daySignal(state.date);

  if (state.loading && !state.feed) {
    elements.heroSubtitle.textContent =
      "Pulling the official On This Day archive and building a cleaner daily readout.";
    return;
  }

  const selectedCount = itemCount("selected");
  const eventsCount = itemCount("events");
  const holidaysCount = itemCount("holidays");
  const active = kindLabel(state.activeKind);

  const fragments = [
    `${selectedCount} curated picks`,
    `${eventsCount} raw events`,
    `${holidaysCount} observances`,
  ];

  const summary = `${active} view for ${formatShortDate(state.date)}. ${fragments.join(", ")}.`;
  elements.heroSubtitle.textContent = state.note ? `${summary} ${state.note}` : summary;
}

function renderCounts() {
  const buttons = elements.typeSegmented.querySelectorAll(".segmented-button");
  for (const button of buttons) {
    const kind = button.dataset.kind;
    const countBubble = button.querySelector(".segmented-count");
    countBubble.textContent = String(itemCount(kind));
    button.classList.toggle("active", kind === state.activeKind);
    button.setAttribute("aria-selected", kind === state.activeKind ? "true" : "false");
  }

  const cards = KINDS.map((kind) => {
    const count = itemCount(kind.id);
    const activeClass = kind.id === state.activeKind ? "overview-card active" : "overview-card";
    return `
      <article class="${activeClass}">
        <span>${kind.label}</span>
        <strong>${count}</strong>
        <span>${kind.hint}</span>
      </article>
    `;
  });

  elements.overviewGrid.innerHTML = cards.join("");
}

function renderStories() {
  const { kind, items } = selectedStorySet();
  elements.storyHeading.textContent = `${kindLabel(kind)} on ${formatMonthDay(state.date)}`;
  elements.storyGrid.innerHTML = "";

  if (!items.length) {
    elements.emptyState.classList.remove("hidden");
    elements.emptyMessage.textContent = state.note
      ? state.note
      : "No entries came back for this slice. Try another category or date.";
    return;
  }

  elements.emptyState.classList.add("hidden");

  items.forEach((item, index) => {
    const fragment = elements.storyCardTemplate.content.cloneNode(true);
    const card = fragment.querySelector(".story-card");
    const meta = normalizeItem(item, kind);

    card.style.setProperty("--delay", `${Math.min(index * 60, 360)}ms`);
    fragment.querySelector(".story-year").textContent = meta.yearLabel;
    fragment.querySelector(".story-kind").textContent = kindLabel(kind);
    fragment.querySelector(".story-title").textContent = meta.heading;
    fragment.querySelector(".story-text").textContent = meta.text;
    fragment.querySelector(".story-description").textContent = meta.description;

    const pageTagContainer = fragment.querySelector(".story-page-tags");
    for (const pageTitle of meta.pageTags) {
      const tag = document.createElement("span");
      tag.className = "story-page-tag";
      tag.textContent = pageTitle;
      pageTagContainer.append(tag);
    }

    const storyImage = fragment.querySelector(".story-image");
    const storyPlaceholder = fragment.querySelector(".story-placeholder");
    if (meta.image) {
      storyImage.src = meta.image;
      storyImage.alt = meta.heading;
      storyImage.classList.remove("hidden");
      storyPlaceholder.classList.add("hidden");
    } else {
      storyImage.classList.add("hidden");
      storyPlaceholder.classList.remove("hidden");
      storyPlaceholder.textContent = meta.yearLabel;
    }

    const link = fragment.querySelector(".story-link");
    if (meta.url) {
      link.href = meta.url;
      link.textContent = "Open on Wikipedia";
    } else {
      link.href = "https://api.wikimedia.org/wiki/Feed_API/Reference/On_this_day";
      link.textContent = "Open API reference";
    }

    elements.storyGrid.append(fragment);
  });
}

function renderSpotlight() {
  const items = visibleItems();
  if (!items.length) {
    elements.spotlightTitle.textContent = "No spotlight available";
    elements.spotlightText.textContent =
      "Once a live or cached day feed arrives, this card will pin the strongest opening fact.";
    elements.spotlightKind.textContent = kindLabel(state.activeKind);
    elements.spotlightYear.textContent = "Archive";
    elements.spotlightLink.href =
      "https://api.wikimedia.org/wiki/Feed_API/Reference/On_this_day";
    return;
  }

  const safeIndex = state.spotlightIndex % items.length;
  const spotlight = normalizeItem(items[safeIndex], selectedStorySet().kind);
  elements.spotlightTitle.textContent = spotlight.heading;
  elements.spotlightText.textContent = spotlight.text;
  elements.spotlightKind.textContent = kindLabel(selectedStorySet().kind);
  elements.spotlightYear.textContent = spotlight.yearLabel;
  elements.spotlightLink.href =
    spotlight.url || "https://api.wikimedia.org/wiki/Feed_API/Reference/On_this_day";
}

function selectedStorySet() {
  const directItems = currentItems(state.activeKind);
  if (directItems.length > 0) {
    return { kind: state.activeKind, items: directItems.slice(0, state.limit) };
  }

  if (state.activeKind === "selected") {
    const fallbackItems = currentItems("events");
    return { kind: "events", items: fallbackItems.slice(0, state.limit) };
  }

  return { kind: state.activeKind, items: [] };
}

function visibleItems() {
  return selectedStorySet().items;
}

function currentItems(kind) {
  const value = state.feed?.[kind];
  return Array.isArray(value) ? value : [];
}

function itemCount(kind) {
  return currentItems(kind).length;
}

function normalizeItem(item, kind) {
  const primaryPage = choosePrimaryPage(item.pages);
  const title =
    cleanText(
      primaryPage?.titles?.normalized ||
        primaryPage?.normalizedtitle ||
        primaryPage?.displaytitle ||
        primaryPage?.title,
    ) ||
    cleanText(typeof item.text === "string" ? item.text.split(/[,.]/)[0] : "") ||
    kindLabel(kind);

  return {
    yearLabel: item.year ? String(item.year) : kind === "holidays" ? "Holiday" : "Archive",
    heading: title,
    text: cleanText(item.text) || "No event text returned from the feed.",
    description: cleanText(primaryPage?.description) || "Linked from the official day feed.",
    image: primaryPage?.thumbnail?.source || "",
    url:
      primaryPage?.content_urls?.desktop?.page ||
      primaryPage?.content_urls?.mobile?.page ||
      "",
    pageTags: (item.pages || [])
      .map((page) =>
        cleanText(
          page?.titles?.normalized || page?.normalizedtitle || page?.displaytitle || page?.title,
        ),
      )
      .filter(Boolean)
      .slice(0, 3),
  };
}

function choosePrimaryPage(pages) {
  if (!Array.isArray(pages) || pages.length === 0) {
    return null;
  }

  return (
    pages.find((page) => page?.content_urls?.desktop?.page) ||
    pages.find((page) => page?.thumbnail?.source) ||
    pages[0]
  );
}

function buildDigest() {
  const { kind, items } = selectedStorySet();
  const lines = [
    `On This Day Studio · ${formatDisplayDate(state.date)}`,
    `${kindLabel(kind)} · ${state.sourceMode}`,
    "",
  ];

  items.forEach((item) => {
    const meta = normalizeItem(item, kind);
    const entry = [`- ${meta.yearLabel} — ${meta.text}`];
    if (meta.url) {
      entry.push(`  ${meta.url}`);
    }
    lines.push(...entry);
  });

  if (state.note) {
    lines.push("", `Note: ${state.note}`);
  }

  lines.push(
    "",
    `Source API: ${buildApiUrl(state.date)}`,
    "Official docs: https://api.wikimedia.org/wiki/Feed_API/Reference/On_this_day",
  );

  return lines.join("\n");
}

function syncControlsFromState() {
  elements.dateInput.value = state.date;
  elements.limitRange.value = String(state.limit);
  elements.limitValue.textContent = String(state.limit);
}

function moveDateBy(deltaDays) {
  state.date = addDays(state.date, deltaDays);
  state.spotlightIndex = 0;
  syncControlsFromState();
  persistPreferences();
  fetchAndRender();
}

function persistPreferences() {
  localStorage.setItem(`${STORAGE_PREFIX}:date`, state.date);
  localStorage.setItem(`${STORAGE_PREFIX}:kind`, state.activeKind);
  localStorage.setItem(`${STORAGE_PREFIX}:limit`, String(state.limit));
}

function readValue(key) {
  return localStorage.getItem(`${STORAGE_PREFIX}:${key}`);
}

function persistCachedFeed(date, data) {
  localStorage.setItem(
    `${CACHE_PREFIX}${date}`,
    JSON.stringify({
      savedAt: new Date().toISOString(),
      data,
    }),
  );
}

function readCachedFeed(date) {
  const raw = localStorage.getItem(`${CACHE_PREFIX}${date}`);
  if (!raw) {
    return null;
  }

  try {
    const parsed = JSON.parse(raw);
    return parsed.data || null;
  } catch (_error) {
    return null;
  }
}

function buildApiUrl(isoDate) {
  const { month, day } = splitIsoDate(isoDate);
  return `https://api.wikimedia.org/feed/v1/wikipedia/en/onthisday/all/${month}/${day}`;
}

function cleanText(value) {
  if (!value) {
    return "";
  }

  const wrapper = document.createElement("div");
  wrapper.innerHTML = String(value);
  return wrapper.textContent?.replace(/\s+/g, " ").trim() || "";
}

function kindLabel(kindId) {
  return KINDS.find((kind) => kind.id === kindId)?.label || "Timeline";
}

function todayInTimeZone(timeZone) {
  const formatter = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  });
  const parts = formatter.formatToParts(new Date());
  const year = parts.find((part) => part.type === "year")?.value;
  const month = parts.find((part) => part.type === "month")?.value;
  const day = parts.find((part) => part.type === "day")?.value;
  return `${year}-${month}-${day}`;
}

function formatDisplayDate(isoDate) {
  return new Intl.DateTimeFormat("en-US", {
    weekday: "long",
    month: "long",
    day: "numeric",
    timeZone: "UTC",
  }).format(isoToSafeDate(isoDate));
}

function formatShortDate(isoDate) {
  return new Intl.DateTimeFormat("en-US", {
    month: "short",
    day: "numeric",
    timeZone: "UTC",
  }).format(isoToSafeDate(isoDate));
}

function formatMonthDay(isoDate) {
  return new Intl.DateTimeFormat("en-US", {
    month: "long",
    day: "numeric",
    timeZone: "UTC",
  }).format(isoToSafeDate(isoDate));
}

function daySignal(isoDate) {
  const date = isoToSafeDate(isoDate);
  const start = Date.UTC(date.getUTCFullYear(), 0, 1);
  const ordinal = Math.floor((date.getTime() - start) / 86400000) + 1;
  return `Day ${ordinal} in the annual timeline`;
}

function isoToSafeDate(isoDate) {
  const { year, month, day } = splitIsoDate(isoDate);
  return new Date(Date.UTC(Number(year), Number(month) - 1, Number(day), 12));
}

function splitIsoDate(isoDate) {
  const [year, month, day] = isoDate.split("-");
  return { year, month, day };
}

function addDays(isoDate, deltaDays) {
  const shifted = new Date(isoToSafeDate(isoDate).getTime() + deltaDays * 86400000);
  return [
    shifted.getUTCFullYear(),
    String(shifted.getUTCMonth() + 1).padStart(2, "0"),
    String(shifted.getUTCDate()).padStart(2, "0"),
  ].join("-");
}

function randomIsoDate() {
  const currentYear = new Date().getUTCFullYear();
  const base = new Date(Date.UTC(currentYear, 0, 1, 12));
  const yearDays = isLeapYear(currentYear) ? 366 : 365;
  const offset = Math.floor(Math.random() * yearDays);
  const randomDate = new Date(base.getTime() + offset * 86400000);
  return [
    randomDate.getUTCFullYear(),
    String(randomDate.getUTCMonth() + 1).padStart(2, "0"),
    String(randomDate.getUTCDate()).padStart(2, "0"),
  ].join("-");
}

function clampNumber(value, min, max) {
  if (!Number.isFinite(value)) {
    return min;
  }
  return Math.max(min, Math.min(max, value));
}

function isLeapYear(year) {
  if (year % 400 === 0) {
    return true;
  }
  if (year % 100 === 0) {
    return false;
  }
  return year % 4 === 0;
}

let toastTimer = null;

function showToast(message) {
  elements.toast.textContent = message;
  elements.toast.classList.remove("hidden");

  if (toastTimer) {
    window.clearTimeout(toastTimer);
  }

  toastTimer = window.setTimeout(() => {
    elements.toast.classList.add("hidden");
  }, 2200);
}
