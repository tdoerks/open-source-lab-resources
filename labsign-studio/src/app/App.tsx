import { useState } from "react";
import { Toolbar } from "./Toolbar";
import { LeftRail } from "./LeftRail";
import { CanvasStage } from "./CanvasStage";
import { Properties } from "./Properties";

export function App() {
  const [uiDark, setUiDark] = useState(false);

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
