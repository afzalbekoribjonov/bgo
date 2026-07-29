import { FlatCompat } from '@eslint/eslintrc';
import tseslint from 'typescript-eslint';
import eslintConfigPrettier from 'eslint-config-prettier';

const compat = new FlatCompat({ baseDirectory: import.meta.dirname });

const config = [
  { ignores: ['.next/**', 'node_modules/**'] },
  ...compat.extends('next/core-web-vitals'),
  ...tseslint.configs.recommended,
  eslintConfigPrettier,
  {
    rules: {
      // O'zbekcha matnda apostrof (o', g') juda tez-tez ishlatiladi — bu qoida
      // deyarli faqat shu holatlarni belgilaydi, haqiqiy xato emas.
      'react/no-unescaped-entities': 'off',
      // <img> -> next/image o'tishi har bir joyda alohida width/height/vizual
      // tekshiruv talab qiladi — alohida vazifa sifatida qoldiriladi.
      '@next/next/no-img-element': 'off',
    },
  },
];

export default config;
