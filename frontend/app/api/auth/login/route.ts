import { authenticate } from "@/lib/server-api";

export async function POST(request: Request) {
  return authenticate(request, "login");
}
