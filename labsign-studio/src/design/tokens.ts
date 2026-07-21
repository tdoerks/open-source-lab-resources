/**
 * Design tokens — the single source of truth for the *sign* design language.
 * The SVG renderer consumes a resolved DesignTokens object (from the active
 * theme). Users edit content; these tokens enforce spacing / type / color so
 * every sign in a lab looks like a set.
 */

/** 4-based spacing scale (SVG user units == points at 1:1). Layout snaps to these. */
export const SPACE = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  "2xl": 32,
  "3xl": 48,
} as const;

/** Type ramp for signs (sizes in SVG units; uppercase titles, strong hierarchy). */
export const TYPE = {
  display: { size: 44, weight: 800, tracking: 0.5, upper: true },
  title: { size: 26, weight: 700, tracking: 0.4, upper: true },
  subtitle: { size: 17, weight: 600, tracking: 0.2, upper: false },
  heading: { size: 14, weight: 700, tracking: 0.6, upper: true },
  body: { size: 13, weight: 500, tracking: 0, upper: false },
  caption: { size: 10.5, weight: 600, tracking: 0.5, upper: true },
} as const;

export type TypeRole = keyof typeof TYPE;

export const RADIUS = { sm: 6, md: 10, lg: 14 } as const;

/** Semantic color slots every theme must provide. Components reference these
 *  by name (never raw hex) so a theme swap restyles everything. */
export interface ThemeColors {
  bg: string; // sign background
  surface: string; // card / panel fill
  surfaceAlt: string; // subtle alt fill (zebra rows)
  border: string;
  ink: string; // primary text
  muted: string; // secondary text
  primary: string; // brand / header band
  primaryInk: string; // text on primary
  accent: string;
  warn: string;
  danger: string;
  ok: string;
}

export type ThemeColorRef = keyof ThemeColors;

export interface DesignTokens {
  colors: ThemeColors;
  /** Base font family for the sign SVG. */
  fontFamily: string;
  radius: number; // default card radius
  /** Whether section headers render as filled bands (true) or underlined (false). */
  bandedHeaders: boolean;
}
