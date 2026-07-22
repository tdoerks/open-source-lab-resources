import { TEMPLATES } from "@/templates";
import { THEMES } from "@/design/themes";
import { useStudio } from "@/store";

export function TemplatesPanel() {
  const apply = useStudio((s) => s.applyTemplate);
  const activeTheme = useStudio((s) => s.project.signs.find((sg) => sg.id === s.activeSignId)!.themeId);

  return (
    <div>
      <h2 className="mb-2 px-1 text-xs font-bold uppercase tracking-wide text-muted">Templates</h2>
      <p className="mb-3 px-1 text-[11px] text-muted">Start from a ready-made sign.</p>
      <div className="space-y-2">
        {TEMPLATES.map((tpl) => {
          const c = THEMES[tpl.themeId].tokens.colors;
          return (
            <button
              key={tpl.id}
              onClick={() => apply(tpl)}
              className="flex w-full items-center gap-3 rounded-lg border border-border p-2.5 text-left hover:border-primary"
            >
              <span
                className="grid h-10 w-10 flex-shrink-0 place-items-center rounded-md text-[10px] font-bold text-white"
                style={{ background: c.primary }}
              >
                {tpl.name.match(/-?\d+ ?°?[CF]?|\d+×\d+/)?.[0] ?? "◻"}
              </span>
              <span>
                <span className="block text-sm font-semibold">{tpl.name}</span>
                <span className="block text-[11px] leading-snug text-muted">
                  {tpl.description} · {THEMES[tpl.themeId].name}
                </span>
              </span>
            </button>
          );
        })}
      </div>
      <p className="mt-3 rounded-lg border border-dashed border-border p-3 text-[11px] text-muted">
        Applying a template replaces the current sign. Current theme: {THEMES[activeTheme].name}.
      </p>
    </div>
  );
}
