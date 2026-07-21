import { Trash2 } from "lucide-react";
import { useStudio } from "@/store";
import type { ComponentInstance } from "@/model/types";

const TYPE_LABEL: Record<ComponentInstance["type"], string> = {
  titleBlock: "Title Block",
  sectionHeader: "Section Header",
  shelfRow: "Shelf Row",
  card: "Card",
  note: "Note",
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

          <div className="space-y-3">
            {Object.entries(inst.props).map(([key, value]) => {
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
        </div>
      )}
    </aside>
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
