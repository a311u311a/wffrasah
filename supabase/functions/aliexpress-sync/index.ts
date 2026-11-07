// Daily sync of AliExpress affiliate products into public.ali_products.
//
// For every category with `ali_keywords`, fetch best-selling products
// (product.query) and high-commission products (hotproduct.query) that ship
// to Saudi Arabia, score them, upsert them, and drop that category's rows the
// run did not see. Called by pg_cron with the `x-sync-token` header.
//
// Body (all optional):
//   source: "store" (default) reads public.categories.ali_keywords and writes
//           public.ali_products; "ali" reads the active public.ali_categories
//           (keywords, in sort_order) and writes public.ali_category_products.
//   category_id: sync only that category.
//   from_order / to_order: with source "ali", only categories whose
//           sort_order is in that range (to split long runs).
//
// `ali_keywords` is one search ("men fashion clothing"), or several searches
// separated by `|` ("2026 women abaya | women maxi dress | women cardigan")
// to fill one category from several AliExpress sub-categories. Each search
// gets its own page of GROUP_PAGE_SIZE products and the results are merged.
// A group that starts with `-` is a comma-separated list of words to exclude:
// any product whose title contains one of them is skipped
// ("... | -sexy, شفاف, مكشوف").
// With several searches, products are ordered round-robin across them (best
// of each search first, then the second best, ...) by handing the category's
// own sort_score values out in that order, so the page shows a mix of types
// and the category's place in the all-categories list stays the same.
//
// Secrets: ALI_APP_KEY, ALI_APP_SECRET, ALI_BASE_URL, ALI_TRACKING_ID,
// ALI_SYNC_TOKEN (and the built-in SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY).
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import CryptoJS from "https://esm.sh/crypto-js@4.2.0";

const PAGE_SIZE = 50;
const GROUP_PAGE_SIZE = 15;
const GROUP_CONCURRENCY = 2;
const SHIP_TO = Deno.env.get("ALI_SHIP_TO_COUNTRY") ?? "SA";
const CURRENCY = Deno.env.get("ALI_TARGET_CURRENCY") ?? "SAR";
const LANGUAGE = Deno.env.get("ALI_TARGET_LANGUAGE") ?? "AR";

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function aliSign(params: Record<string, string>, secret: string): string {
  const concatenated = Object.keys(params)
    .sort()
    .map((k) => `${k}${params[k]}`)
    .join("");
  return CryptoJS.MD5(`${secret}${concatenated}${secret}`).toString().toUpperCase();
}

async function aliCall(method: string, bizParams: Record<string, string>) {
  const appKey = Deno.env.get("ALI_APP_KEY")!;
  const appSecret = Deno.env.get("ALI_APP_SECRET")!;
  const baseUrl = Deno.env.get("ALI_BASE_URL")!;

  const params: Record<string, string> = {
    app_key: appKey,
    method,
    format: "json",
    v: "2.0",
    sign_method: "md5",
    timestamp: new Date().toISOString().replace("T", " ").replace("Z", ""),
    ...bizParams,
  };
  const url = new URL(baseUrl);
  for (const [k, v] of Object.entries(params)) url.searchParams.set(k, v);
  url.searchParams.set("sign", aliSign(params, appSecret));

  const res = await fetch(url.toString());
  const text = await res.text();
  if (!res.ok) throw new Error(`AliExpress HTTP ${res.status}: ${text.slice(0, 300)}`);
  const body = JSON.parse(text);
  if (body?.error_response) {
    const e = body.error_response;
    throw new Error(`${e.code ?? "ALI_ERROR"}: ${e.msg ?? "Unknown error"}`);
  }
  return body;
}

/** Retries when AliExpress rate-limits ("ApiCallLimit ... ban will last N seconds"). */
async function aliCallWithRetry(
  method: string,
  bizParams: Record<string, string>,
  attempts = 3,
) {
  for (let i = 1; ; i++) {
    try {
      return await aliCall(method, bizParams);
    } catch (e) {
      const msg = String((e as Error)?.message ?? e);
      if (i >= attempts || !msg.includes("ApiCallLimit")) throw e;
      const secs = Number(msg.match(/last (\d+) second/)?.[1] ?? 1);
      await new Promise((r) => setTimeout(r, (secs + 0.5) * 1000 * i));
    }
  }
}

function extractProducts(body: any): any[] {
  for (const key of Object.keys(body ?? {})) {
    const result = body[key]?.resp_result?.result;
    if (result) return result?.products?.product ?? [];
  }
  return [];
}

function num(v: unknown): number | null {
  if (v == null) return null;
  const n = parseFloat(String(v).replace("%", "").replace(",", ""));
  return Number.isFinite(n) ? n : null;
}

