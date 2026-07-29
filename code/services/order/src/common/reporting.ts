export type ReportPeriod = 'today' | 'week' | 'month';

export interface VerticalDay {
  date: string; // YYYY-MM-DD (mahalliy)
  orders: number;
  revenue: number;
  profit: number;
}

export interface VerticalReport {
  count: number; // davr ichidagi barcha (har qanday holat)
  delivered: number; // yakunlangan
  cancelled: number;
  revenue: number;
  profit: number;
  daily: VerticalDay[];
}

export interface VerticalStats {
  count: number; // yakunlangan ishlar soni
  revenue: number;
  profit: number;
}

export function periodDays(period: ReportPeriod): number {
  return period === 'today' ? 1 : period === 'week' ? 7 : 30;
}

/** Davr boshlanishi (bugundan ortga days-1 kun). */
export function periodStart(period: ReportPeriod): Date {
  const from = new Date();
  from.setHours(0, 0, 0, 0);
  from.setDate(from.getDate() - (periodDays(period) - 1));
  return from;
}

/** Mahalliy (TZ) sana kaliti YYYY-MM-DD. */
export function localDateKey(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

interface ReportOpts<T> {
  createdAtOf: (i: T) => string;
  isDone: (i: T) => boolean;
  isCancelled: (i: T) => boolean;
  revenueOf: (i: T) => number;
  profitOf: (i: T) => number;
}

/** Bitta vertikal uchun davr hisoboti (kunlik chelaklar + xulosa). */
export function buildVerticalReport<T>(
  items: T[],
  period: ReportPeriod,
  opts: ReportOpts<T>,
): VerticalReport {
  const days = periodDays(period);
  const from = periodStart(period);
  const fromTs = from.getTime();

  const daily = new Map<string, VerticalDay>();
  for (let i = 0; i < days; i++) {
    const d = new Date(from);
    d.setDate(from.getDate() + i);
    const key = localDateKey(d);
    daily.set(key, { date: key, orders: 0, revenue: 0, profit: 0 });
  }

  let count = 0;
  let delivered = 0;
  let cancelled = 0;
  let revenue = 0;
  let profit = 0;

  for (const item of items) {
    const created = new Date(opts.createdAtOf(item));
    if (created.getTime() < fromTs) continue;
    count += 1;
    const bucket = daily.get(localDateKey(created));
    if (bucket) bucket.orders += 1;
    if (opts.isDone(item)) {
      delivered += 1;
      const rev = opts.revenueOf(item);
      const pf = opts.profitOf(item);
      revenue += rev;
      profit += pf;
      if (bucket) {
        bucket.revenue += rev;
        bucket.profit += pf;
      }
    } else if (opts.isCancelled(item)) {
      cancelled += 1;
    }
  }

  return {
    count,
    delivered,
    cancelled,
    revenue,
    profit,
    daily: Array.from(daily.values()),
  };
}

/**
 * Ixtiyoriy sana oralig'i uchun hisobot (istalgan kun/oy/davr) — `buildVerticalReport`
 * bilan bir xil natija shakli, lekin "bugundan orqaga N kun" emas, aniq [from,to].
 */
export function buildVerticalReportRange<T>(
  items: T[],
  from: Date,
  to: Date,
  opts: ReportOpts<T>,
): VerticalReport {
  const fromTs = from.getTime();
  const toTs = to.getTime();

  const daily = new Map<string, VerticalDay>();
  for (let t = new Date(from).setHours(0, 0, 0, 0); t <= toTs; t += 86_400_000) {
    const key = localDateKey(new Date(t));
    daily.set(key, { date: key, orders: 0, revenue: 0, profit: 0 });
  }

  let count = 0;
  let delivered = 0;
  let cancelled = 0;
  let revenue = 0;
  let profit = 0;

  for (const item of items) {
    const created = new Date(opts.createdAtOf(item));
    const ts = created.getTime();
    if (ts < fromTs || ts > toTs) continue;
    count += 1;
    const bucket = daily.get(localDateKey(created));
    if (bucket) bucket.orders += 1;
    if (opts.isDone(item)) {
      delivered += 1;
      const rev = opts.revenueOf(item);
      const pf = opts.profitOf(item);
      revenue += rev;
      profit += pf;
      if (bucket) {
        bucket.revenue += rev;
        bucket.profit += pf;
      }
    } else if (opts.isCancelled(item)) {
      cancelled += 1;
    }
  }

  return {
    count,
    delivered,
    cancelled,
    revenue,
    profit,
    daily: Array.from(daily.values()),
  };
}

/** Bir nechta vertikal hisobotini kun-bo'yicha (index bo'yicha) jamlaydi. */
export function combineVerticalReports(reports: VerticalReport[]): VerticalReport {
  const length = reports[0]?.daily.length ?? 0;
  const daily: VerticalDay[] = [];
  for (let i = 0; i < length; i++) {
    daily.push({
      date: reports[0].daily[i].date,
      orders: reports.reduce((s, r) => s + (r.daily[i]?.orders ?? 0), 0),
      revenue: reports.reduce((s, r) => s + (r.daily[i]?.revenue ?? 0), 0),
      profit: reports.reduce((s, r) => s + (r.daily[i]?.profit ?? 0), 0),
    });
  }
  return {
    count: reports.reduce((s, r) => s + r.count, 0),
    delivered: reports.reduce((s, r) => s + r.delivered, 0),
    cancelled: reports.reduce((s, r) => s + r.cancelled, 0),
    revenue: reports.reduce((s, r) => s + r.revenue, 0),
    profit: reports.reduce((s, r) => s + r.profit, 0),
    daily,
  };
}

/** Bitta vertikal uchun umumiy (all-time) statistika. */
export function buildVerticalStats<T>(
  items: T[],
  opts: { isDone: (i: T) => boolean; revenueOf: (i: T) => number; profitOf: (i: T) => number },
): VerticalStats {
  let count = 0;
  let revenue = 0;
  let profit = 0;
  for (const item of items) {
    if (opts.isDone(item)) {
      count += 1;
      revenue += opts.revenueOf(item);
      profit += opts.profitOf(item);
    }
  }
  return { count, revenue, profit };
}
