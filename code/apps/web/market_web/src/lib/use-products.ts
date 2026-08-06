import { useEffect } from 'react';
import useSWRInfinite from 'swr/infinite';
import { getProducts } from './api';
import type { PagedResult, Product } from './types';

export const PAGE_SIZE = 20;

/**
 * Mahsulot ro'yxatini cheksiz-skroll (sahifalab) yuklaydi va SWR orqali
 * keshlaydi/dedupe qiladi. Kategoriya yoki qidiruv o'zgarsa 1-sahifadan
 * qaytadan boshlaydi (aks holda eski sahifalar yangi filtr ustiga qolib
 * ketishi mumkin — SWRInfinite `size`ni avtomatik qayta o'rnatmaydi).
 */
type ProductsKey = readonly [tag: string, categoryId: string, q: string, page: number];

export function useProducts(categoryId: string | null, q: string) {
  const getKey = (
    pageIndex: number,
    previousPageData: PagedResult<Product> | null,
  ): ProductsKey | null => {
    if (previousPageData && pageIndex * PAGE_SIZE >= previousPageData.total) return null;
    return ['market-products', categoryId ?? '', q, pageIndex + 1] as const;
  };

  const { data, error, size, setSize, isLoading, isValidating, mutate } = useSWRInfinite<
    PagedResult<Product>
  >(
    getKey,
    ([, cat, query, page]: ProductsKey) =>
      getProducts({
        categoryId: cat || undefined,
        q: query || undefined,
        page,
        pageSize: PAGE_SIZE,
      }),
    { revalidateFirstPage: false },
  );

  useEffect(() => {
    setSize(1);
  }, [categoryId, q, setSize]);

  const items = data ? data.flatMap((p) => p.items) : [];
  const total = data?.[data.length - 1]?.total ?? 0;
  const isReachingEnd = data ? items.length >= total : false;
  const isLoadingInitial = !data && !error;
  const isLoadingMore = isLoading || (size > 0 && !!data && typeof data[size - 1] === 'undefined');

  return {
    items,
    total,
    error,
    isLoadingInitial,
    isLoadingMore: !!isLoadingMore,
    isValidating,
    isReachingEnd,
    loadMore: () => setSize(size + 1),
    retry: () => mutate(),
  };
}
