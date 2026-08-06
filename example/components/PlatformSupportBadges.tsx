import { StyleSheet, Text, View } from "react-native";
import {
  activePlatformGaps,
  type PlatformGapId,
} from "../lib/platform-support";
import { theme } from "../lib/theme";

type Props = {
  gaps: PlatformGapId[];
};

/** Shows active platform-gap badges for the current OS. */
export function PlatformSupportBadges({ gaps }: Props) {
  const active = activePlatformGaps(...gaps);
  if (active.length === 0) return null;

  return (
    <View style={styles.wrap}>
      {active.map((gap) => (
        <View key={gap.id} style={styles.badge}>
          <Text style={styles.label}>{gap.label}</Text>
          <Text style={styles.detail}>{gap.detail}</Text>
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { gap: 8, marginBottom: 12 },
  badge: {
    borderWidth: 1,
    borderColor: theme.border,
    backgroundColor: theme.accentBg,
    paddingHorizontal: 10,
    paddingVertical: 8,
  },
  label: {
    fontSize: 12,
    fontWeight: "600",
    color: theme.accent,
    marginBottom: 2,
  },
  detail: { fontSize: 12, color: theme.muted, lineHeight: 16 },
});
