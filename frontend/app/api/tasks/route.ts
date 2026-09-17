import { proxyToBackend } from "@/lib/server-api";

export async function GET(request: Request) {
  return proxyToBackend(request, "/api/tasks");
}

export async function POST(request: Request) {
  return proxyToBackend(request, "/api/tasks");
}
