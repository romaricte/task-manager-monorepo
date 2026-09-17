import type { Metadata } from "next";
import { AuthForm } from "@/components/auth-form";

export const metadata: Metadata = { title: "Créer un compte — Task manager" };

export default function RegisterPage() {
  return <AuthForm mode="register" />;
}
