import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import CryptoJS from "https://esm.sh/crypto-js@4.2.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function pickFirstString(v: unknown): string | null {
  if (!v) return null;
  if (typeof v === "string") return v.trim() || null;
  if (Array.isArray(v)) {
    const s = v
      .map((x) => (typeof x === "string" ? x.trim() : ""))
      .filter(Boolean)
      .join(" ");
    return s || null;
  }
  return null;
}

function md5HexUpper(input: string): string {
  return CryptoJS.MD5(input).toString().toUpperCase();
}

function aliSign(params: Record<string, string>, secret: string): string {
  const keys = Object.keys(params).sort();
  const concatenated = keys.map((k) => `${k}${params[k]}`).join("");
  return md5HexUpper(`${secret}${concatenated}${secret}`);
}

async function aliCall(method: string, bizParams: Record<string, string>) {
  const appKey = Deno.env.get("ALI_APP_KEY");
  const appSecret = Deno.env.get("ALI_APP_SECRET");
  const baseUrl = Deno.env.get("ALI_BASE_URL"); // https://api-sg.aliexpress.com/sync
  if (!appKey || !appSecret || !baseUrl) {
    throw new Error("Missing ALI_APP_KEY / ALI_APP_SECRET / ALI_BASE_URL");
  }

  const publicParams: Record<string, string> = {
    app_key: appKey,
    method,
    format: "json",
    v: "2.0",
    sign_method: "md5",
    timestamp: new Date().toISOString().replace("T", " ").replace("Z", ""),
    ...bizParams,
  };

  const sign = aliSign(publicParams, appSecret);

  const url = new URL(baseUrl);
  for (const [k, v] of Object.entries(publicParams)) url.searchParams.set(k, v);
  url.searchParams.set("sign", sign);

  const res = await fetch(url.toString(), { method: "GET" });
  const text = await res.text();

  let body: any;
  try {
    body = JSON.parse(text);
  } catch {
    body = { raw: text };
  }

  if (!res.ok) throw new Error(`AliExpress HTTP ${res.status}: ${text}`);

  const aliErr = (body as any)?.error_response;
  if (aliErr) {
    const msg = `${aliErr.code ?? "ALI_ERROR"}: ${aliErr.msg ?? "Unknown error"}`;
    if (msg.toLowerCase().includes("invalid app")) {
      throw new Error("Invalid appKey أو appSecret");
    }
    if (
      msg.toLowerCase().includes("frequency") ||
      msg.toLowerCase().includes("throttle") ||
      msg.toLowerCase().includes("too many")
    ) {
      throw new Error("AliExpress rate limit exceeded");
    }
    throw new Error(msg);
  }

  return body;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method Not Allowed" }, 405);

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceKey) {
      return json({ error: "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY" }, 500);
    }
    const supabase = createClient(supabaseUrl, serviceKey);

    const { category_id, page_no = 1, page_size = 20 } = await req.json().catch(() => ({}));
    if (!category_id) return json({ error: "category_id is required" }, 400);

    const { data: cat, error: catErr } = await supabase
      .from("categories")
      .select("id, ali_keywords")
      .eq("id", String(category_id))
      .single();

    if (catErr || !cat) return json({ error: "Category not found", details: catErr }, 404);

    const keywords = pickFirstString((cat as any).ali_keywords);
    if (!keywords) return json({ error: "ali_keywords is empty for this category" }, 400);

    const target_language = Deno.env.get("ALI_TARGET_LANGUAGE") ?? "ar";
    const target_currency = Deno.env.get("ALI_TARGET_CURRENCY") ?? "SAR";
    const tracking_id = Deno.env.get("ALI_TRACKING_ID");
    if (!tracking_id) return json({ error: "Missing ALI_TRACKING_ID" }, 500);

    const productResp = await aliCall("aliexpress.affiliate.product.query", {
      key_words: keywords,
      page_no: String(page_no),
      page_size: String(page_size),
      target_language,
      target_currency,
      tracking_id,
    });

    const result =
      productResp?.aliexpress_affiliate_product_query_response?.resp_result?.result ??
      productResp?.aliexpress_affiliate_product_query_response ??
      productResp;

    const productsRaw: any[] = result?.products?.product ?? [];

    const products = productsRaw.map((p) => ({
      product_id: p.product_id ?? null,
      product_title: p.product_title ?? null,
      product_detail_url: p.product_detail_url ?? null,
      product_main_image_url: p.product_main_image_url ?? null,
      sale_price: p.target_sale_price ?? p.sale_price ?? null,
      original_price: p.target_original_price ?? p.original_price ?? null,
      commission_rate: p.hot_product_commission_rate ?? p.commission_rate ?? null,
      promotion_link: p.promotion_link ?? null,
    }));

    return json({
      category_id: String(category_id),
      keywords_used: keywords,
      count: products.length,
      products,
    });
  } catch (e) {
    return json({ error: String((e as any)?.message ?? e) }, 500);
  }
});
