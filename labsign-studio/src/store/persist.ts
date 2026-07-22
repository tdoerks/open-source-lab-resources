import { get, set } from "idb-keyval";
import type { Project } from "@/model/types";

const KEY = "labsign.project";

/** Load the last-saved project from IndexedDB (undefined on first run / error). */
export async function loadStoredProject(): Promise<Project | undefined> {
  try {
    return (await get(KEY)) as Project | undefined;
  } catch {
    return undefined;
  }
}

let timer: ReturnType<typeof setTimeout> | undefined;
/** Debounced autosave to IndexedDB. */
export function scheduleSave(project: Project) {
  if (timer) clearTimeout(timer);
  timer = setTimeout(() => {
    set(KEY, project).catch(() => {});
  }, 500);
}
