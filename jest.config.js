/** @type {import('jest').Config} */
module.exports = {
  testEnvironment: 'node',
  testMatch: [
    '<rootDir>/src/api/__tests__/**/*.test.ts',
    '<rootDir>/src/bridge/__tests__/**/*.test.ts',
    '<rootDir>/src/mappers/__tests__/**/*.test.ts',
    '<rootDir>/src/modules/__tests__/**/*.test.ts',
    '<rootDir>/src/rest/__tests__/**/*.test.ts',
    '<rootDir>/src/web/__tests__/**/*.test.ts',
  ],
  transform: {
    '^.+\\.tsx?$': [
      'ts-jest',
      {
        tsconfig: {
          module: 'commonjs',
          esModuleInterop: true,
          resolveJsonModule: true,
          types: ['node', 'jest'],
        },
      },
    ],
  },
};
