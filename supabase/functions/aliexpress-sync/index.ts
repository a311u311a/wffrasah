// Daily sync of AliExpress affiliate products into public.ali_products.
//
// For every category with `ali_keywords`, fetch best-selling products
// (product.query) and high-commission products (hotproduct.query) that ship
// to Saudi Arabia, score them, upsert them, and drop that category's rows the
// run did not see. Called by pg_cron with the `x-sync-token` header.
//
// `ali_keywords` is one search ("men fashion clothing"), or several searches
// separated by `|` ("2026 women abaya | women maxi dress | women cardigan")
// to fill one category from several AliExpress sub-categories. Each search
// gets its own page of GROUP_PAGE_SIZE products and the results are merged.
//
// Secrets: ALI_APP_KEY, ALI_APP_SECRET, ALI_BASE_URL, ALI_TRACKING_ID,
// ALI_SYNC_TOKEN (and the built-in SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY).
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import CryptoJS from "https://esm.sh/crypto-js@4.2.0";

const PAGE_SIZE = 50;
const GROUP_PAGE_SIZE = 15;
const GROUP_CONCURRENCY = 4;
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
    aliCall("aliexpress.affiliate.product.query", common),
    useHot
      ? aliCall("aliexpress.affiliate.hotproduct.query", common)
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

/** Runs every `|` search of a category and merges the results. */
async function fetchCategoryGroups(rawKeywords: string, trackingId: string) {
  const groups = rawKeywords
    .split("|")
    .map((g) => g.replace(/\s*,\s*/g, " ").trim())
    .filter(Boolean);
  if (groups.length <= 1) {
    return fetchCategory(groups[0] ?? "", trackingId);
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
      regular.push(...r.regular);
      hot.push(...r.hot);
      errors.push(...r.errors.map((e) => `${batch[j]}: ${e}`));
    });
  }
  return { regular, hot, errors };
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

  const { category_id } = await req.json().catch(() => ({}));
  let query = supabase.from("categories").select("id, ali_keywords");
  if (category_id) query = query.eq("id", String(category_id));
  const { data: categories, error: catErr } = await query;
  if (catErr) return json({ error: catErr.message }, 500);

  const runAt = new Date().toISOString();
  const report: Record<string, unknown>[] = [];

  for (const cat of categories ?? []) {
    const keywords = String(cat.ali_keywords ?? "").trim();
    if (!keywords) continue;

    const { regular, hot, errors } = await fetchCategoryGroups(keywords, trackingId);

    const rows = new Map<number, ReturnType<typeof toRow>>();
    for (const p of regular) {
      const row = toRow(p, String(cat.id), false, runAt);
      if (row.product_id && row.title && row.promotion_link) rows.set(row.product_id, row);
    }
    for (const p of hot) {
      const row = toRow(p, String(cat.id), true, runAt);
      if (row.product_id && row.title && row.promotion_link) rows.set(row.product_id, row);
    }

    let saved = 0;
    let removed = 0;
    if (rows.size > 0) {
      const { error: upErr } = await supabase
        .from("ali_products")
        .upsert([...rows.values()], { onConflict: "product_id,category_id" });
      if (upErr) {
        errors.push(`upsert: ${upErr.message}`);
      } else {
        saved = rows.size;
        // Only prune when this run saved fresh rows, so a failed fetch never
        // empties a category.
        const { count } = await supabase
          .from("ali_products")
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
      saved,
      removed,
      ...(errors.length ? { errors } : {}),
    });
  }

  return json({
    run_at: runAt,
    categories: report.length,
    saved: report.reduce((s, r) => s + Number(r.saved ?? 0), 0),
    report,
  });
});
