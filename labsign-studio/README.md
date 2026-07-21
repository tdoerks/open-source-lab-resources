# LabSign Studio

A Canva-for-laboratory-signage design system. Users edit **content**; the app automatically
enforces a professional design language (spacing, typography, color, hierarchy) so every sign in a
lab looks like it belongs to the same set. Structured components + equipment profiles — **not** an
image generator.

**Module 1: Storage Maps** (freezers, refrigerators, cabinets, incubators, shelving, cryoboxes…).

> Status: **Phase 0–1 scaffold.** Working 3-pane studio, design-token theme system (5 themes),
> SVG rendering engine, click-to-select + live property editing. Equipment profiles, the full
> component library, exports, and the AI Smart Builder are planned in later phases (see the design
> blueprint).

## Tech
Vite · React · TypeScript · TailwindCSS · Zustand. The canvas is **SVG-first** (one SVG document per
sign) so it prints at full quality and exports cleanly to PNG/SVG/PDF from a single source.

## Develop
```bash
cd labsign-studio
npm install
npm run dev        # local dev server
npm run typecheck  # tsc --noEmit
npm run build      # production build to dist/
```

## Architecture (short)
- `src/design/` — design tokens + themes (the enforced visual language).
- `src/model/` — typed data model (Project, Sign, ComponentInstance union, equipment bindings).
- `src/render/` — layout engine + per-component SVG renderers + `SignSvg` (profiles/components → editable SVG).
- `src/store/` — Zustand studio store (document, selection, actions).
- `src/app/` — the studio shell (Toolbar, LeftRail, CanvasStage, Properties).
- `src/equipment/`, `src/export/`, `src/modules/` — added in later phases.

Every sign is an ordered tree of themed components; equipment profiles generate that tree from a few
structured parameters. See the full design blueprint for the roadmap.
