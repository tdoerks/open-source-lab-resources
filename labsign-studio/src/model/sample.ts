import { nanoid } from "nanoid";
import { PAGE_SIZES, type Project, type Sign } from "./types";

/** A seeded sample sign so the studio isn't empty on first load. */
export function sampleSign(): Sign {
  return {
    id: nanoid(8),
    name: "Refrigerator — Room 218",
    size: PAGE_SIZES[0],
    themeId: "scientific",
    tree: [
      {
        id: nanoid(8),
        type: "titleBlock",
        props: { title: "Refrigerator", subtitle: "Trotter Hall · Room 218", badge: "4°C" },
      },
      { id: nanoid(8), type: "sectionHeader", props: { text: "Shelf Contents" } },
      { id: nanoid(8), type: "shelfRow", props: { label: "Shelf 1 — Top", contents: "Media & buffers", tone: "accent" } },
      { id: nanoid(8), type: "shelfRow", props: { label: "Shelf 2", contents: "Antibodies (labeled boxes)", tone: "ok" } },
      { id: nanoid(8), type: "shelfRow", props: { label: "Shelf 3", contents: "Reagents — in-use", tone: "warn" } },
      { id: nanoid(8), type: "shelfRow", props: { label: "Door", contents: "Personal samples only", tone: "danger" } },
      { id: nanoid(8), type: "note", props: { text: "Label everything with name + date.", variant: "reminder" } },
      { id: nanoid(8), type: "footer", props: { left: "PI: Dr. J. Smith", right: "Updated 2026-07" } },
    ],
  };
}

export function sampleProject(): Project {
  const now = Date.now();
  return {
    id: nanoid(8),
    name: "Untitled project",
    module: "storage-maps",
    brandKit: { org: "", dept: "" },
    signs: [sampleSign()],
    createdAt: now,
    updatedAt: now,
  };
}
