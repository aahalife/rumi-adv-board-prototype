import React, { useEffect, useState } from "react";
import { cn } from "@/lib/utils";

/** A bottom sheet that slides up within the device frame. */
export const Sheet: React.FC<{ open: boolean; onClose: () => void; children: React.ReactNode; full?: boolean; bg?: string }> = ({
  open, onClose, children, full, bg,
}) => {
  const [mounted, setMounted] = useState(open);
  const [shown, setShown] = useState(false);
  useEffect(() => {
    if (open) {
      setMounted(true);
      const t = requestAnimationFrame(() => setShown(true));
      return () => cancelAnimationFrame(t);
    }
    setShown(false);
    const t = setTimeout(() => setMounted(false), 360);
    return () => clearTimeout(t);
  }, [open]);

  if (!mounted) return null;
  return (
    <div className="absolute inset-0 z-50" data-no-ripple>
      <div
        onClick={onClose}
        className={cn("absolute inset-0 transition-opacity duration-300", shown ? "opacity-100" : "opacity-0")}
        style={{ background: "rgb(0 0 0 / 0.32)", backdropFilter: "blur(2px)" }}
      />
      <div
        className={cn(
          "absolute inset-x-0 bottom-0 overflow-hidden transition-transform duration-[360ms]",
          shown ? "translate-y-0" : "translate-y-full",
        )}
        style={{
          top: full ? 0 : "5%",
          borderTopLeftRadius: full ? 0 : 30,
          borderTopRightRadius: full ? 0 : 30,
          background: bg ?? "rgb(var(--base))",
          transitionTimingFunction: "cubic-bezier(0.32, 0.72, 0, 1)",
          boxShadow: "0 -20px 60px -10px rgb(var(--shadow) / 0.4)",
        }}
      >
        {!full && (
          <div className="flex justify-center pt-2.5 pb-1">
            <div className="h-1.5 w-10 rounded-full" style={{ background: "rgb(var(--ink-muted) / 0.3)" }} />
          </div>
        )}
        <div className="h-full overflow-y-auto overscroll-contain">{children}</div>
      </div>
    </div>
  );
};

/** A pushed sub-screen that slides in from the right (navigation stack feel). */
export const PushScreen: React.FC<{ children: React.ReactNode; onBack?: () => void; title?: string }> = ({ children }) => (
  <div className="absolute inset-0 anim-push">{children}</div>
);
