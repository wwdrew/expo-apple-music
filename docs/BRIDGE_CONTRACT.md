# Bridge contract (mapper parity)

The **bridge contract** is the set of plain objects returned to JavaScript (`Song`, `Playlist`, `Rating`, …). Native code uses **adapters** to map Apple Music API JSON (or MusicKit types on iOS) into that shape.

**Single source of truth for REST JSON mapping:**

| Platform | Adapter | Runtime |
| -------- | ------- | ------- |
| TypeScript / Web | `src/mappers/apple-music-json-mapper.ts` | Web REST |
| Android | `AppleMusicJsonMapper.kt` | `*RestClient` via `AppleMusicRestStack` |
| iOS (REST) | `RestJsonMapper.swift` | `AppleMusicRestClient` |
| iOS (native) | `MusicItemMapper.swift` | MusicKit types — separate adapter, same field rules |

Field rules: [PLATFORM_IMPLEMENTATION.md](./PLATFORM_IMPLEMENTATION.md#bridge-contract-parity-rules), [RESOURCE_IDS.md](./RESOURCE_IDS.md).

**Expo bridge method names** (native `MusicModule.*` ↔ public `Auth` / `Catalog` / …): `src/bridge/bridge-methods.ts`. List endpoints register via domain bridge modules (`ios/bridge/`, `android/.../bridge/`, `src/bridge/handlers/`). Response envelope keys: `BridgeResponses` on each platform.

---

## Fixture-driven tests

Golden files live under `fixtures/`:

| Path | Role |
| ---- | ---- |
| `fixtures/*.json` | Sample **API** resource or envelope (input) |
| `fixtures/expected/*.json` | Expected **bridge** object (output) |

**TypeScript:** `src/mappers/__tests__/bridge-contract.test.ts` runs every case in `BRIDGE_CONTRACT_CASES` (`bridge-contract.ts`).

**Android:** `BridgeContractTest.kt` loads the same API inputs from `android/src/test/resources/fixtures/`.

Sync inputs before Android unit tests:

```sh
yarn sync:fixtures
```

---

## Adding a contract case

1. Add `fixtures/my-input.json` (API shape).
2. Add `fixtures/expected/my-output.json` (bridge shape).
3. Register in `src/mappers/__tests__/bridge-contract.ts` → `BRIDGE_CONTRACT_CASES`.
4. Implement in `apple-music-json-mapper.ts` and `AppleMusicJsonMapper.kt` (and `RestJsonMapper.swift` if REST-only).
5. Mirror assertions in `BridgeContractTest.kt`.
6. Run `yarn sync:fixtures` and `yarn test`.

---

## `mapRating` (consolidated)

Ratings use an API **envelope** (`{ data: [{ id, attributes: { value } }] }`), not a single resource. Mapping lives in:

- `mapRating()` in `apple-music-json-mapper.ts`
- `AppleMusicJsonMapper.mapRating()` in Kotlin
- `RestJsonMapper.mapRating()` in Swift (iOS REST)

Web and Android API clients call the shared TS/Kotlin mappers — not duplicate private helpers.

---

## iOS native (MusicKit)

`MusicItemMapper` is not covered by JSON fixtures (MusicKit types, not API JSON). When changing bridge fields, update native mapper + docs and verify on device. Future work: XCTest loading exported JSON snapshots.

---

## Related

- [PLATFORM_IMPLEMENTATION.md](./PLATFORM_IMPLEMENTATION.md)
- [TYPES.md](./TYPES.md)
- [docs/scratch/ARCHITECTURE_DEEPENING.md](./scratch/ARCHITECTURE_DEEPENING.md) — item 1
