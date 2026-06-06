# Architecture deepening — scratch backlog

Work through these one at a time. Vocabulary: **module**, **interface**, **seam**, **depth**, **locality**, **adapter**, **leverage** ([improve-codebase-architecture skill](https://github.com/wwdrew/expo-apple-music)).

Domain terms: [CONTEXT.md](../../CONTEXT.md) (Catalog / Library / History / Auth).

Suggested order at bottom. No ADRs in repo yet — record decisions when you reject a candidate for a load-bearing reason.

---

## 1. Bridge mapper contract (four parallel adapters)

**Status:** [ ] not started · [ ] in progress · [x] done

**Files**

- `ios/MusicItemMapper.swift`
- `ios/RestJsonMapper.swift`
- `android/src/main/java/expo/modules/applemusic/AppleMusicJsonMapper.kt`
- `src/mappers/apple-music-json-mapper.ts`
- `fixtures/*.json`, `android/src/test/resources/fixtures/`
- `docs/PLATFORM_IMPLEMENTATION.md`, `docs/RESOURCE_IDS.md`

**Problem**

Public **interface** is plain `Song` / `Playlist` objects; **implementation** is four mappers synced by hand. `mapRating` triplicated outside main mappers. Tests cover only a slice of TS/Kotlin mappers.

**Solution**

Fixture-driven bridge mapping as one deep module: golden JSON → expected bridge objects; each platform mapper is an **adapter** at that **seam**. Consolidate ratings/recommendations mapping into the same contract.

**Benefits**

- **Leverage:** one contract change, all platforms
- **Locality:** playback id, ms durations, library prefixes in one place
- **Tests:** table-driven parity; **deletion test** passes for mapper layer

**Notes**

- 2026-05-20: `docs/BRIDGE_CONTRACT.md`, `fixtures/expected/`, `bridge-contract.test.ts`, `BridgeContractTest.kt`, `mapRating` consolidated in TS/Kotlin; `yarn sync:fixtures`.

---

## 2. Shallow TypeScript domain modules

**Status:** [ ] not started · [ ] in progress · [x] done

**Files**

- `src/modules/catalog.ts`, `library.ts`, `history.ts`, `auth.ts`, `player.ts`, `recommendations.ts`, `library-mutations.ts`
- `src/native-module.ts`, `src/index.ts`

**Problem**

Each domain **module** is `MusicModule.*` + cast. **Deletion test fails** — removing `catalog.ts` forces callers to know bridge names like `catalogSearch`. Exception: `Ratings` + `normalizeResourceIds` already has real **locality**.

**Solution**

Either **(a)** deepen JS: ID normalization, pagination defaults, `AppleMusicError` mapping, capability guards — or **(b)** delete pass-through layer and export one typed native **adapter** (codegen from bridge matrix).

**Benefits**

- **Locality** for what Catalog/Library mean in JS
- **Tests:** pure TS without simulators
- Aligns with v1 `api/` direction in `docs/V1_PLAN.md` (not built yet)

**Notes**

- 2026-05-20: Option (a) — `src/api/` seam (`pagination`, `call-native`, `library-ids`); all domain modules use `callNative` + `paginationBridgePayload`; library-scoped calls validate `i.`/`l.`/`p.` prefixes; unit tests in `src/api/__tests__/`.

---

## 3. iOS Catalog transport seam (MusicKit vs REST)

**Status:** [ ] not started · [ ] in progress · [x] done

**Files**

- `ios/CatalogService.swift`
- `ios/MusicItemMapper.swift`, `ios/RestJsonMapper.swift`
- `ios/AppleMusicRestClient.swift`, `ios/MusicKitAuthStorage.swift`

**Problem**

**Catalog** **implementation** branches on token storage (native search vs REST), two mappers, 404 heuristics in one file. Transport leaks into domain **module**. Android/Web are REST-only for catalog.

**Solution**

Small **Catalog** **interface** (“search store”) with two **adapters**: native MusicKit and REST (developer JWT). Factory picks adapter from Auth session state — not inside `search()`.

**Benefits**

- **Locality** for the dual path fixed during iOS setup work
- **Tests:** mock each adapter separately
- REST **adapter** can align with Android catalog paths

**Notes**

- 2026-05-20: `CatalogSearchStore` protocol; `MusicKitCatalogSearchStore` / `RestCatalogSearchStore` adapters; `CatalogSearchStoreFactory` picks transport from `MusicKitAuthStorage.hasDeveloperToken()`; `CatalogService.search` delegates; 404 heuristics live in MusicKit adapter.

---

## 4. Monolithic REST on Android and Web

**Status:** [ ] not started · [ ] in progress · [x] done

**Files**

- `android/.../AppleMusicApiClient.kt` (~687 lines)
- `src/web/WebAppleMusicApiClient.ts` (~507 lines)
- `AndroidCatalogService.kt`, `AndroidLibraryService.kt`, `AndroidRatingsService.kt` (thin delegates)

**Problem**

Android domain **modules** are pass-through to one deep client. **Deletion test fails** for `AndroidCatalogService`. Hard to unit-test Catalog without mocking entire HTTP layer.

**Solution**

Slice by CONTEXT domains: **Catalog**, **Library**, **History**, **Auth** — narrow **interfaces**, shared HTTP **adapter** underneath. Web mirrors same slices.

**Benefits**

- **Leverage:** shared transport, domain-sized **interfaces**
- **Tests:** Catalog-only fakes
- Matches v1 domain API shape

**Notes**

- 2026-05-20: Full REST slice — `AppleMusicRestTransport` + domain clients (`Catalog`, `Library`, `History`, `Ratings`, `LibraryMutations`, `Recommendations`, `Storefront`) via `AppleMusicRestStack`. Removed monolithic `AppleMusicApiClient.kt`. Android services depend on domain clients only. TS: `src/rest/*` + `createAppleMusicRestStack`; `WebAppleMusicApiClient` is a thin facade.

---

## 5. History seam (naming + transport split)

**Status:** [ ] not started · [ ] in progress · [x] done

**Files**

- `src/modules/history.ts`
- `ios/LibraryService.swift`, `ios/HistoryService.swift`
- `android/.../AndroidLibraryService.kt` (history endpoints live here)
- `ios/ExpoAppleMusicModule.swift` (`getTracksFromLibrary`, etc.)

**Problem**

Public API is **History**; bridge uses legacy names. iOS: some History via native MusicKit in **Library** code, some via REST in **HistoryService**. Android: no native **History** **module** — all under Library client.

**Solution**

One **History** native **module** per platform matching `History.*` in CONTEXT; hide MusicKit vs REST inside. Alias/rename legacy bridge methods.

**Benefits**

- **Locality** for listening-history changes
- Stops Library vs History confusion for humans/agents

**Notes**

- 2026-05-20: Bridge `getRecentlyPlayedResources` (renamed from `getTracksFromLibrary`); iOS `HistoryService` owns MusicKit + REST history; Android `AndroidHistoryService` + `HistoryRestClient` (incl. recently-added); library services library-only.

---

## 6. Auth session seam (tokens + storefront)

**Status:** [ ] not started · [ ] in progress · [x] done

**Files**

- `ios/MusicKitAuthStorage.swift`, `android/.../MusicKitAuthStorage.kt`
- `ios/AppleMusicRestClient.swift`, `ios/CatalogService.swift`, `ios/SubscriptionService.swift`
- `docs/AUTH.md`, `docs/IOS_SETUP.md`

**Problem**

No single **interface** for “what credentials exist?” Token checks scattered; **Catalog** transport and REST routing depend on storage details in multiple files.

**Solution**

**Authenticated session** **module**: developer JWT, music user token, storefront — populated by `Auth.authorize()`. REST and Catalog **adapters** depend only on session.

**Benefits**

- **Leverage:** documents iOS optional JWT vs Android required
- **Tests:** inject session without UserDefaults
- Clearer “why search 404’d” story

**Notes**

- 2026-05-20: `AuthenticatedSession` + `AuthenticatedSessionCache` on iOS/Android; `MusicKitAuthStorage` persists only; REST, catalog search factory, storefront, playback, and API client read session instead of scattered token checks.

---

## 7. Flat Expo bridge interface (~40 methods × 3 platforms)

**Status:** [ ] not started · [ ] in progress · [x] done

**Files**

- `ios/ExpoAppleMusicModule.swift`
- `android/.../ExpoAppleMusicModule.kt`
- `src/ExpoAppleMusicModule.web.ts`
- `example/catalog/apiCatalog.ts` (reference surface)

**Problem**

Wide `MusicModule` **seam**: pagination unpacking, response envelopes, legacy names duplicated per platform. High ceremony, low domain **leverage**.

**Solution**

Group bridge by domain with shared envelope/pagination helpers — or codegen from `PLATFORM_IMPLEMENTATION.md` / api catalog.

**Benefits**

- **Locality** when adding endpoints
- Fewer iOS/Android/Web drift bugs

**Notes**

- 2026-05-20: `src/bridge/bridge-methods.ts` manifest; `BridgeResponses` + domain registration (`ios/bridge/`, `android/.../bridge/`, `src/bridge/handlers/`); shared `BridgePagination` on iOS; web module delegates via `createWebBridgeHandlers`.

---

## 8. Web duplicates native bridge instead of shared JS REST depth

**Status:** [ ] not started · [ ] in progress · [x] done

**Files**

- `src/ExpoAppleMusicModule.web.ts`
- `src/web/WebAppleMusicApiClient.ts`, `music-kit-api.ts`
- `src/mappers/apple-music-json-mapper.ts`

**Problem**

Web mirrors flat native **interface**, re-implements REST in `WebAppleMusicApiClient`. TS mapper unused by iOS native path.

**Solution**

Web **Catalog** / **Library** / **History** call shared TS REST **adapter** (Android paths); MusicKit JS only for Auth + Player **seams**.

**Benefits**

- **Leverage:** one REST path for Android + Web
- **Tests:** mapper + REST once in TS

**Notes**

- 2026-05-20: All Web data REST goes through `src/rest/*` domain clients; MusicKit JS only in `WebAppleMusicRestTransport` + Auth/Player seams. `WebAppleMusicApiClient` delegates to stack (bridge-compatible facade).

---

## Suggested order

| Order | # | Rationale |
| ----- | - | --------- |
| 1 | **1** | Prevents silent cross-platform drift before 1.0 |
| 2 | **3** | Small, contained; iOS pain is fresh |
| 3 | **6** | Clarifies Auth + Catalog search behaviour |
| 4 | **4** + **8** | Larger; pair Android/Web REST slice |
| 5 | **2** | Depends on v1 `api/` decision |
| 6 | **5** | Naming + bridge cleanup |
| 7 | **7** | Pays off as API surface grows |

---

## Session log

| Date | # | Outcome |
| ---- | - | ------- |
| 2026-05-20 | 3 | Catalog search transport seam: protocol + MusicKit/REST adapters + factory |
| 2026-05-20 | 6 | Auth session: `AuthenticatedSession` + storefront cache; REST/catalog depend on session |
| 2026-05-20 | 4 + 8 | Catalog REST slice: shared transport + `CatalogRestClient` (Android + TS/Web) |
| 2026-05-20 | 4 + 8 | Completed: all domain REST clients + `AppleMusicRestStack`; removed `AppleMusicApiClient.kt` |
| 2026-05-20 | 2 | JS domain depth: `src/api/` pagination + `callNative` + library id validation; modules wired |
| 2026-05-20 | 5 | History seam: native History services; bridge `getRecentlyPlayedResources`; REST recently-added on History client |
| 2026-05-20 | 7 | Domain-grouped Expo bridge: manifest, envelopes, per-domain register/handlers on iOS/Android/Web |
