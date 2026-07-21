import { create } from "zustand";
import { nanoid } from "nanoid";
import type { ThemeId } from "@/design/themes";
import type { ComponentInstance, ComponentType, Project, Sign } from "@/model/types";
import { sampleProject } from "@/model/sample";
import { getProfile } from "@/equipment/registry";
import { defaultValues, type EquipmentValues } from "@/equipment/types";

/** A fresh component instance with sensible defaults, for the Add palette. */
function newInstance(type: ComponentType): ComponentInstance {
  const id = nanoid(8);
  switch (type) {
    case "titleBlock":
      return { id, type, props: { title: "Title", subtitle: "" } };
    case "sectionHeader":
      return { id, type, props: { text: "Section" } };
    case "shelfRow":
      return { id, type, props: { label: "Shelf", contents: "", tone: "accent" } };
    case "card":
      return { id, type, props: { title: "Card title", body: "" } };
    case "note":
      return { id, type, props: { text: "Note text", variant: "info" } };
    case "grid":
      return { id, type, props: { label: "Grid", rows: 9, cols: 9 } };
    case "footer":
      return { id, type, props: { left: "", right: "" } };
  }
}

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
  /** Append a fresh component of the given type and select it. */
  addComponent: (type: ComponentType) => void;
  /** Apply an equipment profile: seed defaults and generate the sign's tree. */
  setEquipment: (profileId: string) => void;
  /** Change one guided-question value and regenerate the layout. */
  updateEquipmentValue: (key: string, value: string | number | boolean) => void;
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

    addComponent: (type) => {
      const inst = newInstance(type);
      set((s) => ({
        selectedId: inst.id,
        project: touch({
          ...s.project,
          signs: s.project.signs.map((sg) =>
            sg.id !== s.activeSignId ? sg : { ...sg, tree: [...sg.tree, inst] },
          ),
        }),
      }));
    },

    setEquipment: (profileId) =>
      set((s) => {
        const profile = getProfile(profileId);
        if (!profile) return {};
        const values = defaultValues(profile);
        const tree = profile.generate(values);
        return {
          selectedId: null,
          project: touch({
            ...s.project,
            signs: s.project.signs.map((sg) =>
              sg.id === s.activeSignId
                ? { ...sg, name: profile.name, equipment: { profileId, values }, tree }
                : sg,
            ),
          }),
        };
      }),

    updateEquipmentValue: (key, value) =>
      set((s) => {
        const sign = s.project.signs.find((sg) => sg.id === s.activeSignId)!;
        if (!sign.equipment) return {};
        const profile = getProfile(sign.equipment.profileId);
        if (!profile) return {};
        const values: EquipmentValues = { ...sign.equipment.values, [key]: value };
        const tree = profile.generate(values);
        return {
          project: touch({
            ...s.project,
            signs: s.project.signs.map((sg) =>
              sg.id === s.activeSignId ? { ...sg, equipment: { profileId: profile.id, values }, tree } : sg,
            ),
          }),
        };
      }),
  };
});
