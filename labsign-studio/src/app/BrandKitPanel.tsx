import { RotateCcw } from "lucide-react";
import { useStudio } from "@/store";

export function BrandKitPanel() {
  const brand = useStudio((s) => s.project.brandKit);
  const update = useStudio((s) => s.updateBrandKit);

  return (
    <div>
      <h2 className="mb-2 px-1 text-xs font-bold uppercase tracking-wide text-muted">Brand Kit</h2>
      <p className="mb-3 px-1 text-[11px] text-muted">Set once — applied across every sign.</p>

      <div className="space-y-3">
        <Field label="Organization">
          <input
            value={brand.org}
            onChange={(e) => update({ org: e.target.value })}
            placeholder="Kansas State University"
            className="w-full rounded-md border border-border bg-surface-2 px-2 py-1.5 text-sm outline-none focus:border-primary"
          />
        </Field>
        <Field label="Department / lab">
          <input
            value={brand.dept}
            onChange={(e) => update({ dept: e.target.value })}
            placeholder="College of Veterinary Medicine"
            className="w-full rounded-md border border-border bg-surface-2 px-2 py-1.5 text-sm outline-none focus:border-primary"
          />
        </Field>

        <ColorField
          label="Primary color"
          value={brand.primary}
          fallback="#0f4c81"
          onChange={(v) => update({ primary: v })}
          onClear={() => update({ primary: undefined })}
        />
        <ColorField
          label="Accent color"
          value={brand.accent}
          fallback="#1a9e8f"
          onChange={(v) => update({ accent: v })}
          onClear={() => update({ accent: undefined })}
        />
      </div>

      <p className="mt-4 rounded-lg border border-dashed border-border p-3 text-[11px] text-muted">
        Color overrides apply on top of the chosen theme, so your lab's signs stay consistent regardless
        of theme.
      </p>
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-semibold text-ink">{label}</span>
      {children}
    </label>
  );
}

function ColorField({
  label,
  value,
  fallback,
  onChange,
  onClear,
}: {
  label: string;
  value?: string;
  fallback: string;
  onChange: (v: string) => void;
  onClear: () => void;
}) {
  const set = value != null;
  return (
    <div>
      <span className="mb-1 block text-xs font-semibold text-ink">{label}</span>
      <div className="flex items-center gap-2">
        <input
          type="color"
          value={value ?? fallback}
          onChange={(e) => onChange(e.target.value)}
          className="h-8 w-10 cursor-pointer rounded border border-border bg-surface-2"
        />
        <span className="flex-1 text-xs text-muted">{set ? value : "Theme default"}</span>
        {set && (
          <button onClick={onClear} title="Use theme default" className="text-muted hover:text-ink">
            <RotateCcw size={14} />
          </button>
        )}
      </div>
    </div>
  );
}
