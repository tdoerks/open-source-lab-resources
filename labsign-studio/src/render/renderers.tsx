import type { ReactElement } from "react";
import { TYPE, SPACE, type TypeRole } from "@/design/tokens";
import type { ComponentInstance } from "@/model/types";
import type { RenderCtx } from "./ctx";

/** A rendered component: its SVG node (drawn in local 0,0 coords) + measured height. */
export interface Rendered {
  height: number;
  node: ReactElement;
}

/** Themed SVG text helper honoring a type role. */
function T(props: {
  x: number;
  y: number;
  role: TypeRole;
  fill: string;
  text: string;
  anchor?: "start" | "middle" | "end";
  family: string;
}) {
  const r = TYPE[props.role];
  const value = r.upper ? props.text.toUpperCase() : props.text;
  return (
    <text
      x={props.x}
      y={props.y}
      fontFamily={props.family}
      fontSize={r.size}
      fontWeight={r.weight}
      letterSpacing={r.tracking}
      fill={props.fill}
      textAnchor={props.anchor ?? "start"}
    >
      {value}
    </text>
  );
}

type Renderer = (inst: ComponentInstance, ctx: RenderCtx) => Rendered;

const renderers: { [K in ComponentInstance["type"]]: Renderer } = {
  titleBlock: (inst, ctx) => {
    if (inst.type !== "titleBlock") throw 0;
    const { t, w } = ctx;
    const has = !!inst.props.subtitle;
    const height = has ? 76 : 58;
    const node = (
      <g>
        <rect x={0} y={0} width={w} height={height} rx={t.radius} fill={t.colors.primary} />
        <T x={SPACE.lg} y={has ? 40 : 38} role="display" fill={t.colors.primaryInk} text={inst.props.title} family={t.fontFamily} />
        {has && (
          <T x={SPACE.lg} y={62} role="subtitle" fill={t.colors.primaryInk} text={inst.props.subtitle!} family={t.fontFamily} />
        )}
        {inst.props.badge && (
          <>
            <rect x={w - 92} y={14} width={78} height={22} rx={11} fill={t.colors.primaryInk} opacity={0.18} />
            <T x={w - 53} y={29} role="caption" fill={t.colors.primaryInk} text={inst.props.badge} anchor="middle" family={t.fontFamily} />
          </>
        )}
      </g>
    );
    return { height, node };
  },

  sectionHeader: (inst, ctx) => {
    if (inst.type !== "sectionHeader") throw 0;
    const { t, w } = ctx;
    const height = 28;
    const node = t.bandedHeaders ? (
      <g>
        <rect x={0} y={0} width={w} height={22} rx={4} fill={t.colors.primary} opacity={0.92} />
        <T x={SPACE.sm} y={16} role="heading" fill={t.colors.primaryInk} text={inst.props.text} family={t.fontFamily} />
      </g>
    ) : (
      <g>
        <T x={0} y={14} role="heading" fill={t.colors.ink} text={inst.props.text} family={t.fontFamily} />
        <line x1={0} y1={22} x2={w} y2={22} stroke={t.colors.border} strokeWidth={1.5} />
      </g>
    );
    return { height, node };
  },

  shelfRow: (inst, ctx) => {
    if (inst.type !== "shelfRow") throw 0;
    const { t, w } = ctx;
    const height = 42;
    const tone = inst.props.tone ? t.colors[inst.props.tone] : t.colors.accent;
    const node = (
      <g>
        <rect x={0} y={0} width={w} height={36} rx={t.radius} fill={t.colors.surface} stroke={t.colors.border} strokeWidth={1} />
        <rect x={0} y={0} width={6} height={36} rx={3} fill={tone} />
        <T x={16} y={16} role="body" fill={t.colors.ink} text={inst.props.label} family={t.fontFamily} />
        <T x={16} y={29} role="caption" fill={t.colors.muted} text={inst.props.contents || "—"} family={t.fontFamily} />
      </g>
    );
    return { height, node };
  },

  card: (inst, ctx) => {
    if (inst.type !== "card") throw 0;
    const { t, w } = ctx;
    const height = 56;
    const node = (
      <g>
        <rect x={0} y={0} width={w} height={50} rx={t.radius} fill={t.colors.surface} stroke={t.colors.border} strokeWidth={1} />
        <T x={14} y={22} role="subtitle" fill={t.colors.ink} text={inst.props.title} family={t.fontFamily} />
        {inst.props.body && <T x={14} y={40} role="body" fill={t.colors.muted} text={inst.props.body} family={t.fontFamily} />}
      </g>
    );
    return { height, node };
  },

  note: (inst, ctx) => {
    if (inst.type !== "note") throw 0;
    const { t, w } = ctx;
    const height = 40;
    const map = { info: t.colors.accent, reminder: t.colors.ok, warning: t.colors.danger } as const;
    const c = map[inst.props.variant];
    const node = (
      <g>
        <rect x={0} y={0} width={w} height={34} rx={t.radius} fill={c} opacity={0.12} />
        <rect x={0} y={0} width={5} height={34} rx={2.5} fill={c} />
        <T x={14} y={22} role="body" fill={t.colors.ink} text={inst.props.text} family={t.fontFamily} />
      </g>
    );
    return { height, node };
  },

  footer: (inst, ctx) => {
    if (inst.type !== "footer") throw 0;
    const { t, w } = ctx;
    const height = 22;
    const node = (
      <g>
        <line x1={0} y1={2} x2={w} y2={2} stroke={t.colors.border} strokeWidth={1} />
        {inst.props.left && <T x={0} y={16} role="caption" fill={t.colors.muted} text={inst.props.left} family={t.fontFamily} />}
        {inst.props.right && <T x={w} y={16} role="caption" fill={t.colors.muted} text={inst.props.right} anchor="end" family={t.fontFamily} />}
      </g>
    );
    return { height, node };
  },
};

export function renderComponent(inst: ComponentInstance, ctx: RenderCtx): Rendered {
  return renderers[inst.type](inst, ctx);
}
