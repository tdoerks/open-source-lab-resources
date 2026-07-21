import { Type, Heading, Rows3, Square, StickyNote, Grid3x3, PanelBottom, type LucideIcon } from "lucide-react";
import type { ComponentType } from "@/model/types";
import { useStudio } from "@/store";

const ADD: { type: ComponentType; label: string; icon: LucideIcon }[] = [
  { type: "titleBlock", label: "Title Block", icon: Type },
  { type: "sectionHeader", label: "Section", icon: Heading },
  { type: "shelfRow", label: "Shelf Row", icon: Rows3 },
  { type: "card", label: "Card", icon: Square },
  { type: "note", label: "Note", icon: StickyNote },
  { type: "grid", label: "Grid", icon: Grid3x3 },
  { type: "footer", label: "Footer", icon: PanelBottom },
];

export function ComponentsPanel() {
  const add = useStudio((s) => s.addComponent);
  return (
    <div>
      <h2 className="mb-2 px-1 text-xs font-bold uppercase tracking-wide text-muted">Add component</h2>
      <div className="grid grid-cols-2 gap-2">
        {ADD.map((a) => {
          const Icon = a.icon;
          return (
            <button
              key={a.type}
              onClick={() => add(a.type)}
              className="flex flex-col items-center gap-1.5 rounded-lg border border-border p-3 text-xs font-medium text-ink hover:border-primary hover:text-primary"
            >
              <Icon size={18} />
              {a.label}
            </button>
          );
        })}
      </div>
      <p className="mt-3 rounded-lg border border-dashed border-border p-3 text-[11px] text-muted">
        Components are added to the bottom of the sign. Click one on the canvas to edit or delete it.
      </p>
    </div>
  );
}
