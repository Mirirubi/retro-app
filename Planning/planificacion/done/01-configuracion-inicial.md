# Fase 01: Configuración Inicial del Proyecto

⏱️ **Tiempo estimado**: 1-2 días

---

## 🎯 Objetivo

Configurar el proyecto Next.js 16 con todas las herramientas y dependencias necesarias para el desarrollo, siguiendo las mejores prácticas de TypeScript, ESLint y Prettier.

---

## 📋 Tareas

### 1.1 Inicialización de Next.js 16

- [ ] Crear proyecto Next.js 16 con App Router
  ```bash
  npx create-next-app@latest retro-app --typescript --tailwind --app --no-src
  ```

- [ ] Configurar opciones durante la instalación:
  - ✅ TypeScript
  - ✅ ESLint
  - ✅ Tailwind CSS
  - ✅ App Router
  - ❌ src/ directory (usaremos estructura DDD custom)
  - ✅ Import alias (@/*)

---

### 1.2 Configuración de TypeScript Estricto

- [ ] Actualizar `tsconfig.json` con configuración estricta:

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "exactOptionalPropertyTypes": true,
    "forceConsistentCasingInFileNames": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./*"],
      "@retro/*": ["./src/retro/*"],
      "@shared/*": ["./src/shared/*"],
      "@kernel/*": ["./src/kernel/*"],
      "@app/*": ["./app/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

**Explicación de configuraciones clave:**
- `strict: true` - Activa todas las verificaciones estrictas
- `noUncheckedIndexedAccess: true` - Previene acceso inseguro a arrays/objetos
- `noImplicitReturns: true` - Obliga a retornar en todas las ramas
- `exactOptionalPropertyTypes: true` - Diferencia entre `undefined` y propiedad ausente

---

### 1.3 Configuración de ESLint con Reglas SOLID

- [ ] Instalar dependencias de ESLint:
  ```bash
  npm install -D @typescript-eslint/parser @typescript-eslint/eslint-plugin
  ```

- [ ] Configurar `.eslintrc.json`:

```json
{
  "extends": [
    "next/core-web-vitals",
    "plugin:@typescript-eslint/recommended"
  ],
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "project": "./tsconfig.json"
  },
  "rules": {
    "max-lines-per-function": ["warn", 50],
    "max-params": ["warn", 3],
    "complexity": ["warn", 10],
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/explicit-function-return-type": "warn",
    "@typescript-eslint/no-unused-vars": ["error", {
      "argsIgnorePattern": "^_",
      "varsIgnorePattern": "^_"
    }],
    "@typescript-eslint/consistent-type-imports": ["error", {
      "prefer": "type-imports"
    }]
  }
}
```

**Reglas SOLID aplicadas:**
- `max-lines-per-function` - Fomenta Single Responsibility
- `max-params` - Reduce acoplamiento
- `complexity` - Mantiene funciones simples

---

### 1.4 Instalación de Dependencias Base

#### Dependencias de Producción

- [ ] Instalar Supabase:
  ```bash
  npm install @supabase/supabase-js @supabase/ssr
  ```

- [ ] Instalar Drag & Drop:
  ```bash
  npm install @dnd-kit/core @dnd-kit/sortable @dnd-kit/utilities
  ```

- [ ] Instalar UI Components:
  ```bash
  npm install @base-ui/react
  ```

- [ ] Instalar Validación:
  ```bash
  npm install zod
  ```

- [ ] Instalar Utilidades:
  ```bash
  npm install nanoid
  ```

#### Dependencias de Desarrollo

- [ ] Instalar Testing:
  ```bash
  npm install -D vitest @vitest/ui @testing-library/react @testing-library/jest-dom
  ```

- [ ] Instalar Prettier:
  ```bash
  npm install -D prettier eslint-config-prettier
  ```

---

### 1.5 Configuración de Prettier

- [ ] Crear `.prettierrc`:

```json
{
  "semi": true,
  "trailingComma": "all",
  "singleQuote": false,
  "printWidth": 80,
  "tabWidth": 2,
  "useTabs": false,
  "arrowParens": "always",
  "endOfLine": "lf"
}
```

- [ ] Crear `.prettierignore`:

```
node_modules
.next
out
build
dist
coverage
.vercel
*.md
```

- [ ] Añadir script a `package.json`:

```json
{
  "scripts": {
    "format": "prettier --write \"**/*.{ts,tsx,js,jsx,json,css,md}\"",
    "format:check": "prettier --check \"**/*.{ts,tsx,js,jsx,json,css,md}\""
  }
}
```

---

### 1.6 Configuración de Git

- [ ] Actualizar `.gitignore`:

```
# dependencies
/node_modules
/.pnp
.pnp.js

# testing
/coverage

# next.js
/.next/
/out/

# production
/build

# misc
.DS_Store
*.pem

# debug
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# local env files
.env*.local
.env

# vercel
.vercel

# typescript
*.tsbuildinfo
next-env.d.ts

# vitest
coverage/
```

---

## ✅ Criterios de Validación

- [ ] `npm run dev` ejecuta sin errores
- [ ] `npm run lint` no reporta errores
- [ ] `npm run format:check` pasa sin cambios
- [ ] TypeScript compila sin errores
- [ ] Todas las dependencias instaladas correctamente
- [ ] Alias de paths funcionan correctamente

---

## 📝 Notas

- **No crear carpeta `src/`** - Usaremos estructura DDD custom en la raíz
- **Versiones recomendadas**:
  - Next.js: 16.x
  - React: 19.x
  - TypeScript: 5.x
  - Node.js: 20.x o superior

---

## 🔗 Siguiente Fase

[Fase 02: Estructura de Carpetas DDD](./02-estructura-carpetas.md)
