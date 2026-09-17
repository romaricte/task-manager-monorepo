import { afterEach, describe, expect, it, vi } from "vitest";

import { ApiClientError, tasksApi } from "./api";

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("tasksApi", () => {
  it("transmet le statut et la recherche nettoyée", async () => {
    const fetchMock = vi.fn().mockResolvedValue(
      new Response(JSON.stringify([]), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }),
    );
    vi.stubGlobal("fetch", fetchMock);

    await tasksApi.list({ status: "DONE", search: "  rapport  " });

    expect(fetchMock).toHaveBeenCalledWith(
      "/api/tasks?status=DONE&search=rapport",
      expect.objectContaining({ cache: "no-store", credentials: "same-origin" }),
    );
  });

  it("expose les erreurs de validation renvoyées par l'API", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(
        new Response(
          JSON.stringify({
            message: "Données invalides",
            validationErrors: { title: "Le titre est obligatoire" },
          }),
          { status: 400, headers: { "Content-Type": "application/json" } },
        ),
      ),
    );

    const result = tasksApi.create({ title: "", description: "", status: "TODO" });

    await expect(result).rejects.toEqual(
      expect.objectContaining<ApiClientError>({
        name: "ApiClientError",
        message: "Données invalides",
        status: 400,
        validationErrors: { title: "Le titre est obligatoire" },
      }),
    );
  });
});
