# syntax=docker/dockerfile:1.7

ARG NODE_VERSION=20-bookworm-slim

# -----------------------------------------------------------------------
# base — barcha bosqichlar uchun umumiy poydevor. Debian (Alpine EMAS)
# ataylab — Prisma'ning native query-engine binary'lari glibc bilan
# qurilgan, PrismaService bu yerda oddiy `extends PrismaClient` (driver
# adapter yo'q) — Alpine (musl) aralashtirish "libquery_engine...so:
# cannot open shared object file" xatosining #1 sababi production'da.
# -----------------------------------------------------------------------
FROM node:${NODE_VERSION} AS base
RUN apt-get update && apt-get install -y --no-install-recommends \
      openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
# Root package.json'dagi "packageManager": "pnpm@10.33.0" bilan bir xil
# pnpm versiyasi.
RUN corepack enable && corepack prepare pnpm@10.33.0 --activate
# turbo — pruner bosqichida `pnpm install` ishga tushishidan OLDIN kerak,
# shuning uchun butun workspace'ni o'rnatmasdan global qo'yiladi.
RUN npm install -g turbo@2.9.18
WORKDIR /app

# -----------------------------------------------------------------------
# pruner — monorepo'ni faqat kerakli xizmat + uning ishlatadigan ichki
# paketlariga (@beshariq/nest-auth, @beshariq/nest-bootstrap, kerak
# bo'lsa @beshariq/i18n) qisqartiradi. Boshqa xizmatlar, 5 Next.js
# ilova, Flutter kodi va infra/osrm/data build kontekstiga umuman
# kirmaydi.
# -----------------------------------------------------------------------
FROM base AS pruner
ARG SERVICE
RUN test -n "$SERVICE" || (echo "SERVICE build-arg kerak: auth|gateway|restaurant|order|market|marketplace|support" && exit 1)
COPY . .
RUN turbo prune "@beshariq/${SERVICE}" --docker

# -----------------------------------------------------------------------
# build — qisqartirilgan bog'liqliklarni o'rnatadi, haqiqiy manba kodini
# qo'shadi, Prisma mijozini shu platforma (Linux) uchun generatsiya
# qiladi, turbo bilan quradi.
# -----------------------------------------------------------------------
FROM base AS build
ARG SERVICE

# 1) Faqat bog'liqliklar — keshga qulay qatlam. --ignore-scripts ATAYLAB:
#    out/json/'da faqat package.json manifestlari bor, prisma/schema.prisma
#    hali yo'q — shu xizmatning o'z "postinstall": "prisma generate"
#    skripti shu yerda ishga tushsa, sxema topilmay xato beradi. Prisma
#    generate'ni pastda (3-qadam) manba kodi kelgach QO'LDA chaqiramiz.
COPY --from=pruner /app/out/json/ .
COPY --from=pruner /app/out/pnpm-lock.yaml ./pnpm-lock.yaml
COPY --from=pruner /app/out/pnpm-workspace.yaml ./pnpm-workspace.yaml
RUN --mount=type=cache,id=pnpm-store,target=/root/.local/share/pnpm/store \
    pnpm install --frozen-lockfile --ignore-scripts

# 2) Haqiqiy manba kodi (faqat shu xizmat + uning workspace bog'liqliklari).
COPY --from=pruner /app/out/full/ .
# turbo prune --docker out/full/'ga root darajadagi konfiguratsiya
# fayllarini (turbo.json'dagi globalDependencies) NUSXALAMAYDI — ular
# faqat kesh-hash uchun ishlatiladi, fayl sifatida ko'chirilmaydi. Har
# bir xizmatning tsconfig.json'i "../../tsconfig.base.json"ni extend
# qiladi (experimentalDecorators/emitDecoratorMetadata — Nest
# dekoratorlari uchun SHART) — shu fayl yo'q bo'lsa TypeScript jimgina
# standart sozlamalarga tushib, barcha @Controller/@Post va h.k.
# dekoratorlarida "Unable to resolve signature of method decorator"
# xatosi beradi.
COPY --from=pruner /app/tsconfig.base.json ./tsconfig.base.json

# 3) Prisma mijozi — gateway uchun no-op (schema.prisma yo'q).
RUN if [ -f "services/${SERVICE}/prisma/schema.prisma" ]; then \
      pnpm --filter "@beshariq/${SERVICE}" exec prisma generate; \
    fi

# 4) Qurish. turbo.json'dagi dependsOn: ["^build"] nest-auth/nest-bootstrap/
#    i18n'ni avtomatik oldin quradi.
RUN turbo run build --filter="@beshariq/${SERVICE}"

# -----------------------------------------------------------------------
# runner — yakuniy image. `pnpm prune --prod` ATAYLAB ishlatilmaydi —
# `prisma` CLI (devDependency) ishga tushishda (`prisma migrate deploy`)
# kerak, uni o'chirib tashlash boot'ni sindiradi.
# -----------------------------------------------------------------------
FROM base AS runner
ARG SERVICE
ENV NODE_ENV=production
RUN addgroup --system --gid 1001 beshariq \
    && adduser --system --uid 1001 --gid 1001 beshariq
COPY --from=build --chown=beshariq:beshariq /app /app
COPY --chown=beshariq:beshariq docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh
USER beshariq
WORKDIR /app/services/${SERVICE}
ENTRYPOINT ["/app/docker-entrypoint.sh"]
