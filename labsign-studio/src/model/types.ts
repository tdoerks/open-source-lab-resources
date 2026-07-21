import type { ThemeId } from "@/design/themes";
import type { ThemeColorRef } from "@/design/tokens";

/** A physical page/sign size. Units are inches or millimeters; the renderer
 *  works in SVG user units where 1 unit = 1 point (72/in). */
export interface PageSize {
  id: string;
  label: string;
  wIn: number;
  hIn: number;
  bleedIn?: number;
}

export const PAGE_SIZES: PageSize[] = [
  { id: "letter-p", label: "Letter (portrait)", wIn: 8.5, hIn: 11 },
  { id: "letter-l", label: "Letter (landscape)", wIn: 11, hIn: 8.5 },
  { id: "a4-p", label: "A4 (portrait)", wIn: 8.27, hIn: 11.69 },
  { id: "tabloid", label: "11 × 17", wIn: 11, hIn: 17 },
  { id: "quarter", label: "Quarter sheet", wIn: 4.25, hIn: 5.5 },
];

/** Reference to an icon: a Lucide name, a curated lab icon, or a user SVG. */
export interface IconRef {
  source: "lucide" | "lab" | "user";
  name?: string;
  dataUri?: string;
}

/** Style overrides are theme-referential (a color *slot*, not raw hex) so the
 *  design language can never be broken by user edits. */
export interface StyleOverride {
  color?: ThemeColorRef;
  icon?: IconRef;
}

/** Layout hints for the flow engine (no raw x/y unless a future 'free' mode). */
export interface LayoutHint {
  order?: number;
  span?: number; // grid span for row/grid children
}

interface BaseInstance {
  id: string;
  locked?: boolean;
  layout?: LayoutHint;
  style?: StyleOverride;
}

/* ---- Component instances (discriminated union by `type`) ------------------ */

export interface TitleBlockInstance extends BaseInstance {
  type: "titleBlock";
  props: { title: string; subtitle?: string; icon?: IconRef; badge?: string };
}
export interface SectionHeaderInstance extends BaseInstance {
  type: "sectionHeader";
  props: { text: string; icon?: IconRef };
}
export interface ShelfRowInstance extends BaseInstance {
  type: "shelfRow";
  props: { label: string; contents: string; icon?: IconRef; tone?: ThemeColorRef };
}
export interface CardInstance extends BaseInstance {
  type: "card";
  props: { title: string; body?: string; icon?: IconRef };
}
export interface NoteInstance extends BaseInstance {
  type: "note";
  props: { text: string; variant: "info" | "reminder" | "warning" };
}
export interface FooterInstance extends BaseInstance {
  type: "footer";
  props: { left?: string; right?: string };
}

export type ComponentInstance =
  | TitleBlockInstance
  | SectionHeaderInstance
  | ShelfRowInstance
  | CardInstance
  | NoteInstance
  | FooterInstance;

export type ComponentType = ComponentInstance["type"];

/* ---- Document ------------------------------------------------------------- */

export interface EquipmentBinding {
  profileId: string;
  values: Record<string, unknown>;
}

export interface Sign {
  id: string;
  name: string;
  size: PageSize;
  themeId: ThemeId;
  equipment?: EquipmentBinding;
  /** Ordered component tree (generated from equipment and/or user-added). */
  tree: ComponentInstance[];
}

export type ModuleId = "storage-maps";

export interface Project {
  id: string;
  name: string;
  module: ModuleId;
  signs: Sign[];
  createdAt: number;
  updatedAt: number;
}