function toRow(p: any, categoryId: string, isHot: boolean, runAt: string) {
  const sale = num(p.target_sale_price ?? p.sale_price);
  const original = num(p.target_original_price ?? p.original_price);
  let discount = num(p.discount);
  if (discount == null && sale != null && original && original > sale) {
    discount = Math.round((1 - sale / original) * 100);
  }
  const commission = Math.max(
    num(p.hot_product_commission_rate) ?? 0,
    num(p.commission_rate) ?? 0,
  );
  const orders = num(p.lastest_volume ?? p.latest_volume) ?? 0;
  const rating = num(p.evaluate_rate);

  // Favour sellers people actually buy, then commission, then discount.
  const score =
    Math.log10(orders + 1) * 10 +
    commission * 2 +
    (discount ?? 0) * 0.3 +
    (isHot ? 5 : 0);

  return {
    product_id: Number(p.product_id),
    category_id: categoryId,
    title: String(p.product_title ?? "").trim(),
    image: p.product_main_image_url ?? null,
    sale_price: sale,
    original_price: original,
    discount_percent: discount == null ? null : Math.round(discount),
    currency: p.target_sale_price_currency ?? CURRENCY,
    commission_rate: commission,
    promotion_link: p.promotion_link ?? "",
    detail_url: p.product_detail_url ?? null,
    orders_count: Math.round(orders),
    rating,
    is_hot: isHot,
    sort_score: Math.round(score * 100) / 100,
    updated_at: runAt,
  };
}

async function fetchCategory(
  keywords: string,
  trackingId: string,
  pageSize = PAGE_SIZE,
) {
  const common = {
    keywords,
    page_no: "1",
    page_size: String(pageSize),
    sort: "LAST_VOLUME_DESC",
    ship_to_country: SHIP_TO,
    target_currency: CURRENCY,
    target_language: LANGUAGE,
    tracking_id: trackingId,
  };
  // hotproduct.query needs an elevated API permission on the AliExpress app;
  // enable it with the ALI_USE_HOT=true secret once AliExpress grants it.
  const useHot = Deno.env.get("ALI_USE_HOT") === "true";
  const [regular, hot] = await Promise.allSettled([
    aliCallWithRetry("aliexpress.affiliate.product.query", common),
    useHot
      ? aliCallWithRetry("aliexpress.affiliate.hotproduct.query", common)
      : Promise.resolve({}),
  ]);
  return {
    regular: regular.status === "fulfilled" ? extractProducts(regular.value) : [],
    hot: hot.status === "fulfilled" ? extractProducts(hot.value) : [],
    errors: [regular, hot]
      .filter((r): r is PromiseRejectedResult => r.status === "rejected")
      .map((r) => String(r.reason?.message ?? r.reason)),
  };
}

/** Words from `-` groups; products whose title contains one are skipped. */
function parseExcludes(rawKeywords: string): string[] {
  return rawKeywords
    .split("|")
    .map((g) => g.trim())
    .filter((g) => g.startsWith("-"))
    .flatMap((g) => g.slice(1).split(","))
    .map((w) => w.trim().toLowerCase())
    .filter(Boolean);
}

function isExcluded(title: string, excludes: string[]): boolean {
  if (!excludes.length) return false;
  const t = title.toLowerCase();
  return excludes.some((w) => t.includes(w));
}

/** Runs every `|` search of a category and merges the results. */
async function fetchCategoryGroups(rawKeywords: string, trackingId: string) {
  const groups = rawKeywords
    .split("|")
    .map((g) => g.trim())
    .filter((g) => g && !g.startsWith("-"))
    .map((g) => g.replace(/\s*,\s*/g, " ").trim())
    .filter(Boolean);
  // product_id -> index of the first search that returned it.
  const groupOf = new Map<number, number>();
  if (groups.length <= 1) {
    return { ...(await fetchCategory(groups[0] ?? "", trackingId)), groupOf };
  }
  const regular: any[] = [];
  const hot: any[] = [];
  const errors: string[] = [];
  for (let i = 0; i < groups.length; i += GROUP_CONCURRENCY) {
    const batch = groups.slice(i, i + GROUP_CONCURRENCY);
    const results = await Promise.all(
      batch.map((g) => fetchCategory(g, trackingId, GROUP_PAGE_SIZE)),
    );
    results.forEach((r, j) => {
      for (const p of [...r.regular, ...r.hot]) {
        const id = Number(p.product_id);
        if (id && !groupOf.has(id)) groupOf.set(id, i + j);
      }
      regular.push(...r.regular);
      hot.push(...r.hot);
      errors.push(...r.errors.map((e) => `${batch[j]}: ${e}`));
    });
  }
  return { regular, hot, errors, groupOf };
}

