import * as fs from 'node:fs';
import * as path from 'node:path';
import { BRIDGE_METHODS } from '../bridge-methods';

/** Parse Expo `AsyncFunction("name")` / `Function("name")` registrations from Swift source. */
export function parseIosBridgeRegistrationNames(swiftSource: string): string[] {
  const pattern = /\b(?:AsyncFunction|Function)\("([^"]+)"\)/g;
  const names: string[] = [];
  let match: RegExpExecArray | null;
  while ((match = pattern.exec(swiftSource)) !== null) {
    names.push(match[1]);
  }
  return names;
}

describe('BRIDGE_METHODS ↔ iOS ExpoBridgeRegistrations', () => {
  it('registers exactly the 50 manifest nativeNames', () => {
    const registrationsPath = path.join(
      __dirname,
      '../../../ios/bridge/ExpoBridgeRegistrations.swift',
    );
    const source = fs.readFileSync(registrationsPath, 'utf8');
    const registered = parseIosBridgeRegistrationNames(source);
    const expected = BRIDGE_METHODS.map((m) => m.nativeName);

    expect(expected).toHaveLength(50);
    expect(registered).toHaveLength(50);
    expect([...registered].sort()).toEqual([...expected].sort());
    expect(new Set(registered).size).toBe(registered.length);
  });
});
