import { useState } from "react";
import { Refrigerator, Snowflake, ChevronLeft, type LucideIcon } from "lucide-react";
import { EQUIPMENT, getProfile } from "@/equipment/registry";
import type { EquipmentParam } from "@/equipment/types";
import { useStudio } from "@/store";

const ICONS: Record<string, LucideIcon> = { Refrigerator, Snowflake };

export function EquipmentPanel() {
  const equipment = useStudio((s) => s.project.signs.find((sg) => sg.id === s.activeSignId)!.equipment);
  const setEquipment = useStudio((s) => s.setEquipment);
  const [browsing, setBrowsing] = useState(false);
  const profile = equipment ? getProfile(equipment.profileId) : undefined;

  if (profile && equipment && !browsing) {
    return (
      <div>
        <button
          onClick={() => setBrowsing(true)}
          className="mb-3 flex items-center gap-1 text-xs font-medium text-muted hover:text-ink"
          title="Choose a different unit"
        >
          <ChevronLeft size={14} /> Equipment · {profile.name}
        </button>
        <div className="space-y-3">
          {profile.params.map((p) => (
            <ParamField key={p.key} param={p} value={equipment.values[p.key]} />
          ))}
        </div>
        <p className="mt-4 rounded-lg border border-dashed border-border p-3 text-[11px] text-muted">
          Changing these rebuilds the layout automatically. Click any element on the sign to fill in its
          contents.
        </p>
      </div>
    );
  }

  return (
    <div>
      <h2 className="mb-2 px-1 text-xs font-bold uppercase tracking-wide text-muted">Equipment</h2>
      <p className="mb-3 px-1 text-xs text-muted">Pick a unit — the sign builds itself.</p>
      <div className="space-y-2">
        {EQUIPMENT.map((eq) => {
          const Icon = ICONS[eq.icon] ?? Refrigerator;
          const active = equipment?.profileId === eq.id;
          return (
            <button
              key={eq.id}
              onClick={() => {
                setEquipment(eq.id);
                setBrowsing(false);
              }}
              className={`flex w-full items-start gap-3 rounded-lg border p-3 text-left ${
                active ? "border-primary ring-1 ring-primary" : "border-border hover:border-muted"
              }`}
            >
              <span className="grid h-9 w-9 flex-shrink-0 place-items-center rounded-md bg-surface-2 text-primary">
                <Icon size={19} />
              </span>
              <span>
                <span className="block text-sm font-semibold">{eq.name}</span>
                <span className="block text-[11px] leading-snug text-muted">{eq.description}</span>
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

function ParamField({ param, value }: { param: EquipmentParam; value: string | number | boolean }) {
  const update = useStudio((s) => s.updateEquipmentValue);

  if (param.type === "toggle") {
    return (
      <label className="flex items-center justify-between gap-3">
        <span className="text-xs font-semibold text-ink">{param.label}</span>
        <input
          type="checkbox"
          checked={Boolean(value)}
          onChange={(e) => update(param.key, e.target.checked)}
          className="h-4 w-4 accent-[color:var(--ui-primary)]"
        />
      </label>
    );
  }

  return (
    <label className="block">
      <span className="mb-1 block text-xs font-semibold text-ink">{param.label}</span>
      {param.type === "number" ? (
        <input
          type="number"
          min={param.min}
          max={param.max}
          value={Number(value)}
          onChange={(e) => {
            const n = Math.max(param.min, Math.min(param.max, Number(e.target.value) || 0));
            update(param.key, n);
          }}
          className="w-full rounded-md border border-border bg-surface-2 px-2 py-1.5 text-sm outline-none focus:border-primary"
        />
      ) : param.type === "select" ? (
        <select
          value={String(value)}
          onChange={(e) => update(param.key, e.target.value)}
          className="w-full rounded-md border border-border bg-surface-2 px-2 py-1.5 text-sm outline-none focus:border-primary"
        >
          {param.options.map((o) => (
            <option key={o} value={o}>
              {o}
            </option>
          ))}
        </select>
      ) : (
        <input
          type="text"
          value={String(value)}
          placeholder={param.placeholder}
          onChange={(e) => update(param.key, e.target.value)}
          className="w-full rounded-md border border-border bg-surface-2 px-2 py-1.5 text-sm outline-none focus:border-primary"
        />
      )}
    </label>
  );
}