/**
 * Reorders rows round-robin across their searches by reassigning the same
 * sort_score values (highest first) in that order. No-op for one search.
 */
function interleaveScores(
  rows: { product_id: number; sort_score: number }[],
  groupOf: Map<number, number>,
) {
  if (groupOf.size === 0) return;
  const byGroup = new Map<number, typeof rows>();
  for (const r of rows) {
    const g = groupOf.get(r.product_id) ?? -1;
    if (!byGroup.has(g)) byGroup.set(g, []);
    byGroup.get(g)!.push(r);
  }
  if (byGroup.size <= 1) return;
  const lists = [...byGroup.keys()]
    .sort((a, b) => a - b)
    .map((g) => byGroup.get(g)!.sort((a, b) => b.sort_score - a.sort_score));
  const order: typeof rows = [];
  for (let i = 0; order.length < rows.length; i++) {
    for (const list of lists) if (i < list.length) order.push(list[i]);
  }
  const scores = rows.map((r) => r.sort_score).sort((a, b) => b - a);
  // Strictly decreasing so equal scores cannot undo the order in the DB.
  for (let i = 1; i < scores.length; i++) {
    if (scores[i] >= scores[i - 1]) {
      scores[i] = Math.round((scores[i - 1] - 0.01) * 100) / 100;
    }
  }
  order.forEach((r, i) => (r.sort_score = scores[i]));
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "Method Not Allowed" }, 405);

  const expected = Deno.env.get("ALI_SYNC_TOKEN");
  if (!expected || req.headers.get("x-sync-token") !== expected) {
    return json({ error: "Unauthorized" }, 401);
  }

  const trackingId = Deno.env.get("ALI_TRACKING_ID");
  if (!trackingId) return json({ error: "Missing ALI_TRACKING_ID" }, 500);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const body = await req.json().catch(() => ({}));
  const { category_id, from_order, to_order } = body ?? {};
  const useAli = body?.source === "ali";
  const productsTable = useAli ? "ali_category_products" : "ali_products";

  let query = useAli
    ? supabase
      .from("ali_categories")
      .select("id, keywords, sort_order")
      .eq("active", true)
      .order("sort_order")
    : supabase.from("categories").select("id, ali_keywords");
  if (category_id) query = query.eq("id", String(category_id));
  if (useAli && from_order != null) query = query.gte("sort_order", Number(from_order));
  if (useAli && to_order != null) query = query.lte("sort_order", Number(to_order));
  const { data: rawCategories, error: catErr } = await query;
  if (catErr) return json({ error: catErr.message }, 500);
  const categories = (rawCategories ?? []).map((c: any) => ({
    id: c.id,
    keywords: String((useAli ? c.keywords : c.ali_keywords) ?? ""),
  }));

  const runAt = new Date().toISOString();
  const report: Record<string, unknown>[] = [];

  for (const cat of categories) {
    const keywords = cat.keywords.trim();
    if (!keywords) continue;

    const { regular, hot, errors, groupOf } = await fetchCategoryGroups(
      keywords,
      trackingId,
    );
    const excludes = parseExcludes(keywords);

    let excluded = 0;
    const rows = new Map<number, ReturnType<typeof toRow>>();
    for (const [list, isHot] of [[regular, false], [hot, true]] as const) {
      for (const p of list) {
        const row = toRow(p, String(cat.id), isHot, runAt);
        if (!row.product_id || !row.title || !row.promotion_link) continue;
        if (isExcluded(row.title, excludes)) {
          excluded++;
          continue;
        }
        rows.set(row.product_id, row);
      }
    }

    let saved = 0;
    let removed = 0;
    interleaveScores([...rows.values()], groupOf);

    if (rows.size > 0) {
      const { error: upErr } = await supabase
        .from(productsTable)
        .upsert([...rows.values()], { onConflict: "product_id,category_id" });
      if (upErr) {
        errors.push(`upsert: ${upErr.message}`);
      } else {
        saved = rows.size;
        // Only prune when this run saved fresh rows, so a failed fetch never
        // empties a category.
        const { count } = await supabase
          .from(productsTable)
          .delete({ count: "exact" })
          .eq("category_id", String(cat.id))
          .lt("updated_at", runAt);
        removed = count ?? 0;
      }
    }

    report.push({
      category_id: cat.id,
      regular: regular.length,
      hot: hot.length,
      excluded,
      saved,
      removed,
      ...(errors.length ? { errors } : {}),
    });
  }

  return json({
    source: useAli ? "ali" : "store",
    run_at: runAt,
    categories: report.length,
    saved: report.reduce((s, r) => s + Number(r.saved ?? 0), 0),
    report,
  });
});
