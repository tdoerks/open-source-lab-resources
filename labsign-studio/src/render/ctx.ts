import type { DesignTokens, ThemeColorRef } from "@/design/tokens";

/** Rendering context handed to every component renderer. */
export interface RenderCtx {
  t: DesignTokens;
  /** Local content width available to the component (SVG units). */
  w: number;
}

/** Resolve a theme color slot to a concrete value. */
export function color(t: DesignTokens, ref: ThemeColorRef | undefined, fallback: ThemeColorRef): string {
  return t.colors[ref ?? fallback];
}
