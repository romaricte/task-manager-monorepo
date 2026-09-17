import { Check } from "lucide-react";

export function Brand({ inverse = false }: { inverse?: boolean }) {
  return (
    <span className={`brand-mark ${inverse ? "inverse" : ""}`} aria-label="Momentum">
      <span className="brand-icon"><Check size={18} strokeWidth={3} /></span>
      <span>momentum</span>
    </span>
  );
}
