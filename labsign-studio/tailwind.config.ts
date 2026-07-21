import type { Config } from "tailwindcss";

// The app chrome (UI) reads its palette from CSS variables defined in index.css,
// which are driven by the active UI theme. Sign/design tokens live separately in
// src/design/tokens.ts (consumed by the SVG renderer).
export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        bg: "var(--ui-bg)",
        surface: "var(--ui-surface)",
        "surface-2": "var(--ui-surface-2)",
        border: "var(--ui-border)",
        ink: "var(--ui-ink)",
        muted: "var(--ui-muted)",
        primary: "var(--ui-primary)",
        "primary-ink": "var(--ui-primary-ink)",
        accent: "var(--ui-accent)",
      },
      borderRadius: {
        md: "10px",
        lg: "14px",
      },
      boxShadow: {
        card: "0 1px 2px rgba(16,24,40,.06), 0 4px 12px rgba(16,24,40,.06)",
        raised: "0 6px 24px rgba(16,24,40,.12)",
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "-apple-system", "Segoe UI", "Roboto", "sans-serif"],
      },
    },
  },
  plugins: [],
} satisfies Config;
