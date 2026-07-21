import { create } from "zustand";
import type { ThemeId } from "@/design/themes";
import type { ComponentInstance, Project, Sign } from "@/model/types";
import { sampleProject } from "@/model/sample";

interface StudioState {
  project: Project;
  activeSignId: string;
  selectedId: string | null;

  // selectors
  activeSign: () => Sign;

  // actions
  select: (id: string | null) => void;
  setTheme: (themeId: ThemeId) => void;
  renameSign: (name: string) => void;
  /** Shallow-merge props on a component instance in the active sign. */
  updateProps: (id: string, props: Record<string, unknown>) => void;
  removeComponent: (id: string) => void;
}

function touch(p: Project): Project {
  return { ...p, updatedAt: Date.now() };
}

export const useStudio = create<StudioState>((set, get) => {
  const project = sampleProject();
  return {
    project,
    activeSignId: project.signs[0].id,
    selectedId: null,

    activeSign: () => {
      const s = get();
      return s.project.signs.find((sg) => sg.id === s.activeSignId)!;
    },

    select: (id) => set({ selectedId: id }),

    setTheme: (themeId) =>
      set((s) => ({
        project: touch({
          ...s.project,
          signs: s.project.signs.map((sg) => (sg.id === s.activeSignId ? { ...sg, themeId } : sg)),
        }),
      })),

    renameSign: (name) =>
      set((s) => ({
        project: touch({
          ...s.project,
          signs: s.project.signs.map((sg) => (sg.id === s.activeSignId ? { ...sg, name } : sg)),
        }),
      })),

    updateProps: (id, props) =>
      set((s) => ({
        project: touch({
          ...s.project,
          signs: s.project.signs.map((sg) =>
            sg.id !== s.activeSignId
              ? sg
              : {
                  ...sg,
                  tree: sg.tree.map((c) =>
                    c.id === id ? ({ ...c, props: { ...c.props, ...props } } as ComponentInstance) : c,
                  ),
                },
          ),
        }),
      })),

    removeComponent: (id) =>
      set((s) => ({
        selectedId: s.selectedId === id ? null : s.selectedId,
        project: touch({
          ...s.project,
          signs: s.project.signs.map((sg) =>
            sg.id !== s.activeSignId ? sg : { ...sg, tree: sg.tree.filter((c) => c.id !== id) },
          ),
        }),
      })),
  };
});
