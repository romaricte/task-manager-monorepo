import { cookies } from "next/headers";
import { NextResponse } from "next/server";
import { parseUserCookie, TOKEN_COOKIE, USER_COOKIE } from "@/lib/server-api";

export async function GET() {
  const cookieStore = await cookies();
  const token = cookieStore.get(TOKEN_COOKIE)?.value;
  const user = parseUserCookie(cookieStore.get(USER_COOKIE)?.value);
  if (!token || !user) {
    const response = NextResponse.json({ message: "Aucune session active" }, { status: 401 });
    response.cookies.delete(TOKEN_COOKIE);
    response.cookies.delete(USER_COOKIE);
    return response;
  }
  return NextResponse.json({ user });
}
