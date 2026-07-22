import { THEMES } from "@/design/themes";
import { resolveTheme } from "@/design/brand";
import { SignSvg } from "@/render/SignSvg";
import { useStudio } from "@/store";

export function CanvasStage() {
  const sign = useStudio((s) => s.project.signs.find((sg) => sg.id === s.activeSignId)!);
  const brand = useStudio((s) => s.project.brandKit);
  const selectedId = useStudio((s) => s.selectedId);
  const select = useStudio((s) => s.select);
  const theme = resolveTheme(THEMES[sign.themeId], brand);

  return (
    <main
      className="canvas-backdrop flex min-w-0 flex-1 items-center justify-center overflow-auto p-8"
      onMouseDown={() => select(null)}
    >
      <SignSvg
        sign={sign}
        theme={theme}
        selectedId={selectedId}
        onSelect={select}
        svgProps={{
          style: {
            height: "min(80vh, 900px)",
            width: "auto",
            maxWidth: "100%",
            background: "#fff",
            boxShadow: "0 10px 40px rgba(16,24,40,.22)",
            borderRadius: 4,
          },
        }}
      />
    </main>
  );
}
