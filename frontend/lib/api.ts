import type { ApiErrorBody, Task, TaskInput, TaskStatus, User } from "./types";

export class ApiClientError extends Error {
  constructor(
    message: string,
    public readonly status: number,
    public readonly validationErrors?: Record<string, string>,
  ) {
    super(message);
    this.name = "ApiClientError";
  }
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(path, {
    ...init,
    credentials: "same-origin",
    headers: {
      Accept: "application/json",
      ...(init?.body ? { "Content-Type": "application/json" } : {}),
      ...init?.headers,
    },
  });

  if (response.status === 204) {
    return undefined as T;
  }

  const body = (await response.json().catch(() => null)) as (T & ApiErrorBody) | null;
  if (!response.ok) {
    throw new ApiClientError(
      body?.message ?? "Une erreur inattendue est survenue",
      response.status,
      body?.validationErrors ?? undefined,
    );
  }
  return body as T;
}

export const authApi = {
  register: (payload: { name: string; email: string; password: string }) =>
    request<{ user: User }>("/api/auth/register", {
      method: "POST",
      body: JSON.stringify(payload),
    }),
  login: (payload: { email: string; password: string }) =>
    request<{ user: User }>("/api/auth/login", {
      method: "POST",
      body: JSON.stringify(payload),
    }),
  session: () => request<{ user: User }>("/api/auth/session", { cache: "no-store" }),
  logout: () => request<void>("/api/auth/logout", { method: "POST" }),
};

export const tasksApi = {
  list: ({ status, search }: { status?: TaskStatus; search?: string } = {}) => {
    const params = new URLSearchParams();
    if (status) params.set("status", status);
    if (search?.trim()) params.set("search", search.trim());
    const query = params.toString();
    return request<Task[]>(`/api/tasks${query ? `?${query}` : ""}`, { cache: "no-store" });
  },
  create: (payload: TaskInput) =>
    request<Task>("/api/tasks", { method: "POST", body: JSON.stringify(payload) }),
  update: (id: number, payload: TaskInput) =>
    request<Task>(`/api/tasks/${id}`, { method: "PUT", body: JSON.stringify(payload) }),
  remove: (id: number) => request<void>(`/api/tasks/${id}`, { method: "DELETE" }),
};
