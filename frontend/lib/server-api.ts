import { cookies } from "next/headers";
import { NextResponse } from "next/server";
import type { User } from "./types";

export const TOKEN_COOKIE = "momentum_token";
export const USER_COOKIE = "momentum_user";
const API_URL = (process.env.API_URL ?? "http://localhost:8080").replace(/\/$/, "");

type AuthPayload = {
  token: string;
  expiresIn: number;
  user: User;
};

const cookieOptions = (maxAge: number) => ({
  httpOnly: true,
  secure: process.env.NODE_ENV === "production",
  sameSite: "strict" as const,
  path: "/",
  maxAge,
  priority: "high" as const,
});

export async function authenticate(request: Request, endpoint: "login" | "register") {
  try {
    const upstream = await fetch(`${API_URL}/api/auth/${endpoint}`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json" },
      body: await request.text(),
      cache: "no-store",
    });
    const body = await upstream.json().catch(() => ({ message: "Réponse invalide du serveur" }));

    if (!upstream.ok) {
      return NextResponse.json(body, { status: upstream.status });
    }

    const auth = body as AuthPayload;
    const response = NextResponse.json({ user: auth.user }, { status: endpoint === "register" ? 201 : 200 });
    response.cookies.set(TOKEN_COOKIE, auth.token, cookieOptions(auth.expiresIn));
    response.cookies.set(USER_COOKIE, encodeURIComponent(JSON.stringify(auth.user)), cookieOptions(auth.expiresIn));
    return response;
  } catch {
    return NextResponse.json(
      { message: "Impossible de joindre l’API. Vérifiez que Spring Boot est démarré." },
      { status: 503 },
    );
  }
}

export async function proxyToBackend(request: Request, endpoint: string) {
  const cookieStore = await cookies();
  const token = cookieStore.get(TOKEN_COOKIE)?.value;
  if (!token) {
    return NextResponse.json({ message: "Votre session a expiré. Veuillez vous reconnecter." }, { status: 401 });
  }

  try {
    const url = new URL(request.url);
    const upstream = await fetch(`${API_URL}${endpoint}${url.search}`, {
      method: request.method,
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: "application/json",
        ...(request.method !== "GET" && request.method !== "HEAD" ? { "Content-Type": "application/json" } : {}),
      },
      body: request.method === "GET" || request.method === "HEAD" ? undefined : await request.text(),
      cache: "no-store",
    });

    const response = upstream.status === 204
      ? new NextResponse(null, { status: 204 })
      : new NextResponse(await upstream.text(), {
          status: upstream.status,
          headers: { "Content-Type": upstream.headers.get("content-type") ?? "application/json" },
        });

    if (upstream.status === 401) {
      response.cookies.delete(TOKEN_COOKIE);
      response.cookies.delete(USER_COOKIE);
    }
    return response;
  } catch {
    return NextResponse.json(
      { message: "Impossible de joindre l’API. Réessayez dans quelques instants." },
      { status: 503 },
    );
  }
}

export function parseUserCookie(value?: string): User | null {
  if (!value) return null;
  try {
    return JSON.parse(decodeURIComponent(value)) as User;
  } catch {
    return null;
  }
}
