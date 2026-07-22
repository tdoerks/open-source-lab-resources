import { useState } from "react";
import { FlaskConical, Moon, Sun, Download, FileImage, FileCode, FileText, Check, Undo2, Redo2 } from "lucide-react";
import { useStudio, useTemporal } from "@/store";
import { THEMES } from "@/design/themes";
import { resolveTheme } from "@/design/brand";
import { exportPng, exportSvg, exportPdf } from "@/export";

export function Toolbar({ uiDark, onToggleUiDark }: { uiDark: boolean; onToggleUiDark: () => void }) {
  const sign = useStudio((s) => s.project.signs.find((sg) => sg.id === s.activeSignId)!);
  const brand = useStudio((s) => s.project.brandKit);
  const renameSign = useStudio((s) => s.renameSign);
  const [menuOpen, setMenuOpen] = useState(false);
  const [busy, setBusy] = useState<string | null>(null);
  const [done, setDone] = useState<string | null>(null);

  async function run(fmt: "png" | "svg" | "pdf") {
    setBusy(fmt);
    const theme = resolveTheme(THEMES[sign.themeId], brand);
    try {
      if (fmt === "png") await exportPng(sign, theme, 300);
      else if (fmt === "svg") exportSvg(sign, theme);
      else await exportPdf(sign, theme, 300);
      setDone(fmt);
      setTimeout(() => setDone(null), 1500);
    } finally {
      setBusy(null);
      setMenuOpen(false);
    }
  }

  return (
    <header className="relative z-20 flex h-14 flex-shrink-0 items-center gap-3 border-b border-border bg-surface px-4">
      <div className="flex items-center gap-2">
        <div className="grid h-8 w-8 place-items-center rounded-md bg-primary text-primary-ink">
          <FlaskConical size={18} />
        </div>
        <div className="leading-tight">
          <div className="text-sm font-bold tracking-tight">LabSign Studio</div>
          <div className="text-[11px] text-muted">Storage Maps</div>
        </div>
      </div>

      <div className="mx-1 flex items-center">
        <UndoRedo />
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

      <div className="relative">
        <button
          onClick={() => setMenuOpen((v) => !v)}
          className="flex h-9 items-center gap-2 rounded-md bg-primary px-3 text-sm font-semibold text-primary-ink hover:brightness-110"
        >
          <Download size={16} /> Export
        </button>
        {menuOpen && (
          <>
            <div className="fixed inset-0 z-10" onClick={() => setMenuOpen(false)} />
            <div className="absolute right-0 z-20 mt-1 w-52 overflow-hidden rounded-lg border border-border bg-surface shadow-raised">
              <MenuItem icon={<FileImage size={16} />} label="PNG (300 DPI)" busy={busy === "png"} done={done === "png"} onClick={() => run("png")} />
              <MenuItem icon={<FileCode size={16} />} label="SVG (vector)" busy={busy === "svg"} done={done === "svg"} onClick={() => run("svg")} />
              <MenuItem icon={<FileText size={16} />} label="PDF (print)" busy={busy === "pdf"} done={done === "pdf"} onClick={() => run("pdf")} />
              <div className="border-t border-border px-3 py-2 text-[11px] text-muted">{sign.size.label}</div>
            </div>
          </>
        )}
      </div>
    </header>
  );
}

function UndoRedo() {
  const undo = useTemporal((s) => s.undo);
  const redo = useTemporal((s) => s.redo);
  const canUndo = useTemporal((s) => s.pastStates.length > 0);
  const canRedo = useTemporal((s) => s.futureStates.length > 0);
  return (
    <>
      <button
        onClick={() => undo()}
        disabled={!canUndo}
        title="Undo (Ctrl+Z)"
        className="grid h-9 w-9 place-items-center rounded-md text-muted hover:bg-surface-2 hover:text-ink disabled:opacity-40 disabled:hover:bg-transparent"
      >
        <Undo2 size={17} />
      </button>
      <button
        onClick={() => redo()}
        disabled={!canRedo}
        title="Redo (Ctrl+Shift+Z)"
        className="grid h-9 w-9 place-items-center rounded-md text-muted hover:bg-surface-2 hover:text-ink disabled:opacity-40 disabled:hover:bg-transparent"
      >
        <Redo2 size={17} />
      </button>
    </>
  );
}

function MenuItem({
  icon,
  label,
  busy,
  done,
  onClick,
}: {
  icon: React.ReactNode;
  label: string;
  busy: boolean;
  done: boolean;
  onClick: () => void;
}) {
  return (
    <button
      onClick={onClick}
      disabled={busy}
      className="flex w-full items-center gap-3 px-3 py-2.5 text-left text-sm text-ink hover:bg-surface-2 disabled:opacity-60"
    >
      <span className="text-muted">{icon}</span>
      <span className="flex-1">{label}</span>
      {busy ? <span className="text-xs text-muted">…</span> : done ? <Check size={15} className="text-primary" /> : null}
    </button>
  );
}
