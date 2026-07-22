import { renderToStaticMarkup } from "react-dom/server";
import { createElement } from "react";
import type { Theme } from "@/design/themes";
import type { Sign } from "@/model/types";
import { SignSvg } from "@/render/SignSvg";

const PT_PER_IN = 72;

/** Serialize a sign to a standalone, non-interactive SVG string. */
export function signToSvgString(sign: Sign, theme: Theme): string {
  const markup = renderToStaticMarkup(createElement(SignSvg, { sign, theme, interactive: false }));
  return `<?xml version="1.0" encoding="UTF-8"?>\n${markup}`;
}

/** Rasterize a sign to a canvas at the given DPI (SVG units are points @72/in). */
function signToCanvas(sign: Sign, theme: Theme, dpi: number): Promise<HTMLCanvasElement> {
  const svg = signToSvgString(sign, theme);
  const W = sign.size.wIn * PT_PER_IN;
  const H = sign.size.hIn * PT_PER_IN;
  const scale = dpi / PT_PER_IN;
  return new Promise((resolve, reject) => {
    const img = new Image();
    img.onload = () => {
      const canvas = document.createElement("canvas");
      canvas.width = Math.round(W * scale);
      canvas.height = Math.round(H * scale);
      const ctx = canvas.getContext("2d")!;
      ctx.fillStyle = "#ffffff";
      ctx.fillRect(0, 0, canvas.width, canvas.height);
      ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
      resolve(canvas);
    };
    img.onerror = () => reject(new Error("Failed to rasterize sign SVG"));
    img.src = "data:image/svg+xml;base64," + btoa(unescape(encodeURIComponent(svg)));
  });
}

function fileName(sign: Sign, ext: string): string {
  const base = (sign.name || "sign").replace(/[^a-z0-9\-_]+/gi, "_");
  return `${base}.${ext}`;
}

function download(blob: Blob, name: string) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = name;
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

export function exportSvg(sign: Sign, theme: Theme) {
  download(new Blob([signToSvgString(sign, theme)], { type: "image/svg+xml" }), fileName(sign, "svg"));
}

export async function exportPng(sign: Sign, theme: Theme, dpi = 300) {
  const canvas = await signToCanvas(sign, theme, dpi);
  await new Promise<void>((res) =>
    canvas.toBlob((blob) => {
      if (blob) download(blob, fileName(sign, "png"));
      res();
    }, "image/png"),
  );
}

/**
 * Single-page, page-sized PDF with the sign embedded as a JPEG (DCTDecode).
 * Hand-built (no library) — a JPEG can be embedded directly in a PDF image
 * XObject, keeping the bundle lean. (jsPDF can replace this later for the
 * multi-page Facility Pack.)
 */
export async function exportPdf(sign: Sign, theme: Theme, dpi = 300) {
  const canvas = await signToCanvas(sign, theme, dpi);
  const jpeg = atob(canvas.toDataURL("image/jpeg", 0.95).split(",")[1]); // binary string
  const ptW = sign.size.wIn * PT_PER_IN;
  const ptH = sign.size.hIn * PT_PER_IN;

  const objects = [
    "<< /Type /Catalog /Pages 2 0 R >>",
    "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
    `<< /Type /Page /Parent 2 0 R /MediaBox [0 0 ${ptW} ${ptH}] /Resources << /XObject << /Im0 5 0 R >> >> /Contents 4 0 R >>`,
  ];
  const content = `q ${ptW} 0 0 ${ptH} 0 0 cm /Im0 Do Q`;
  objects.push(`<< /Length ${content.length} >>\nstream\n${content}\nendstream`);
  objects.push(
    `<< /Type /XObject /Subtype /Image /Width ${canvas.width} /Height ${canvas.height} /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length ${jpeg.length} >>\nstream\n${jpeg}\nendstream`,
  );

  let pdf = "%PDF-1.4\n%\xFF\xFF\xFF\xFF\n";
  const offsets: number[] = [];
  for (let i = 0; i < objects.length; i++) {
    offsets.push(pdf.length);
    pdf += `${i + 1} 0 obj\n${objects[i]}\nendobj\n`;
  }
  const xref = pdf.length;
  pdf += `xref\n0 ${objects.length + 1}\n0000000000 65535 f \n`;
  for (const o of offsets) pdf += ("0000000000" + o).slice(-10) + " 00000 n \n";
  pdf += `trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${xref}\n%%EOF`;

  const bytes = new Uint8Array(pdf.length);
  for (let i = 0; i < pdf.length; i++) bytes[i] = pdf.charCodeAt(i) & 0xff;
  download(new Blob([bytes], { type: "application/pdf" }), fileName(sign, "pdf"));
}
