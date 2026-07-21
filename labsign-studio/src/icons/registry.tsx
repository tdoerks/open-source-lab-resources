import {
  FlaskConical,
  FlaskRound,
  TestTube,
  TestTubes,
  Microscope,
  Dna,
  Syringe,
  Pill,
  Thermometer,
  Snowflake,
  Refrigerator,
  Archive,
  Box,
  Container,
  Package,
  Layers,
  Grid3x3,
  TriangleAlert,
  ShieldAlert,
  Flame,
  Biohazard,
  Skull,
  Calendar,
  Clock,
  MapPin,
  QrCode,
  Tag,
  Atom,
  Leaf,
  Bug,
  Fish,
  Droplet,
  Recycle,
  Users,
  ClipboardList,
  type LucideIcon,
} from "lucide-react";
import type { IconRef } from "@/model/types";

export interface CuratedIcon {
  name: string;
  label: string;
  group: string;
  Comp: LucideIcon;
}

/** The curated laboratory icon set surfaced in the picker. `name` is stored on
 *  the component's IconRef; add entries here to grow the library. */
export const ICON_SET: CuratedIcon[] = [
  { name: "flask", label: "Flask", group: "Bio", Comp: FlaskConical },
  { name: "flask-round", label: "Round flask", group: "Bio", Comp: FlaskRound },
  { name: "test-tube", label: "Test tube", group: "Bio", Comp: TestTube },
  { name: "test-tubes", label: "Test tubes", group: "Bio", Comp: TestTubes },
  { name: "microscope", label: "Microscope", group: "Bio", Comp: Microscope },
  { name: "dna", label: "DNA", group: "Bio", Comp: Dna },
  { name: "atom", label: "Atom", group: "Bio", Comp: Atom },
  { name: "syringe", label: "Syringe", group: "Bio", Comp: Syringe },
  { name: "pill", label: "Pill", group: "Bio", Comp: Pill },
  { name: "bug", label: "Microbe", group: "Bio", Comp: Bug },
  { name: "leaf", label: "Plant", group: "Bio", Comp: Leaf },
  { name: "fish", label: "Seafood", group: "Bio", Comp: Fish },
  { name: "droplet", label: "Sample", group: "Bio", Comp: Droplet },
  { name: "fridge", label: "Refrigerator", group: "Storage", Comp: Refrigerator },
  { name: "snowflake", label: "Freezer", group: "Storage", Comp: Snowflake },
  { name: "thermometer", label: "Temperature", group: "Storage", Comp: Thermometer },
  { name: "box", label: "Box", group: "Storage", Comp: Box },
  { name: "archive", label: "Archive", group: "Storage", Comp: Archive },
  { name: "container", label: "Container", group: "Storage", Comp: Container },
  { name: "package", label: "Package", group: "Storage", Comp: Package },
  { name: "layers", label: "Shelves", group: "Storage", Comp: Layers },
  { name: "grid", label: "Cryobox grid", group: "Storage", Comp: Grid3x3 },
  { name: "warning", label: "Warning", group: "Safety", Comp: TriangleAlert },
  { name: "shield", label: "Caution", group: "Safety", Comp: ShieldAlert },
  { name: "flame", label: "Flammable", group: "Safety", Comp: Flame },
  { name: "biohazard", label: "Biohazard", group: "Safety", Comp: Biohazard },
  { name: "toxic", label: "Toxic", group: "Safety", Comp: Skull },
  { name: "recycle", label: "Waste", group: "Safety", Comp: Recycle },
  { name: "calendar", label: "Date", group: "Info", Comp: Calendar },
  { name: "clock", label: "Time", group: "Info", Comp: Clock },
  { name: "pin", label: "Location", group: "Info", Comp: MapPin },
  { name: "qr", label: "QR", group: "Info", Comp: QrCode },
  { name: "tag", label: "Label", group: "Info", Comp: Tag },
  { name: "people", label: "People", group: "Info", Comp: Users },
  { name: "clipboard", label: "SOP", group: "Info", Comp: ClipboardList },
];

const BY_NAME = new Map(ICON_SET.map((i) => [i.name, i.Comp]));

export function iconComp(name?: string): LucideIcon | undefined {
  return name ? BY_NAME.get(name) : undefined;
}

/** Draw an icon at the SVG origin (0,0). Wrap in a <g transform> to place it. */
export function SignIcon({ icon, size, color }: { icon: IconRef; size: number; color: string }) {
  if (icon.source === "user" && icon.dataUri) {
    return <image href={icon.dataUri} width={size} height={size} preserveAspectRatio="xMidYMid meet" />;
  }
  const Comp = iconComp(icon.name);
  if (!Comp) return null;
  return <Comp width={size} height={size} color={color} strokeWidth={1.75} absoluteStrokeWidth />;
}
