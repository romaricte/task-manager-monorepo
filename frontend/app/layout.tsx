import type { Metadata } from "next";
import { AppProviders } from "@/components/providers";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3000"),
  title: "Momentum — Gestionnaire de tâches",
  description: "Organisez vos priorités et avancez sereinement avec Momentum.",
  openGraph: {
    title: "Momentum — Gestionnaire de tâches",
    description: "Avancez sereinement, une tâche à la fois.",
    type: "website",
    locale: "fr_FR",
    images: [{ url: "/og.png", width: 1728, height: 909, alt: "Momentum — Avancez sereinement, une tâche à la fois." }],
  },
  twitter: {
    card: "summary_large_image",
    title: "Momentum — Gestionnaire de tâches",
    description: "Avancez sereinement, une tâche à la fois.",
    images: ["/og.png"],
  },
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="fr">
      <body><AppProviders>{children}</AppProviders></body>
    </html>
  );
}
