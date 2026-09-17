"use client";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { CheckCircle2, CircleAlert, X } from "lucide-react";
import { createContext, useCallback, useContext, useMemo, useState } from "react";

type Toast = { id: number; message: string; type: "success" | "error" };
type ToastContextValue = { showToast: (message: string, type?: Toast["type"]) => void };

const ToastContext = createContext<ToastContextValue | null>(null);

export function AppProviders({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient({
    defaultOptions: {
      queries: { staleTime: 15_000, retry: 1, refetchOnWindowFocus: false },
      mutations: { retry: 0 },
    },
  }));
  const [toasts, setToasts] = useState<Toast[]>([]);

  const removeToast = useCallback((id: number) => {
    setToasts((current) => current.filter((toast) => toast.id !== id));
  }, []);

  const showToast = useCallback((message: string, type: Toast["type"] = "success") => {
    const id = Date.now() + Math.floor(Math.random() * 1000);
    setToasts((current) => [...current, { id, message, type }]);
    window.setTimeout(() => removeToast(id), 4_500);
  }, [removeToast]);

  const toastValue = useMemo(() => ({ showToast }), [showToast]);

  return (
    <QueryClientProvider client={queryClient}>
      <ToastContext.Provider value={toastValue}>
        {children}
        <div className="toast-viewport" aria-live="polite" aria-atomic="true">
          {toasts.map((toast) => (
            <div className={`toast ${toast.type}`} key={toast.id} role="status">
              {toast.type === "success" ? <CheckCircle2 size={19} /> : <CircleAlert size={19} />}
              <span>{toast.message}</span>
              <button type="button" aria-label="Fermer la notification" onClick={() => removeToast(toast.id)}><X size={16} /></button>
            </div>
          ))}
        </div>
      </ToastContext.Provider>
    </QueryClientProvider>
  );
}

export function useToast() {
  const value = useContext(ToastContext);
  if (!value) throw new Error("useToast doit être utilisé dans AppProviders");
  return value;
}
