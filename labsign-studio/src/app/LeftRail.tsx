import { useState } from "react";
import {
  LayoutTemplate,
  Boxes,
  Refrigerator,
  Shapes,
  Palette,
  Sparkles,
  type LucideIcon,
} from "lucide-react";
import { cn } from "@/lib/cn";
import { THEME_LIST } from "@/design/themes";
import { useStudio } from "@/store";
import { EquipmentPanel } from "./EquipmentPanel";
import { ComponentsPanel } from "./ComponentsPanel";
import { TemplatesPanel } from "./TemplatesPanel";
import { BrandKitPanel } from "./BrandKitPanel";

type TabId = "templates" | "components" | "equipment" | "icons" | "themes" | "brand";

const TABS: { id: TabId; label: string; icon: LucideIcon }[] = [
  { id: "templates", label: "Templates", icon: LayoutTemplate },
  { id: "components", label: "Components", icon: Shapes },
  { id: "equipment", label: "Equipment", icon: Refrigerator },
  { id: "icons", label: "Icons", icon: Boxes },
  { id: "themes", label: "Themes", icon: Palette },
  { id: "brand", label: "Brand Kit", icon: Sparkles },
];

export function LeftRail() {
  const [tab, setTab] = useState<TabId>("equipment");

  return (
    <div className="flex flex-shrink-0">
      {/* icon column */}
      <nav className="flex w-16 flex-col items-center gap-1 border-r border-border bg-surface py-3">
        {TABS.map((t) => {
          const Icon = t.icon;
          const active = tab === t.id;
          return (
            <button
              key={t.id}
              onClick={() => setTab(t.id)}
              className={cn(
                "flex w-14 flex-col items-center gap-1 rounded-md py-2 text-[10px] font-medium",
                active ? "bg-surface-2 text-primary" : "text-muted hover:bg-surface-2 hover:text-ink",
              )}
            >
              <Icon size={19} />
              {t.label}
            </button>
          );
        })}
      </nav>

      {/* panel */}
      <aside className="w-64 overflow-y-auto border-r border-border bg-surface p-3">
        {tab === "themes" ? (
          <ThemesPanel />
        ) : tab === "equipment" ? (
          <EquipmentPanel />
        ) : tab === "components" ? (
          <ComponentsPanel />
        ) : tab === "templates" ? (
          <TemplatesPanel />
        ) : tab === "brand" ? (
          <BrandKitPanel />
        ) : (
          <Placeholder label={TABS.find((t) => t.id === tab)!.label} />
        )}
      </aside>
    </div>
  );
}

function ThemesPanel() {
  const themeId = useStudio((s) => s.project.signs.find((sg) => sg.id === s.activeSignId)!.themeId);
  const setTheme = useStudio((s) => s.setTheme);

  return (
    <div>
      <h2 className="mb-2 px-1 text-xs font-bold uppercase tracking-wide text-muted">Themes</h2>
      <div className="space-y-2">
        {THEME_LIST.map((th) => {
          const c = th.tokens.colors;
          const active = th.id === themeId;
          return (
            <button
              key={th.id}
              onClick={() => setTheme(th.id)}
              className={cn(
                "flex w-full items-center gap-3 rounded-lg border p-2 text-left",
                active ? "border-primary ring-1 ring-primary" : "border-border hover:border-muted",
              )}
            >
              <span className="flex h-9 w-9 flex-shrink-0 overflow-hidden rounded-md border border-border">
                <span className="w-1/3" style={{ background: c.primary }} />
                <span className="w-1/3" style={{ background: c.accent }} />
                <span className="w-1/3" style={{ background: c.surface }} />
              </span>
              <span className="text-sm font-medium">{th.name}</span>
            </button>
          );
        })}
      </div>
    </div>
  );
}

function Placeholder({ label }: { label: string }) {
  return (
    <div className="px-1">
      <h2 className="mb-2 text-xs font-bold uppercase tracking-wide text-muted">{label}</h2>
      <p className="rounded-lg border border-dashed border-border p-4 text-xs text-muted">
        {label} coming in a later phase.
      </p>
    </div>
  );
}
