import { Trash2, Ban } from "lucide-react";
import { useStudio } from "@/store";
import type { ComponentInstance, GridInstance } from "@/model/types";
import { ICON_SET } from "@/icons/registry";

const ICON_TYPES = new Set<ComponentInstance["type"]>(["titleBlock", "sectionHeader", "shelfRow", "card"]);

const TYPE_LABEL: Record<ComponentInstance["type"], string> = {
  titleBlock: "Title Block",
  sectionHeader: "Section Header",
  shelfRow: "Shelf Row",
  card: "Card",
  note: "Note",
  grid: "Grid",
  footer: "Footer",
};

export function Properties() {
  const sign = useStudio((s) => s.project.signs.find((sg) => sg.id === s.activeSignId)!);
  const selectedId = useStudio((s) => s.selectedId);
  const updateProps = useStudio((s) => s.updateProps);
  const removeComponent = useStudio((s) => s.removeComponent);

  const inst = sign.tree.find((c) => c.id === selectedId) ?? null;

  return (
    <aside className="w-72 flex-shrink-0 overflow-y-auto border-l border-border bg-surface p-4">
      {!inst ? (
        <div>
          <h2 className="text-xs font-bold uppercase tracking-wide text-muted">Sign</h2>
          <dl className="mt-3 space-y-2 text-sm">
            <Row k="Name" v={sign.name} />
            <Row k="Size" v={sign.size.label} />
            <Row k="Theme" v={sign.themeId} />
            <Row k="Components" v={String(sign.tree.length)} />
          </dl>
          <p className="mt-6 rounded-lg border border-dashed border-border p-3 text-xs text-muted">
            Click any element on the canvas to edit it.
          </p>
        </div>
      ) : (
        <div>
          <div className="mb-3 flex items-center justify-between">
            <h2 className="text-xs font-bold uppercase tracking-wide text-muted">{TYPE_LABEL[inst.type]}</h2>
            <button
              onClick={() => removeComponent(inst.id)}
              className="grid h-8 w-8 place-items-center rounded-md text-muted hover:bg-surface-2 hover:text-[color:var(--ui-ink)]"
              title="Delete component"
            >
              <Trash2 size={15} />
            </button>
          </div>

          {ICON_TYPES.has(inst.type) && <IconField instId={inst.id} current={(inst.props as { icon?: { name?: string } }).icon?.name} />}

          <div className="mt-3 space-y-3">
            {Object.entries(inst.props).map(([key, value]) => {
              if (key === "icon") return null;
              if (typeof value === "number") {
                return (
                  <label key={key} className="block">
                    <span className="mb-1 block text-xs font-semibold capitalize text-muted">{key}</span>
                    <input
                      type="number"
                      value={value}
                      onChange={(e) => updateProps(inst.id, { [key]: Number(e.target.value) || 0 })}
                      className="w-full rounded-md border border-border bg-surface-2 px-2 py-1.5 text-sm outline-none focus:border-primary"
                    />
                  </label>
                );
              }
              if (typeof value !== "string") return null;
              const isEnum = key === "variant" || key === "tone";
              return (
                <label key={key} className="block">
                  <span className="mb-1 block text-xs font-semibold capitalize text-muted">{key}</span>
                  {isEnum ? (
                    <select
                      value={value}
                      onChange={(e) => updateProps(inst.id, { [key]: e.target.value })}
                      className="w-full rounded-md border border-border bg-surface-2 px-2 py-1.5 text-sm outline-none focus:border-primary"
                    >
                      {(key === "variant"
                        ? ["info", "reminder", "warning"]
                        : ["accent", "ok", "warn", "danger", "primary", "muted"]
                      ).map((o) => (
                        <option key={o} value={o}>
                          {o}
                        </option>
                      ))}
                    </select>
                  ) : (
                    <input
                      value={value}
                      onChange={(e) => updateProps(inst.id, { [key]: e.target.value })}
                      className="w-full rounded-md border border-border bg-surface-2 px-2 py-1.5 text-sm outline-none focus:border-primary"
                    />
                  )}
                </label>
              );
            })}
          </div>

          {inst.type === "grid" && <GridCellsEditor inst={inst} />}
        </div>
      )}
    </aside>
  );
}

function GridCellsEditor({ inst }: { inst: GridInstance }) {
  const updateProps = useStudio((s) => s.updateProps);
  const rows = Math.max(1, Math.min(12, inst.props.rows));
  const cols = Math.max(1, Math.min(12, inst.props.cols));
  const cells = inst.props.cells ?? {};
  const rowLabel = (r: number) => (r < 26 ? String.fromCharCode(65 + r) : String(r + 1));

  const setCell = (r: number, c: number, v: string) => {
    const next = { ...cells };
    if (v) next[`${r}-${c}`] = v;
    else delete next[`${r}-${c}`];
    updateProps(inst.id, { cells: next });
  };

  return (
    <div className="mt-4">
      <span className="mb-1 block text-xs font-semibold text-muted">Positions — type contents</span>
      <div className="overflow-x-auto rounded-md border border-border p-2">
        <table style={{ borderSpacing: 2, borderCollapse: "separate" }}>
          <thead>
            <tr>
              <th />
              {Array.from({ length: cols }).map((_, c) => (
                <th key={c} className="text-[9px] font-bold text-muted">{c + 1}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {Array.from({ length: rows }).map((_, r) => (
              <tr key={r}>
                <td className="pr-1 text-[9px] font-bold text-muted">{rowLabel(r)}</td>
                {Array.from({ length: cols }).map((_, c) => (
                  <td key={c}>
                    <input
                      value={cells[`${r}-${c}`] ?? ""}
                      onChange={(e) => setCell(r, c, e.target.value)}
                      className="h-5 w-6 rounded border border-border bg-surface-2 text-center text-[9px] outline-none focus:border-primary"
                    />
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function Row({ k, v }: { k: string; v: string }) {
  return (
    <div className="flex justify-between gap-3">
      <dt className="text-muted">{k}</dt>
      <dd className="truncate font-medium">{v}</dd>
    </div>
  );
}

function IconField({ instId, current }: { instId: string; current?: string }) {
  const updateProps = useStudio((s) => s.updateProps);
  return (
    <div>
      <span className="mb-1 block text-xs font-semibold text-muted">Icon</span>
      <div className="flex flex-wrap gap-1">
        <button
          onClick={() => updateProps(instId, { icon: undefined })}
          title="No icon"
          className={`grid h-8 w-8 place-items-center rounded-md border ${
            !current ? "border-primary text-primary" : "border-border text-muted hover:border-muted"
          }`}
        >
          <Ban size={15} />
        </button>
        {ICON_SET.map((ic) => {
          const Comp = ic.Comp;
          const active = current === ic.name;
          return (
            <button
              key={ic.name}
              title={ic.label}
              onClick={() => updateProps(instId, { icon: { source: "lab", name: ic.name } })}
              className={`grid h-8 w-8 place-items-center rounded-md border ${
                active ? "border-primary text-primary" : "border-border text-ink hover:border-muted"
              }`}
            >
              <Comp size={16} />
            </button>
          );
        })}
      </div>
    </div>
  );
}
