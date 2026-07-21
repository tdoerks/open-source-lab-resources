import type { EquipmentProfile } from "./types";
import { refrigerator } from "./profiles/refrigerator";
import { uprightFreezer } from "./profiles/upright-freezer";

/** All equipment profiles available in the picker. Add a profile file + register
 *  it here — the renderer adapts automatically. */
export const EQUIPMENT: EquipmentProfile[] = [refrigerator, uprightFreezer];

export function getProfile(id: string): EquipmentProfile | undefined {
  return EQUIPMENT.find((p) => p.id === id);
}
