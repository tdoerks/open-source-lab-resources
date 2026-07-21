import { nanoid } from "nanoid";
import type { ComponentInstance } from "@/model/types";
import type { ThemeColorRef } from "@/design/tokens";
import type { EquipmentProfile, EquipmentValues } from "../types";

const TONES: ThemeColorRef[] = ["accent", "ok", "warn", "primary"];

export const refrigerator: EquipmentProfile = {
  id: "refrigerator",
  name: "Refrigerator",
  category: "fridge",
  icon: "Refrigerator",
  description: "Shelves, door storage, and bottom drawers.",
  params: [
    { key: "room", label: "Room / location", type: "text", default: "", placeholder: "Trotter Hall · Room 218" },
    { key: "temp", label: "Temperature badge", type: "text", default: "4°C" },
    { key: "shelves", label: "Number of shelves", type: "number", min: 1, max: 8, default: 4 },
    { key: "doorStorage", label: "Door storage", type: "toggle", default: true },
    { key: "drawers", label: "Bottom drawers", type: "number", min: 0, max: 3, default: 2 },
    { key: "reminder", label: "Show labeling reminder", type: "toggle", default: true },
  ],
  generate(v: EquipmentValues): ComponentInstance[] {
    const room = String(v.room ?? "").trim();
    const temp = String(v.temp ?? "").trim();
    const shelves = Number(v.shelves ?? 4);
    const drawers = Number(v.drawers ?? 0);
    const tree: ComponentInstance[] = [];

    tree.push({
      id: nanoid(8),
      type: "titleBlock",
      props: { title: "Refrigerator", subtitle: room || undefined, badge: temp || undefined },
    });
    tree.push({ id: nanoid(8), type: "sectionHeader", props: { text: "Shelf Contents" } });

    for (let i = 1; i <= shelves; i++) {
      tree.push({
        id: nanoid(8),
        type: "shelfRow",
        props: {
          label: i === 1 ? "Shelf 1 — Top" : `Shelf ${i}`,
          contents: "",
          tone: TONES[(i - 1) % TONES.length],
        },
      });
    }
    if (v.doorStorage) {
      tree.push({ id: nanoid(8), type: "shelfRow", props: { label: "Door", contents: "", tone: "danger" } });
    }
    if (drawers > 0) {
      tree.push({ id: nanoid(8), type: "sectionHeader", props: { text: "Drawers" } });
      for (let i = 1; i <= drawers; i++) {
        tree.push({ id: nanoid(8), type: "shelfRow", props: { label: `Drawer ${i}`, contents: "", tone: "muted" } });
      }
    }
    if (v.reminder) {
      tree.push({ id: nanoid(8), type: "note", props: { text: "Label everything with name + date.", variant: "reminder" } });
    }
    tree.push({ id: nanoid(8), type: "footer", props: { left: "", right: "" } });
    return tree;
  },
};
