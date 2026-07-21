import type { ComponentInstance } from "@/model/types";

export type EquipmentCategory =
  | "freezer"
  | "fridge"
  | "cabinet"
  | "incubator"
  | "cryo"
  | "shelf"
  | "custom";

/** A single guided-question parameter that drives layout generation. */
export type EquipmentParam =
  | { key: string; label: string; type: "number"; min: number; max: number; default: number; help?: string }
  | { key: string; label: string; type: "toggle"; default: boolean; help?: string }
  | { key: string; label: string; type: "text"; default: string; placeholder?: string; help?: string }
  | { key: string; label: string; type: "select"; options: string[]; default: string; help?: string };

export type EquipmentValues = Record<string, string | number | boolean>;

/** An equipment profile: physical structure + a generator that emits a themed
 *  component tree from the answered parameters. Adding equipment = one profile. */
export interface EquipmentProfile {
  id: string;
  name: string;
  category: EquipmentCategory;
  /** Lucide icon name for the picker. */
  icon: string;
  description: string;
  params: EquipmentParam[];
  generate: (values: EquipmentValues) => ComponentInstance[];
}

/** Resolve the default value map for a profile's params. */
export function defaultValues(profile: EquipmentProfile): EquipmentValues {
  const v: EquipmentValues = {};
  for (const p of profile.params) v[p.key] = p.default;
  return v;
}
