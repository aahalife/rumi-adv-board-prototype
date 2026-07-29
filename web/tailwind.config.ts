import type { Config } from "tailwindcss";
import tailwindcssAnimate from "tailwindcss-animate";

const rgb = (v: string) => `rgb(var(${v}) / <alpha-value>)`;

export default {
  darkMode: ["class"],
  content: ["./pages/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}", "./app/**/*.{ts,tsx}", "./src/**/*.{ts,tsx}"],
  prefix: "",
  theme: {
    container: {
      center: true,
      padding: "2rem",
      screens: { "2xl": "1400px" },
    },
    extend: {
      colors: {
        // Sano semantic tokens
        base: rgb("--base"),
        surface: rgb("--surface"),
        raised: rgb("--raised"),
        ink: rgb("--ink"),
        "ink-muted": rgb("--ink-muted"),
        edge: rgb("--edge"),
        warm: rgb("--warm"),
        life: rgb("--life"),
        sky: rgb("--sky"),
        gold: rgb("--gold"),
        rose: rgb("--rose"),
        attention: rgb("--attention"),
        // shadcn bridge
        border: rgb("--border"),
        input: rgb("--input"),
        ring: rgb("--ring"),
        background: rgb("--background"),
        foreground: rgb("--foreground"),
        primary: { DEFAULT: rgb("--primary"), foreground: rgb("--primary-foreground") },
        secondary: { DEFAULT: rgb("--secondary"), foreground: rgb("--secondary-foreground") },
        destructive: { DEFAULT: rgb("--destructive"), foreground: rgb("--destructive-foreground") },
        muted: { DEFAULT: rgb("--muted"), foreground: rgb("--muted-foreground") },
        accent: { DEFAULT: rgb("--accent"), foreground: rgb("--accent-foreground") },
        popover: { DEFAULT: rgb("--popover"), foreground: rgb("--popover-foreground") },
        card: { DEFAULT: rgb("--card"), foreground: rgb("--card-foreground") },
      },
      fontFamily: {
        serif: ['"Fraunces"', "Georgia", "serif"],
        display: ['"Hermione"', '"Fraunces"', "Georgia", "serif"],
        rounded: ['"SF Pro Rounded"', "ui-rounded", '"Nunito"', "system-ui", "sans-serif"],
      },
      borderRadius: {
        lg: "var(--radius)",
        md: "calc(var(--radius) - 2px)",
        sm: "calc(var(--radius) - 4px)",
      },
      keyframes: {
        "accordion-down": { from: { height: "0" }, to: { height: "var(--radix-accordion-content-height)" } },
        "accordion-up": { from: { height: "var(--radix-accordion-content-height)" }, to: { height: "0" } },
      },
      animation: {
        "accordion-down": "accordion-down 0.2s ease-out",
        "accordion-up": "accordion-up 0.2s ease-out",
      },
    },
  },
  plugins: [tailwindcssAnimate],
} satisfies Config;
