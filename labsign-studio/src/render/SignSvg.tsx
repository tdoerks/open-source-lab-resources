import type { SVGProps } from "react";
import { SPACE } from "@/design/tokens";
import type { Theme } from "@/design/themes";
import type { Sign } from "@/model/types";
import { renderComponent } from "./renderers";

const PT_PER_IN = 72;

interface Props {
  sign: Sign;
  theme: Theme;
  selectedId?: string | null;
  onSelect?: (id: string | null) => void;
  /** Extra attrs for the root <svg> (e.g. id/ref for export). */
  svgProps?: SVGProps<SVGSVGElement>;
  /** Hide selection chrome (for export). */
  interactive?: boolean;
}

/**
 * The rendering engine's output: a sign laid out as SVG. Components stack
 * vertically on the spacing grid inside a themed page — users never position
 * anything manually.
 */
export function SignSvg({ sign, theme, selectedId, onSelect, svgProps, interactive = true }: Props) {
  const t = theme.tokens;
  const W = sign.size.wIn * PT_PER_IN;
  const H = sign.size.hIn * PT_PER_IN;
  const margin = SPACE.xl;
  const contentW = W - margin * 2;

  // Flow layout: place each component top-to-bottom with a consistent gap.
  let y = margin;
  const placed = sign.tree.map((inst) => {
    const r = renderComponent(inst, { t, w: contentW });
    const top = y;
    y += r.height + SPACE.md;
    return { inst, r, top };
  });

  return (
    <svg
      viewBox={`0 0 ${W} ${H}`}
      xmlns="http://www.w3.org/2000/svg"
      width={W}
      height={H}
      {...svgProps}
    >
      <rect x={0} y={0} width={W} height={H} fill={t.colors.bg} />
      {placed.map(({ inst, r, top }) => {
        const selected = interactive && selectedId === inst.id;
        return (
          <g
            key={inst.id}
            data-id={inst.id}
            transform={`translate(${margin},${top})`}
            style={interactive ? { cursor: "pointer" } : undefined}
            onMouseDown={
              interactive
                ? (e) => {
                    e.stopPropagation();
                    onSelect?.(inst.id);
                  }
                : undefined
            }
          >
            {r.node}
            {selected && (
              <rect
                x={-4}
                y={-4}
                width={contentW + 8}
                height={r.height + 4}
                fill="none"
                stroke={t.colors.accent}
                strokeWidth={2}
                strokeDasharray="5 3"
                rx={6}
                pointerEvents="none"
              />
            )}
          </g>
        );
      })}
    </svg>
  );
}
