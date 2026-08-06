import { Platform, Pressable, StyleSheet, Text, View } from "react-native";
import { useApp } from "../context/AppContext";
import { isAuthorized, needsDeveloperToken } from "../lib/auth";
import { theme } from "../lib/theme";

type ReadinessRow = { label: string; ok: boolean; detail?: string };

export function AuthCard() {
  const { authStatus, hasStoredSession, musicUserToken, devToken, authorize } = useApp();
  const authorized = isAuthorized(authStatus);
  const tokenRequired = needsDeveloperToken(Platform.OS);
  const hasDevToken = Boolean(devToken?.trim());
  const canAuthorize = !tokenRequired || hasDevToken;

  const readiness: ReadinessRow[] = [
    {
      label: "Developer JWT",
      ok: hasDevToken,
      detail: hasDevToken
        ? "Loaded from EXPO_PUBLIC_APPLE_MUSIC_DEVELOPER_TOKEN"
        : tokenRequired
          ? "Required on Android/web — set example/.env.local (docs/CLI.md)"
          : "Optional on iOS; recommended for REST catalog/search fallback",
    },
    {
      label: "Authorized",
      ok: authorized,
      detail: authorized ? authStatus : `Status: ${authStatus}`,
    },
    {
      label: "Music user token",
      ok: Boolean(musicUserToken),
      detail: musicUserToken
        ? "Ready for Library / History / Ratings / Player.playLibrary*"
        : "Call Authorize — token is stored in the example app only",
    },
  ];

  return (
    <View style={styles.wrap}>
      <Text style={styles.heading}>Apple Music</Text>
      <Text style={styles.status}>
        Status: <Text style={styles.statusValue}>{authStatus}</Text>
      </Text>
      {hasStoredSession ? (
        <Text style={styles.hint}>Session restored from app storage.</Text>
      ) : null}

      <Text style={styles.readinessTitle}>Auth readiness</Text>
      {readiness.map((row) => (
        <View key={row.label} style={styles.readinessRow}>
          <Text style={[styles.readinessMark, row.ok ? styles.ok : styles.pending]}>
            {row.ok ? "✓" : "○"}
          </Text>
          <View style={styles.readinessBody}>
            <Text style={styles.readinessLabel}>{row.label}</Text>
            {row.detail ? <Text style={styles.readinessDetail}>{row.detail}</Text> : null}
          </View>
        </View>
      ))}

      {Platform.OS === "web" ? (
        <Text style={styles.hint}>
          Web: allow popups for localhost. See docs/AUTH.md if authorize fails after the popup.
        </Text>
      ) : null}
      <Pressable
        style={[styles.button, (!canAuthorize || authorized) && styles.buttonMuted]}
        onPress={() => void authorize()}
        disabled={!canAuthorize}
      >
        <Text style={styles.buttonText}>{authorized ? "Re-authorize" : "Authorize"}</Text>
      </Pressable>
      {!canAuthorize ? (
        <Text style={styles.blocked}>
          Add a developer JWT before authorizing on {Platform.OS}.
        </Text>
      ) : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: {
    backgroundColor: theme.card,
    borderRadius: 10,
    padding: 14,
    marginBottom: 16,
    borderWidth: 1,
    borderColor: theme.border,
  },
  heading: { fontSize: 16, fontWeight: "700", color: theme.text, marginBottom: 6 },
  status: { fontSize: 14, color: theme.text },
  statusValue: { fontWeight: "600", color: theme.accent },
  hint: { fontSize: 11, color: theme.muted, marginTop: 6, lineHeight: 16 },
  readinessTitle: {
    marginTop: 12,
    marginBottom: 6,
    fontSize: 12,
    fontWeight: "700",
    color: theme.text,
    textTransform: "uppercase",
    letterSpacing: 0.4,
  },
  readinessRow: { flexDirection: "row", alignItems: "flex-start", marginBottom: 8 },
  readinessMark: { width: 18, fontSize: 13, fontWeight: "700", marginTop: 1 },
  ok: { color: theme.accent },
  pending: { color: theme.muted },
  readinessBody: { flex: 1 },
  readinessLabel: { fontSize: 13, fontWeight: "600", color: theme.text },
  readinessDetail: { fontSize: 11, color: theme.muted, marginTop: 2, lineHeight: 15 },
  button: {
    marginTop: 12,
    backgroundColor: theme.accent,
    borderRadius: 8,
    paddingVertical: 10,
    alignItems: "center",
  },
  buttonMuted: { opacity: 0.85 },
  buttonText: { color: "#fff", fontWeight: "600", fontSize: 15 },
  blocked: { fontSize: 11, color: theme.muted, marginTop: 8 },
});
