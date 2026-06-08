#!/usr/bin/env node
/**
 * Run `npm pack` and fail if the tarball contains paths we never ship.
 */
import { execSync } from 'node:child_process';
import { readFileSync, unlinkSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(fileURLToPath(new URL('..', import.meta.url)));
const pkg = JSON.parse(readFileSync(join(root, 'package.json'), 'utf8'));
const tgzName = `${pkg.name.replace('@', '').replace('/', '-')}-${pkg.version}.tgz`;
const tgzPath = join(root, tgzName);

const required = [
  'package/plugin/build/index.js',
  'package/plugin/build/index.d.ts',
  'package/plugin/build/with-expo-apple-music.js',
  'package/app.plugin.js',
];

const forbidden = [
  /^package\/example\//,
  /^package\/docs\//,
  /^package\/scripts\//,
  /^package\/src\//,
  /^package\/android\/build\//,
  /^package\/android\/\.gradle\//,
  /^package\/android\/src\/test\//,
  /^package\/android\/src\/androidTest\//,
  /^package\/plugin\/src\//,
  /^package\/fixtures\//,
  /^package\/__tests__\//,
  /^package\/\.github\//,
];

try {
  execSync('npm pack --silent', { cwd: root, stdio: 'pipe' });
  const listing = execSync(`tar -tzf ${JSON.stringify(tgzName)}`, {
    cwd: root,
    encoding: 'utf8',
  });
  const paths = listing.trim().split('\n').filter(Boolean);
  const missing = required.filter((p) => !paths.includes(p));
  if (missing.length > 0) {
    console.error('npm pack tarball is missing required paths:\n');
    for (const p of missing) {
      console.error(`  ${p}`);
    }
    process.exit(1);
  }
  const bad = paths.filter((p) => forbidden.some((re) => re.test(p)));
  if (bad.length > 0) {
    console.error('npm pack tarball includes forbidden paths:\n');
    for (const p of bad.slice(0, 30)) {
      console.error(`  ${p}`);
    }
    if (bad.length > 30) {
      console.error(`  … and ${bad.length - 30} more`);
    }
    process.exit(1);
  }
  const sizeMb = (readFileSync(tgzPath).length / (1024 * 1024)).toFixed(2);
  console.log(`OK: ${paths.length} paths, ${sizeMb} MB — ${tgzName}`);
} finally {
  try {
    unlinkSync(tgzPath);
  } catch {
    /* ignore */
  }
}
