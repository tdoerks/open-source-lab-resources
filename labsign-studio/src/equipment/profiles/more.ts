import type { ComponentInstance } from "@/model/types";
import type { EquipmentProfile, EquipmentValues } from "../types";
import { title, header, shelf, note, grid, footer, reminder, TONES } from "../gen";

const num = (v: EquipmentValues, k: string, d: number) => Number(v[k] ?? d);
const str = (v: EquipmentValues, k: string) => String(v[k] ?? "").trim();

export const ultraLow: EquipmentProfile = {
  id: "ultra-low",
  name: "Ultra-Low Freezer",
  category: "freezer",
  icon: "Snowflake",
  description: "-80°C upright: shelves × racks.",
  params: [
    { key: "room", label: "Room / location", type: "text", default: "", placeholder: "Room 214" },
    { key: "temp", label: "Temperature", type: "select", options: ["-80°C", "-70°C", "-86°C"], default: "-80°C" },
    { key: "shelves", label: "Number of shelves", type: "number", min: 1, max: 6, default: 4 },
    { key: "racks", label: "Racks per shelf", type: "number", min: 1, max: 8, default: 4 },
  ],
  generate(v) {
    const shelves = num(v, "shelves", 4);
    const racks = num(v, "racks", 4);
    const tree: ComponentInstance[] = [title("Ultra-Low Freezer", str(v, "room"), str(v, "temp"), "snowflake"), header("Rack Layout")];
    for (let i = 1; i <= shelves; i++) tree.push(shelf(`Shelf ${i}`, `${racks} racks (1–${racks}, left → right)`, TONES[(i - 1) % TONES.length]));
    tree.push(note("Return racks to their labeled positions immediately — door-open time is critical.", "warning"), reminder(), footer());
    return tree;
  },
};

export const chestFreezer: EquipmentProfile = {
  id: "chest-freezer",
  name: "Chest Freezer",
  category: "freezer",
  icon: "Box",
  description: "Top-opening compartments.",
  params: [
    { key: "room", label: "Room / location", type: "text", default: "" },
    { key: "temp", label: "Temperature", type: "select", options: ["-20°C", "-30°C", "-80°C"], default: "-20°C" },
    { key: "compartments", label: "Compartments", type: "number", min: 1, max: 6, default: 3 },
  ],
  generate(v) {
    const n = num(v, "compartments", 3);
    const tree: ComponentInstance[] = [title("Chest Freezer", str(v, "room"), str(v, "temp"), "box"), header("Compartments")];
    for (let i = 1; i <= n; i++) tree.push(shelf(`Compartment ${i}`, "", TONES[(i - 1) % TONES.length]));
    tree.push(reminder(), footer());
    return tree;
  },
};

export const cabinet: EquipmentProfile = {
  id: "cabinet",
  name: "Cabinet",
  category: "cabinet",
  icon: "Archive",
  description: "Shelves and drawers.",
  params: [
    { key: "room", label: "Room / location", type: "text", default: "" },
    { key: "shelves", label: "Number of shelves", type: "number", min: 1, max: 8, default: 4 },
    { key: "drawers", label: "Drawers", type: "number", min: 0, max: 6, default: 2 },
  ],
  generate(v) {
    const shelves = num(v, "shelves", 4);
    const drawers = num(v, "drawers", 2);
    const tree: ComponentInstance[] = [title("Cabinet", str(v, "room"), undefined, "archive"), header("Shelves")];
    for (let i = 1; i <= shelves; i++) tree.push(shelf(`Shelf ${i}`, "", TONES[(i - 1) % TONES.length]));
    if (drawers > 0) {
      tree.push(header("Drawers"));
      for (let i = 1; i <= drawers; i++) tree.push(shelf(`Drawer ${i}`, "", "muted"));
    }
    tree.push(footer());
    return tree;
  },
};

export const incubator: EquipmentProfile = {
  id: "incubator",
  name: "Incubator",
  category: "incubator",
  icon: "Thermometer",
  description: "Warm shelves; CO₂ optional.",
  params: [
    { key: "room", label: "Room / location", type: "text", default: "" },
    { key: "temp", label: "Temperature", type: "select", options: ["37°C", "30°C", "42°C"], default: "37°C" },
    { key: "shelves", label: "Number of shelves", type: "number", min: 1, max: 6, default: 3 },
  ],
  generate(v) {
    const shelves = num(v, "shelves", 3);
    const tree: ComponentInstance[] = [title("Incubator", str(v, "room"), str(v, "temp"), "thermometer"), header("Shelf Contents")];
    for (let i = 1; i <= shelves; i++) tree.push(shelf(`Shelf ${i}`, "", TONES[(i - 1) % TONES.length]));
    tree.push(note("Keep the door closed — maintain temperature and CO₂.", "info"), footer());
    return tree;
  },
};

export const shelfUnit: EquipmentProfile = {
  id: "shelf-unit",
  name: "Shelf Unit",
  category: "shelf",
  icon: "Layers",
  description: "Open shelving / storage rack.",
  params: [
    { key: "room", label: "Room / location", type: "text", default: "" },
    { key: "shelves", label: "Number of shelves", type: "number", min: 1, max: 10, default: 5 },
  ],
  generate(v) {
    const shelves = num(v, "shelves", 5);
    const tree: ComponentInstance[] = [title("Storage Shelf", str(v, "room"), undefined, "layers"), header("Shelf Contents")];
    for (let i = 1; i <= shelves; i++) tree.push(shelf(`Shelf ${i}`, "", TONES[(i - 1) % TONES.length]));
    tree.push(footer());
    return tree;
  },
};

export const cryobox: EquipmentProfile = {
  id: "cryobox",
  name: "Cryobox",
  category: "cryo",
  icon: "Grid3x3",
  description: "A single gridded cryobox map.",
  params: [
    { key: "boxName", label: "Box name / ID", type: "text", default: "Box A1" },
    { key: "rows", label: "Rows", type: "number", min: 1, max: 12, default: 9 },
    { key: "cols", label: "Columns", type: "number", min: 1, max: 12, default: 9 },
    { key: "contents", label: "Contents note", type: "text", default: "" },
  ],
  generate(v) {
    const rows = num(v, "rows", 9);
    const cols = num(v, "cols", 9);
    return [
      title("Cryobox", str(v, "boxName"), `${rows}×${cols}`, "grid"),
      grid("Positions", rows, cols, str(v, "contents") || undefined),
      note("Fill positions row by row (A1, A2 …).", "info"),
      footer(),
    ];
  },
};
