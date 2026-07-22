import { useEffect, useState } from "react";
import { Toolbar } from "./Toolbar";
import { LeftRail } from "./LeftRail";
import { CanvasStage } from "./CanvasStage";
import { Properties } from "./Properties";
import { useStudio } from "@/store";
import { loadStoredProject, scheduleSave } from "@/store/persist";

export function App() {
  const [uiDark, setUiDark] = useState(false);

  // Hydrate from IndexedDB, autosave on change, and wire undo/redo shortcuts.
  useEffect(() => {
    let active = true;
    loadStoredProject().then((p) => {
      if (active && p && p.signs?.length) {
        useStudio.getState().loadProject(p);
        useStudio.temporal.getState().clear(); // don't count hydration as an undo step
      }
    });
    const unsub = useStudio.subscribe((s) => scheduleSave(s.project));

    const onKey = (e: KeyboardEvent) => {
      const mod = e.ctrlKey || e.metaKey;
      if (!mod || (e.target instanceof HTMLElement && /INPUT|TEXTAREA|SELECT/.test(e.target.tagName))) return;
      if (e.key.toLowerCase() === "z") {
        e.preventDefault();
        if (e.shiftKey) useStudio.temporal.getState().redo();
        else useStudio.temporal.getState().undo();
      } else if (e.key.toLowerCase() === "y") {
        e.preventDefault();
        useStudio.temporal.getState().redo();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => {
      active = false;
      unsub();
      window.removeEventListener("keydown", onKey);
    };
  }, []);

  return (
    <div data-ui-theme={uiDark ? "dark" : "light"} className="flex h-full flex-col bg-bg text-ink">
      <Toolbar uiDark={uiDark} onToggleUiDark={() => setUiDark((v) => !v)} />
      <div className="flex min-h-0 flex-1">
        <LeftRail />
        <CanvasStage />
        <Properties />
      </div>
    </div>
  );
}
