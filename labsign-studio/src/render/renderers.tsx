import type { ReactElement } from "react";
import { TYPE, SPACE, type TypeRole } from "@/design/tokens";
import type { ComponentInstance } from "@/model/types";
import { SignIcon } from "@/icons/registry";
import type { RenderCtx } from "./ctx";

/** A rendered component: its SVG node (drawn in local 0,0 coords) + measured height. */
export interface Rendered {
  height: number;
  node: ReactElement;
}

/** Rough text width estimate (bold-ish sans), for auto-fitting titles. */
function estWidth(s: string, size: number): number {
  return s.length * size * 0.6;
}
/** Largest size in [min, base] that fits `s` within `maxW`. */
function fit(s: string, maxW: number, base: number, min: number): number {
  let sz = base;
  while (sz > min && estWidth(s, sz) > maxW) sz -= 1;
  return sz;
}

/** Themed SVG text helper honoring a type role (with optional size override). */
function T(props: {
  x: number;
  y: number;
  role: TypeRole;
  fill: string;
  text: string;
  anchor?: "start" | "middle" | "end";
  family: string;
  size?: number;
}) {
  const r = TYPE[props.role];
  const value = r.upper ? props.text.toUpperCase() : props.text;
  return (
    <text
      x={props.x}
      y={props.y}
      fontFamily={props.family}
      fontSize={props.size ?? r.size}
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
    const ic = inst.props.icon;
    const height = has ? 76 : 58;
    const tx = ic ? SPACE.lg + 42 : SPACE.lg;
    const badgeW = inst.props.badge ? 96 : SPACE.lg;
    const titleSize = fit(inst.props.title.toUpperCase(), w - tx - badgeW, TYPE.display.size, 22);
    const node = (
      <g>
        <rect x={0} y={0} width={w} height={height} rx={t.radius} fill={t.colors.primary} />
        {ic && (
          <g transform={`translate(${SPACE.lg},${(height - 32) / 2})`}>
            <SignIcon icon={ic} size={32} color={t.colors.primaryInk} />
          </g>
        )}
        <T x={tx} y={has ? 40 : 38} role="display" size={titleSize} fill={t.colors.primaryInk} text={inst.props.title} family={t.fontFamily} />
        {has && (
          <T x={tx} y={62} role="subtitle" fill={t.colors.primaryInk} text={inst.props.subtitle!} family={t.fontFamily} />
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
    const ic = inst.props.icon;
    const node = t.bandedHeaders ? (
      <g>
        <rect x={0} y={0} width={w} height={22} rx={4} fill={t.colors.primary} opacity={0.92} />
        {ic && (
          <g transform="translate(8,4)">
            <SignIcon icon={ic} size={14} color={t.colors.primaryInk} />
          </g>
        )}
        <T x={ic ? SPACE.sm + 20 : SPACE.sm} y={16} role="heading" fill={t.colors.primaryInk} text={inst.props.text} family={t.fontFamily} />
      </g>
    ) : (
      <g>
        {ic && (
          <g transform="translate(0,1)">
            <SignIcon icon={ic} size={14} color={t.colors.ink} />
          </g>
        )}
        <T x={ic ? 20 : 0} y={14} role="heading" fill={t.colors.ink} text={inst.props.text} family={t.fontFamily} />
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
    const ic = inst.props.icon;
    const tx = ic ? 42 : 16;
    const node = (
      <g>
        <rect x={0} y={0} width={w} height={36} rx={t.radius} fill={t.colors.surface} stroke={t.colors.border} strokeWidth={1} />
        <rect x={0} y={0} width={6} height={36} rx={3} fill={tone} />
        {ic && (
          <g transform="translate(15,9)">
            <SignIcon icon={ic} size={18} color={tone} />
          </g>
        )}
        <T x={tx} y={16} role="body" fill={t.colors.ink} text={inst.props.label} family={t.fontFamily} />
        <T x={tx} y={29} role="caption" fill={t.colors.muted} text={inst.props.contents || "—"} family={t.fontFamily} />
      </g>
    );
    return { height, node };
  },

  card: (inst, ctx) => {
    if (inst.type !== "card") throw 0;
    const { t, w } = ctx;
    const height = 56;
    const ic = inst.props.icon;
    const tx = ic ? 44 : 14;
    const node = (
      <g>
        <rect x={0} y={0} width={w} height={50} rx={t.radius} fill={t.colors.surface} stroke={t.colors.border} strokeWidth={1} />
        {ic && (
          <g transform="translate(13,15)">
            <SignIcon icon={ic} size={20} color={t.colors.primary} />
          </g>
        )}
        <T x={tx} y={22} role="subtitle" fill={t.colors.ink} text={inst.props.title} family={t.fontFamily} />
        {inst.props.body && <T x={tx} y={40} role="body" fill={t.colors.muted} text={inst.props.body} family={t.fontFamily} />}
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

  grid: (inst, ctx) => {
    if (inst.type !== "grid") throw 0;
    const { t, w } = ctx;
    const cols = Math.max(1, inst.props.cols);
    const rows = Math.max(1, inst.props.rows);
    const cell = Math.max(9, Math.min(22, Math.floor((w - 20) / cols)));
    const gw = cols * cell;
    const gh = rows * cell;
    const y0 = 22;
    const height = y0 + gh + 8;
    const cells: ReactElement[] = [];
    for (let r = 0; r < rows; r++) {
      for (let c = 0; c < cols; c++) {
        cells.push(
          <rect
            key={`${r}-${c}`}
            x={c * cell}
            y={y0 + r * cell}
            width={cell}
            height={cell}
            fill={(r + c) % 2 ? t.colors.surfaceAlt : t.colors.surface}
            stroke={t.colors.border}
            strokeWidth={0.75}
          />,
        );
      }
    }
    const node = (
      <g>
        <T x={0} y={14} role="heading" fill={t.colors.ink} text={inst.props.label} family={t.fontFamily} />
        {cells}
        {inst.props.note && (
          <T x={gw + 14} y={y0 + 16} role="body" fill={t.colors.muted} text={inst.props.note} family={t.fontFamily} />
        )}
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
