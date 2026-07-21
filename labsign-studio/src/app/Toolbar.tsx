import { FlaskConical, Moon, Sun, Download } from "lucide-react";
import { useStudio } from "@/store";

export function Toolbar({ uiDark, onToggleUiDark }: { uiDark: boolean; onToggleUiDark: () => void }) {
  const sign = useStudio((s) => s.project.signs.find((sg) => sg.id === s.activeSignId)!);
  const renameSign = useStudio((s) => s.renameSign);

  return (
    <header className="flex h-14 flex-shrink-0 items-center gap-3 border-b border-border bg-surface px-4">
      <div className="flex items-center gap-2">
        <div className="grid h-8 w-8 place-items-center rounded-md bg-primary text-primary-ink">
          <FlaskConical size={18} />
        </div>
        <div className="leading-tight">
          <div className="text-sm font-bold tracking-tight">LabSign Studio</div>
          <div className="text-[11px] text-muted">Storage Maps</div>
        </div>
      </div>

      <div className="mx-2 h-6 w-px bg-border" />

      <input
        value={sign.name}
        onChange={(e) => renameSign(e.target.value)}
        className="min-w-0 flex-1 rounded-md bg-transparent px-2 py-1 text-sm font-medium text-ink outline-none hover:bg-surface-2 focus:bg-surface-2"
        aria-label="Sign name"
      />

      <button
        onClick={onToggleUiDark}
        className="grid h-9 w-9 place-items-center rounded-md text-muted hover:bg-surface-2 hover:text-ink"
        title="Toggle app theme"
      >
        {uiDark ? <Sun size={17} /> : <Moon size={17} />}
      </button>

      <button className="flex h-9 items-center gap-2 rounded-md bg-primary px-3 text-sm font-semibold text-primary-ink hover:brightness-110">
        <Download size={16} /> Export
      </button>
    </header>
  );
}
