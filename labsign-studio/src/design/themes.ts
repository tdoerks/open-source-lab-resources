import type { DesignTokens } from "./tokens";

export type ThemeId = "scientific" | "university" | "minimal" | "osha" | "dark";

export interface Theme {
  id: ThemeId;
  name: string;
  tokens: DesignTokens;
}

const SANS = "Inter, system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif";

export const THEMES: Record<ThemeId, Theme> = {
  scientific: {
    id: "scientific",
    name: "Scientific Modern",
    tokens: {
      fontFamily: SANS,
      radius: 10,
      bandedHeaders: true,
      colors: {
        bg: "#ffffff",
        surface: "#f6f8fb",
        surfaceAlt: "#eef2f7",
        border: "#d7dee8",
        ink: "#16202e",
        muted: "#5b6b80",
        primary: "#0f4c81",
        primaryInk: "#ffffff",
        accent: "#1a9e8f",
        warn: "#c77700",
        danger: "#c0392b",
        ok: "#2e8b57",
      },
    },
  },
  university: {
    id: "university",
    name: "University",
    tokens: {
      fontFamily: SANS,
      radius: 8,
      bandedHeaders: true,
      colors: {
        bg: "#ffffff",
        surface: "#f5f2f8",
        surfaceAlt: "#efe9f4",
        border: "#ddd3e6",
        ink: "#1c1523",
        muted: "#6a5b78",
        primary: "#512888",
        primaryInk: "#ffffff",
        accent: "#a67c00",
        warn: "#b8860b",
        danger: "#b3141c",
        ok: "#3d7a3d",
      },
    },
  },
  minimal: {
    id: "minimal",
    name: "Minimal",
    tokens: {
      fontFamily: SANS,
      radius: 6,
      bandedHeaders: false,
      colors: {
        bg: "#ffffff",
        surface: "#fafafa",
        surfaceAlt: "#f2f2f2",
        border: "#e4e4e4",
        ink: "#111111",
        muted: "#777777",
        primary: "#111111",
        primaryInk: "#ffffff",
        accent: "#111111",
        warn: "#8a6d00",
        danger: "#8a1f16",
        ok: "#2f6f3f",
      },
    },
  },
  osha: {
    id: "osha",
    name: "OSHA High-Vis",
    tokens: {
      fontFamily: SANS,
      radius: 4,
      bandedHeaders: true,
      colors: {
        bg: "#ffffff",
        surface: "#fff8e1",
        surfaceAlt: "#fff3cd",
        border: "#111111",
        ink: "#111111",
        muted: "#3a3a3a",
        primary: "#111111",
        primaryInk: "#ffd200",
        accent: "#e30613",
        warn: "#ff6a00",
        danger: "#e30613",
        ok: "#1f8f3a",
      },
    },
  },
  dark: {
    id: "dark",
    name: "Dark",
    tokens: {
      fontFamily: SANS,
      radius: 10,
      bandedHeaders: true,
      colors: {
        bg: "#12161d",
        surface: "#1b212b",
        surfaceAlt: "#232b37",
        border: "#33404f",
        ink: "#eaf0f7",
        muted: "#9fb0c3",
        primary: "#2f6feb",
        primaryInk: "#ffffff",
        accent: "#31c8b0",
        warn: "#e0a458",
        danger: "#f0616d",
        ok: "#43c07a",
      },
    },
  },
};

export const THEME_LIST = Object.values(THEMES);
