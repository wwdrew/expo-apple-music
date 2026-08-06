import { getMethod, getModule, type ApiMethod } from "./apiCatalog";

export type MethodDocParam = {
  name: string;
  type: string;
  description: string;
  required?: boolean;
};

export type MethodDoc = {
  moduleId: string;
  methodId: string;
  signature: string;
  summary: string;
  description: string;
  params: MethodDocParam[];
  returns: string;
  requiresAuth: boolean;
  platformNotes?: {
    ios?: string;
    android?: string;
    web?: string;
  };
};

type DocOverride = Partial<
  Omit<MethodDoc, "moduleId" | "methodId" | "signature" | "summary">
>;

const AUTH_OPTIONAL = new Set([
  "auth:authorize",
  "auth:setDeveloperToken",
  "auth:checkSubscription",
  "auth:getStorefront",
]);

const OVERRIDES: Record<string, Record<string, DocOverride>> = {
  auth: {
    authorize: {
      description:
        "Starts the Apple Music sign-in flow and stores tokens for library, catalog REST, and playback. On Android and web a MusicKit developer JWT is required before the native or MusicKit JS UI opens.",
      params: [
        {
          name: "developerToken",
          type: "string | undefined",
          description: "MusicKit developer JWT. Required on Android and web.",
        },
        {
          name: "options",
          type: "AndroidAuthorizeOptions | undefined",
          description: "Android-only upsell screen options. Ignored on iOS and web.",
        },
      ],
      returns: "AuthorizeResult — { status, musicUserToken? }",
      requiresAuth: false,
      platformNotes: {
        ios: "Developer JWT optional; native Catalog.search preferred. Store musicUserToken in your app.",
        android: "Developer JWT required. Opens Apple Music app for approval.",
        web: "Developer JWT required. Opens MusicKit authorize popup — allow popups for your origin.",
      },
    },
    setDeveloperToken: {
      description:
        "Store a developer JWT on native/web without opening the Apple Music sign-in UI. Your app supplies the string (e.g. after rotation).",
      params: [
        {
          name: "developerToken",
          type: "string",
          description: "Fresh MusicKit developer JWT from your app.",
          required: true,
        },
      ],
      returns: "void",
      requiresAuth: false,
      platformNotes: {
        ios: "Updates stored JWT for REST fallback paths only.",
        android: "Updates stored JWT for REST and playback.",
        web: "Re-configures MusicKit JS with the new developer token.",
      },
    },
  },
  catalog: {
    search: {
      description:
        "Search the Apple Music store (not the user's library). Returns songs, albums, artists, playlists, and other requested types for the user's storefront.",
      params: [
        { name: "term", type: "string", description: "Search query.", required: true },
        {
          name: "types",
          type: "CatalogSearchType[]",
          description: "Resource types to include (songs, albums, artists, …).",
          required: true,
        },
        {
          name: "options",
          type: "PaginationOptions | undefined",
          description: "Optional limit and offset.",
        },
      ],
      returns: "CatalogSearchResult — grouped arrays per requested type.",
      requiresAuth: true,
    },
  },
  player: {
    setQueue: {
      description:
        "Queues a catalog song, album, playlist, or station for playback. Does not automatically start playback — call Player.play() unless your UI handles transport separately. Station type works on iOS and web; Android permanently rejects station queues (`UNSUPPORTED_PLATFORM` — MusicKit Android has no radio).",
      params: [
        { name: "itemId", type: "string", description: "Catalog resource id.", required: true },
        {
          name: "type",
          type: "MusicItem",
          description: "song | album | playlist | station (station permanently unsupported on Android)",
          required: true,
        },
      ],
      returns: "void",
      requiresAuth: true,
    },
  },
};

function defaultRequiresAuth(moduleId: string, methodId: string): boolean {
  if (moduleId === "auth") return false;
  if (moduleId === "hooks") return true;
  return !AUTH_OPTIONAL.has(`${moduleId}:${methodId}`);
}

function defaultDescription(method: ApiMethod, moduleId: string): string {
  const mod = getModule(moduleId);
  return `${method.summary}${mod ? ` Part of the ${mod.name} module.` : ""}`;
}

export function getMethodDoc(
  moduleId: string,
  methodId: string,
): MethodDoc | undefined {
  const method = getMethod(moduleId, methodId);
  if (!method) return undefined;

  const mod = OVERRIDES[moduleId]?.[methodId];
  const requiresAuth = mod?.requiresAuth ?? defaultRequiresAuth(moduleId, methodId);

  return {
    moduleId,
    methodId,
    signature: method.signature,
    summary: method.summary,
    description: mod?.description ?? defaultDescription(method, moduleId),
    params: mod?.params ?? [],
    returns: mod?.returns ?? "See TypeScript types in @wwdrew/expo-apple-music.",
    requiresAuth,
    platformNotes: mod?.platformNotes,
  };
}
