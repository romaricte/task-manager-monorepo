import { NextResponse } from "next/server";
import { proxyToBackend } from "@/lib/server-api";

type Context = { params: Promise<{ id: string }> };

async function endpoint(context: Context) {
  const { id } = await context.params;
  if (!/^\d+$/.test(id)) return null;
  return `/api/tasks/${id}`;
}

export async function PUT(request: Request, context: Context) {
  const path = await endpoint(context);
  return path
    ? proxyToBackend(request, path)
    : NextResponse.json({ message: "Identifiant de tâche invalide" }, { status: 400 });
}

export async function DELETE(request: Request, context: Context) {
  const path = await endpoint(context);
  return path
    ? proxyToBackend(request, path)
    : NextResponse.json({ message: "Identifiant de tâche invalide" }, { status: 400 });
}
