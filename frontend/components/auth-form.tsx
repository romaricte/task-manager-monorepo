"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { ArrowRight, Eye, EyeOff, LockKeyhole, Mail, UserRound } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { FormEvent, useEffect, useState } from "react";
import { ApiClientError, authApi } from "@/lib/api";
import { Brand } from "./brand";
import { useToast } from "./providers";

type AuthFormProps = { mode: "login" | "register" };

export function AuthForm({ mode }: AuthFormProps) {
  const isRegister = mode === "register";
  const router = useRouter();
  const queryClient = useQueryClient();
  const { showToast } = useToast();
  const [showPassword, setShowPassword] = useState(false);
  const [form, setForm] = useState({ name: "", email: "", password: "" });
  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

  const sessionQuery = useQuery({
    queryKey: ["session"],
    queryFn: authApi.session,
    retry: false,
    staleTime: 60_000,
  });

  useEffect(() => {
    if (sessionQuery.isSuccess) router.replace("/");
  }, [router, sessionQuery.isSuccess]);

  const mutation = useMutation({
    mutationFn: () => isRegister
      ? authApi.register(form)
      : authApi.login({ email: form.email, password: form.password }),
    onSuccess: (data) => {
      queryClient.setQueryData(["session"], data);
      showToast(isRegister ? "Votre compte est prêt. Bienvenue !" : "Connexion réussie. Bon retour !");
      router.replace("/");
    },
    onError: (error) => {
      if (error instanceof ApiClientError && error.validationErrors) {
        setFieldErrors(error.validationErrors);
      }
      showToast(error instanceof Error ? error.message : "Connexion impossible", "error");
    },
  });

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const errors: Record<string, string> = {};
    if (isRegister && form.name.trim().length < 2) errors.name = "Indiquez votre nom";
    if (!/^\S+@\S+\.\S+$/.test(form.email)) errors.email = "Saisissez une adresse e-mail valide";
    if (form.password.length < 8) errors.password = "Le mot de passe doit contenir au moins 8 caractères";
    setFieldErrors(errors);
    if (Object.keys(errors).length === 0) mutation.mutate();
  }

  return (
    <main className="auth-shell">
      <section className="auth-story" aria-label="Présentation de Momentum">
        <Brand inverse />
        <div className="auth-story-copy">
          <span className="story-kicker">Votre espace, votre rythme.</span>
          <h1>Chaque grande journée commence par une priorité claire.</h1>
          <p>Rassemblez vos tâches, suivez vos avancées et gardez l’esprit léger.</p>
        </div>
        <div className="story-card-stack" aria-hidden="true">
          <div className="story-task story-task-one"><span>✓</span><i /><i /></div>
          <div className="story-task story-task-two"><span>✓</span><i /><i /></div>
          <div className="story-orbit" />
        </div>
        <p className="auth-quote">“La simplicité est la sophistication suprême.”</p>
      </section>

      <section className="auth-panel">
        <div className="auth-mobile-brand"><Brand /></div>
        <div className="auth-card">
          <span className="eyebrow">{isRegister ? "Commencer" : "Bon retour"}</span>
          <h2>{isRegister ? "Créez votre espace" : "Connectez-vous"}</h2>
          <p>{isRegister ? "Quelques secondes suffisent pour organiser votre journée." : "Retrouvez vos tâches exactement là où vous les avez laissées."}</p>

          <form className="auth-form" onSubmit={submit} noValidate>
            {isRegister && (
              <label className="form-field">
                <span>Nom complet</span>
                <span className={`input-wrap ${fieldErrors.name ? "invalid" : ""}`}>
                  <UserRound size={18} />
                  <input
                    autoComplete="name"
                    value={form.name}
                    onChange={(event) => setForm({ ...form, name: event.target.value })}
                    placeholder="Alice Kamga"
                    aria-invalid={Boolean(fieldErrors.name)}
                  />
                </span>
                {fieldErrors.name && <small className="field-error">{fieldErrors.name}</small>}
              </label>
            )}

            <label className="form-field">
              <span>Adresse e-mail</span>
              <span className={`input-wrap ${fieldErrors.email ? "invalid" : ""}`}>
                <Mail size={18} />
                <input
                  type="email"
                  autoComplete="email"
                  value={form.email}
                  onChange={(event) => setForm({ ...form, email: event.target.value })}
                  placeholder="alice@example.com"
                  aria-invalid={Boolean(fieldErrors.email)}
                />
              </span>
              {fieldErrors.email && <small className="field-error">{fieldErrors.email}</small>}
            </label>

            <label className="form-field">
              <span>Mot de passe</span>
              <span className={`input-wrap ${fieldErrors.password ? "invalid" : ""}`}>
                <LockKeyhole size={18} />
                <input
                  type={showPassword ? "text" : "password"}
                  autoComplete={isRegister ? "new-password" : "current-password"}
                  value={form.password}
                  onChange={(event) => setForm({ ...form, password: event.target.value })}
                  placeholder="8 caractères minimum"
                  aria-invalid={Boolean(fieldErrors.password)}
                />
                <button type="button" aria-label={showPassword ? "Masquer le mot de passe" : "Afficher le mot de passe"} onClick={() => setShowPassword((value) => !value)}>
                  {showPassword ? <EyeOff size={17} /> : <Eye size={17} />}
                </button>
              </span>
              {fieldErrors.password && <small className="field-error">{fieldErrors.password}</small>}
            </label>

            <button className="auth-submit" type="submit" disabled={mutation.isPending}>
              {mutation.isPending ? <span className="spinner" /> : <>{isRegister ? "Créer mon compte" : "Se connecter"}<ArrowRight size={18} /></>}
            </button>
          </form>

          <p className="auth-switch">
            {isRegister ? "Déjà un compte ?" : "Nouveau sur Momentum ?"}{" "}
            <Link href={isRegister ? "/login" : "/register"}>{isRegister ? "Se connecter" : "Créer un compte"}</Link>
          </p>
        </div>
      </section>
    </main>
  );
}
