import { nanoid } from "nanoid";
import type { ComponentInstance } from "@/model/types";
import type { ThemeColorRef } from "@/design/tokens";
import type { EquipmentProfile, EquipmentValues } from "../types";

const TONES: ThemeColorRef[] = ["primary", "accent", "ok", "warn"];

export const uprightFreezer: EquipmentProfile = {
  id: "upright-freezer",
  name: "Upright Freezer",
  category: "freezer",
  icon: "Snowflake",
  description: "Vertical shelves; optional rack note.",
  params: [
    { key: "room", label: "Room / location", type: "text", default: "", placeholder: "Room 214" },
    { key: "temp", label: "Temperature badge", type: "select", options: ["-20°C", "-30°C", "-80°C", "-150°C"], default: "-20°C" },
    { key: "shelves", label: "Number of shelves", type: "number", min: 1, max: 6, default: 5 },
    { key: "racksPerShelf", label: "Racks per shelf", type: "number", min: 0, max: 6, default: 0 },
    { key: "reminder", label: "Show labeling reminder", type: "toggle", default: true },
  ],
  generate(v: EquipmentValues): ComponentInstance[] {
    const room = String(v.room ?? "").trim();
    const temp = String(v.temp ?? "").trim();
    const shelves = Number(v.shelves ?? 5);
    const racks = Number(v.racksPerShelf ?? 0);
    const tree: ComponentInstance[] = [];

    tree.push({
      id: nanoid(8),
      type: "titleBlock",
      props: {
        title: "Freezer",
        subtitle: room || undefined,
        badge: temp || undefined,
        icon: { source: "lab", name: "snowflake" },
      },
    });
    tree.push({ id: nanoid(8), type: "sectionHeader", props: { text: "Shelf Contents" } });

    for (let i = 1; i <= shelves; i++) {
      tree.push({
        id: nanoid(8),
        type: "shelfRow",
        props: {
          label: `Shelf ${i}`,
          contents: racks > 0 ? `${racks} rack${racks > 1 ? "s" : ""}` : "",
          tone: TONES[(i - 1) % TONES.length],
        },
      });
    }
    if (racks > 0) {
      tree.push({
        id: nanoid(8),
        type: "note",
        props: { text: `Each shelf holds ${racks} racks — label racks left to right.`, variant: "info" },
      });
    }
    if (v.reminder) {
      tree.push({ id: nanoid(8), type: "note", props: { text: "Label everything with name + date.", variant: "reminder" } });
    }
    tree.push({ id: nanoid(8), type: "footer", props: { left: "", right: "" } });
    return tree;
  },
};
