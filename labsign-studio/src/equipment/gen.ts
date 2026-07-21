import { nanoid } from "nanoid";
import type { ComponentInstance } from "@/model/types";
import type { ThemeColorRef } from "@/design/tokens";

/** Small builders that keep equipment generators concise and consistent. */
export const id = () => nanoid(8);
export const TONES: ThemeColorRef[] = ["accent", "ok", "warn", "primary"];

export function title(text: string, sub?: string, badge?: string, icon?: string): ComponentInstance {
  return {
    id: id(),
    type: "titleBlock",
    props: {
      title: text,
      subtitle: sub && sub.trim() ? sub.trim() : undefined,
      badge: badge && badge.trim() ? badge.trim() : undefined,
      icon: icon ? { source: "lab", name: icon } : undefined,
    },
  };
}
export function header(text: string): ComponentInstance {
  return { id: id(), type: "sectionHeader", props: { text } };
}
export function shelf(label: string, contents = "", tone: ThemeColorRef = "accent"): ComponentInstance {
  return { id: id(), type: "shelfRow", props: { label, contents, tone } };
}
export function note(
  text: string,
  variant: "info" | "reminder" | "warning" = "reminder",
): ComponentInstance {
  return { id: id(), type: "note", props: { text, variant } };
}
export function grid(label: string, rows: number, cols: number, note?: string): ComponentInstance {
  return { id: id(), type: "grid", props: { label, rows, cols, note } };
}
export function footer(): ComponentInstance {
  return { id: id(), type: "footer", props: { left: "", right: "" } };
}
export function reminder(): ComponentInstance {
  return note("Label everything with name + date.", "reminder");
}
