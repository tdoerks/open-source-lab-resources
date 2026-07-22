import type { Theme } from "./themes";
import type { BrandKit } from "@/model/types";

/** Apply a brand kit's optional color overrides on top of a theme, so a whole
 *  lab's signs share the same primary/accent regardless of the chosen theme. */
export function resolveTheme(theme: Theme, brand?: BrandKit): Theme {
  if (!brand || (!brand.primary && !brand.accent)) return theme;
  return {
    ...theme,
    tokens: {
      ...theme.tokens,
      colors: {
        ...theme.tokens.colors,
        ...(brand.primary ? { primary: brand.primary } : {}),
        ...(brand.accent ? { accent: brand.accent } : {}),
      },
    },
  };
}
