-- Sotuvchi aloqasi faqat telefon orqali — telegram maydoni olib tashlandi.
ALTER TABLE "sellers" DROP COLUMN "telegram";

-- Mahsulot o'lchamlari (S/M/L yoki 42/43...). Bo'sh massiv — o'lchamsiz mahsulot.
ALTER TABLE "products" ADD COLUMN "sizes" TEXT[] DEFAULT ARRAY[]::TEXT[];
