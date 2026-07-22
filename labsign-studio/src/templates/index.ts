import type { ThemeId } from "@/design/themes";
import type { EquipmentValues } from "@/equipment/types";

/** A starting point: an equipment profile pre-filled with values + a theme. */
export interface Template {
  id: string;
  name: string;
  description: string;
  equipmentId: string;
  values: EquipmentValues;
  themeId: ThemeId;
}

export const TEMPLATES: Template[] = [
  {
    id: "fridge-4c",
    name: "4 °C Refrigerator",
    description: "Shelves, door, drawers",
    equipmentId: "refrigerator",
    values: { temp: "4°C", shelves: 4, doorStorage: true, drawers: 2, reminder: true },
    themeId: "scientific",
  },
  {
    id: "ult-80",
    name: "−80 °C ULT Freezer",
    description: "Rack layout",
    equipmentId: "ultra-low",
    values: { temp: "-80°C", shelves: 4, racks: 4 },
    themeId: "scientific",
  },
  {
    id: "cryobox-9",
    name: "Cryobox 9×9",
    description: "Gridded box map",
    equipmentId: "cryobox",
    values: { boxName: "Box A1", rows: 9, cols: 9, contents: "" },
    themeId: "university",
  },
  {
    id: "incubator-37",
    name: "37 °C Incubator",
    description: "Warm shelves",
    equipmentId: "incubator",
    values: { temp: "37°C", shelves: 3 },
    themeId: "scientific",
  },
  {
    id: "cabinet",
    name: "Supply Cabinet",
    description: "Shelves + drawers",
    equipmentId: "cabinet",
    values: { shelves: 4, drawers: 2 },
    themeId: "minimal",
  },
  {
    id: "chest-osha",
    name: "Chest Freezer",
    description: "High-vis / OSHA",
    equipmentId: "chest-freezer",
    values: { temp: "-20°C", compartments: 3 },
    themeId: "osha",
  },
];
