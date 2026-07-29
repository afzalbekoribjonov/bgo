/** Haydovchi daromadi xulosasi (bitta vertikal bo'yicha). */
export interface EarningsSummary {
  count: number; // yakunlangan ishlar soni
  earning: number; // jami daromad (so'm)
  todayEarning: number; // bugungi daromad (so'm)
  todayCount: number; // bugun yakunlangan ishlar soni
  activeCount: number; // hozir bajarilayotgan ishlar
}

/**
 * Ish ro'yxatidan daromad xulosasini hisoblaydi.
 * isDone — yakunlangan (pul sanaladigan), isActive — hozir bajarilayotgan.
 */
export function summarizeEarnings<T>(
  items: T[],
  isDone: (i: T) => boolean,
  isActive: (i: T) => boolean,
  earningOf: (i: T) => number,
  doneAtOf: (i: T) => string, // yakunlanish vaqti (updatedAt)
): EarningsSummary {
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);

  let count = 0;
  let earning = 0;
  let todayEarning = 0;
  let todayCount = 0;
  let activeCount = 0;

  for (const item of items) {
    if (isDone(item)) {
      count += 1;
      const e = earningOf(item);
      earning += e;
      if (new Date(doneAtOf(item)) >= todayStart) {
        todayEarning += e;
        todayCount += 1;
      }
    } else if (isActive(item)) {
      activeCount += 1;
    }
  }
  return { count, earning, todayEarning, todayCount, activeCount };
}

/** Bir nechta vertikal xulosasini jamlaydi. */
export function combineEarnings(parts: EarningsSummary[]): EarningsSummary {
  return parts.reduce(
    (acc, p) => ({
      count: acc.count + p.count,
      earning: acc.earning + p.earning,
      todayEarning: acc.todayEarning + p.todayEarning,
      todayCount: acc.todayCount + p.todayCount,
      activeCount: acc.activeCount + p.activeCount,
    }),
    { count: 0, earning: 0, todayEarning: 0, todayCount: 0, activeCount: 0 },
  );
}
