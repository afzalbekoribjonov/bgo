-- Nomi bo'yicha erkin-matn qidiruv (market.service.ts'dagi `name::text ILIKE`)
-- hozir hech qanday indeks bilan qoplanmagan — katalog o'sganda har bir
-- qidiruv so'rovi to'liq jadval skanerini talab qiladi. pg_trgm trigram
-- indeksi ILIKE '%...%' naqshlarini ham tezlashtiradi (oddiy B-tree buni
-- qila olmaydi). Indeks ifodasi so'rovdagi bilan AYNAN bir xil (`name::text`)
-- bo'lishi shart — aks holda Postgres uni ishlatmaydi.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS "products_name_trgm_idx" ON "products" USING gin ((name::text) gin_trgm_ops);
