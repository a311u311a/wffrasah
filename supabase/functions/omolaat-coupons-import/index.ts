import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-omolaat-import-token",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function normalizeText(value: unknown): string {
  return String(value ?? "").trim();
}

function normalizeStoreId(value: unknown): string {
  const raw = normalizeText(value).toLowerCase();
  return raw.replace(/\s+/g, "-").replace(/[^a-z0-9\u0600-\u06FF-]/g, "") ||
    "store";
}

function normalizeDuplicatePart(value: unknown): string {
  return normalizeText(value).toLowerCase().replace(/\s+/g, " ");
}

function compactRecord(record: Record<string, unknown>) {
  return Object.fromEntries(
    Object.entries(record).filter(([, value]) =>
      value !== null && value !== undefined && String(value).trim() !== ""
    ),
  );
}

function hasArabic(value: string) {
  return /[\u0600-\u06FF]/.test(value);
}

function logoUrlFromWebsite(value: unknown): string {
  const raw = normalizeText(value);
  if (!raw) return "";

  try {
    const url = new URL(/^https?:\/\//i.test(raw) ? raw : `https://${raw}`);
    const domain = url.hostname.replace(/^www\./, "");
    if (!domain) return "";
    return `https://www.google.com/s2/favicons?domain=${encodeURIComponent(domain)}&sz=256`;
  } catch {
    return "";
  }
}

async function translateArabicToEnglish(text: string, target = "text") {
  const openaiApiKey = Deno.env.get("OPENAI_API_KEY");
  const source = normalizeText(text);
  if (!openaiApiKey || !source || !hasArabic(source)) return "";

  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${openaiApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: Deno.env.get("OPENAI_TRANSLATION_MODEL") || "gpt-4o-mini",
      input:
        `Translate this Arabic store ${target} to natural English. Return only the translation, no quotes or explanation.\n\n` +
        source,
      store: false,
    }),
  });

  if (!response.ok) return "";
  const data = await response.json();
  return normalizeText(data.output_text);
}

type OmolaatCouponInput = {
  import_source?: unknown;
  source_coupon_id?: unknown;
  store_id?: unknown;
  store_name?: unknown;
  store_name_ar?: unknown;
  store_name_en?: unknown;
  store_description?: unknown;
  store_description_ar?: unknown;
  store_description_en?: unknown;
  store_image?: unknown;
  category_id?: unknown;
  category_name?: unknown;
  code?: unknown;
  title?: unknown;
  discount?: unknown;
  coupon_description?: unknown;
  description?: unknown;
  affiliate_url?: unknown;
  web?: unknown;
  expiry_date?: unknown;
  image?: unknown;
  tags?: unknown;
};

const allowedImportSources = new Set(["omolaat", "linkaraby"]);

function normalizeImportSource(value: unknown): string {
  const source = normalizeText(value).toLowerCase();
  return allowedImportSources.has(source) ? source : "omolaat";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const importToken = Deno.env.get("OMOLAAT_IMPORT_TOKEN");

    if (!supabaseUrl || !serviceRoleKey) {
      return json({ error: "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY" }, 500);
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    const requestImportToken = req.headers.get("x-omolaat-import-token") ?? "";
    const hasValidImportToken = Boolean(importToken) &&
      requestImportToken === importToken;
    const userClient = createClient(supabaseUrl, serviceRoleKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    });
    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    if (!hasValidImportToken) {
      const { data: userData, error: userError } = await userClient.auth.getUser();
      if (userError || !userData.user) return json({ error: "Unauthorized" }, 401);

      const { data: adminRow, error: adminError } = await adminClient
        .from("admins")
        .select("user_id")
        .eq("user_id", userData.user.id)
        .maybeSingle();

      if (adminError) return json({ error: "Admin check failed", details: adminError }, 500);
      if (!adminRow) return json({ error: "Forbidden" }, 403);
    }

    const body = await req.json().catch(() => ({}));
    const bodyImportSource = normalizeImportSource(body.import_source);
    const inputCoupons = Array.isArray(body.coupons) ? body.coupons : [body];
    const { data: categoriesData } = await adminClient
      .from("categories")
      .select("id,name,name_ar,name_en");
    const categories = Array.isArray(categoriesData) ? categoriesData : [];
    const resolveCategoryId = (item: OmolaatCouponInput, tags: string[]) => {
      const explicitCategoryId = normalizeText(item.category_id);
      if (explicitCategoryId) return explicitCategoryId;

      const categoryName = normalizeText(item.category_name) || tags[0] || "";
      const normalizedCategoryName = categoryName.toLowerCase();
      if (!normalizedCategoryName) return "";

      const match = categories.find((category: Record<string, unknown>) => {
        const names = [
          category.name,
          category.name_ar,
          category.name_en,
        ].map((name) => normalizeText(name).toLowerCase());

        return names.some((name) =>
          name &&
          (name === normalizedCategoryName ||
            name.includes(normalizedCategoryName) ||
            normalizedCategoryName.includes(name))
        );
      }) as Record<string, unknown> | undefined;

      return normalizeText(match?.id);
    };
    const storesBySlug = new Map<string, Record<string, unknown>>();
    const storesByCouponDuplicateKey = new Map<string, Record<string, unknown>>();

    const rows = (await Promise.all(
      inputCoupons.map(async (item: OmolaatCouponInput) => {
        const importSource = normalizeImportSource(
          item.import_source ?? bodyImportSource,
        );
        const storeNameAr = normalizeText(item.store_name_ar ?? item.store_name);
        let storeNameEn = normalizeText(item.store_name_en);
        if (!storeNameEn && storeNameAr) {
          storeNameEn = await translateArabicToEnglish(storeNameAr, "name");
        } else if (hasArabic(storeNameEn)) {
          storeNameEn = await translateArabicToEnglish(storeNameEn, "name");
        }
        const storeName = storeNameAr || storeNameEn || normalizeText(item.store_id);
        const storeId = normalizeStoreId(normalizeText(item.store_id) || storeName);
        const storeDescriptionAr = normalizeText(
          item.store_description_ar ?? item.store_description,
        );
        let storeDescriptionEn = normalizeText(item.store_description_en);
        if (!storeDescriptionEn && storeDescriptionAr) {
          storeDescriptionEn = await translateArabicToEnglish(
            storeDescriptionAr,
            "description",
          );
        } else if (hasArabic(storeDescriptionEn)) {
          storeDescriptionEn = await translateArabicToEnglish(
            storeDescriptionEn,
            "description",
          );
        }
        const code = normalizeText(item.code);
        if (!code) return null;
        const title = normalizeText(item.title) || storeName || "كوبون جديد";
        const description = normalizeText(
          item.coupon_description ?? item.discount ?? item.description,
        ) || title;
        const web = normalizeText(item.affiliate_url) || normalizeText(item.web);
        const storeImage = normalizeText(item.store_image ?? item.image) ||
          logoUrlFromWebsite(web);
        const sourceCouponId = normalizeText(item.source_coupon_id);
        const duplicateKey = [
          importSource,
          sourceCouponId || normalizeDuplicatePart(storeId),
          normalizeDuplicatePart(code || web || title),
        ]
          .filter(Boolean)
          .join(":");
        const tags = Array.isArray(item.tags)
          ? item.tags.map((tag) => normalizeText(tag)).filter(Boolean)
          : [];
        const categoryId = resolveCategoryId(item, tags);

        const storeRecord = compactRecord({
          approval_status: "waiting_approval",
          category_id: categoryId,
          description: storeDescriptionAr || storeDescriptionEn,
          description_ar: storeDescriptionAr || storeDescriptionEn,
          description_en: storeDescriptionEn || undefined,
          image: storeImage || undefined,
          import_source: importSource,
          name: storeNameAr || storeNameEn || storeId,
          name_ar: storeNameAr || storeNameEn || storeId,
          name_en: storeNameEn || undefined,
          slug: storeId,
        });
        storesBySlug.set(storeId, storeRecord);
        storesByCouponDuplicateKey.set(duplicateKey, storeRecord);

        return {
          approval_status: "waiting_approval",
          code,
          created_at: new Date().toISOString(),
          description,
          description_ar: description,
          description_en: description,
          duplicate_key: duplicateKey,
          expiry_date: normalizeText(item.expiry_date) || null,
          image: storeImage,
          import_source: importSource,
          name: title,
          name_ar: title,
          name_en: title,
          source_coupon_id: sourceCouponId || null,
          store_id: storeId,
          tags: JSON.stringify(tags),
          web,
        };
      })
    )).filter((row) => row?.code);

    if (rows.length === 0) return json({ success: true, imported: 0, skipped: 0 });

    const duplicateKeys = rows
      .map((row) => String(row.duplicate_key ?? ""))
      .filter(Boolean);
    const { data: existingCoupons, error: existingCouponsError } =
      await adminClient
        .from("coupons")
        .select("duplicate_key")
        .in("duplicate_key", duplicateKeys);

    if (existingCouponsError) {
      return json({
        error: "Failed to check Omolaat coupons",
        details: existingCouponsError,
      }, 500);
    }

    const existingDuplicateKeys = new Set(
      (existingCoupons ?? []).map((coupon: Record<string, unknown>) =>
        String(coupon.duplicate_key ?? "")
      ),
    );
    const rowsToInsert = rows.filter((row) =>
      !existingDuplicateKeys.has(String(row.duplicate_key ?? ""))
    );

    const stores = Array.from(
      new Map(
        rowsToInsert
          .map((row) =>
            storesByCouponDuplicateKey.get(String(row.duplicate_key ?? ""))
          )
          .filter(Boolean)
          .map((store) => [String(store?.slug ?? ""), store]),
      ).values(),
    );
    if (stores.length > 0) {
      const storeSlugs = stores.map((store) => String(store.slug ?? "")).filter(Boolean);
      const { data: existingStores, error: existingStoresError } = await adminClient
        .from("stores")
        .select("slug")
        .in("slug", storeSlugs);

      if (existingStoresError) {
        return json({
          error: "Failed to check Omolaat stores",
          details: existingStoresError,
        }, 500);
      }

      const existingStoreSlugs = new Set(
        (existingStores ?? []).map((store: Record<string, unknown>) =>
          String(store.slug ?? "")
        ),
      );
      const storesToInsert = stores.filter((store) =>
        !existingStoreSlugs.has(String(store.slug ?? ""))
      );
      const storesToUpdate = stores.filter((store) =>
        existingStoreSlugs.has(String(store.slug ?? ""))
      );

      if (storesToInsert.length > 0) {
        const { error: storesInsertError } = await adminClient
          .from("stores")
          .insert(storesToInsert);

        if (storesInsertError) {
          return json({
            error: "Failed to insert Omolaat stores",
            details: storesInsertError,
          }, 500);
        }
      }

      for (const store of storesToUpdate) {
        const {
          approval_status: _approvalStatus,
          import_source: _importSource,
          ...storeUpdate
        } = store;
        const { error: storesUpdateError } = await adminClient
          .from("stores")
          .update(storeUpdate)
          .eq("slug", String(store.slug ?? ""));

        if (storesUpdateError) {
          return json({
            error: "Failed to update Omolaat stores",
            details: storesUpdateError,
          }, 500);
        }
      }
    }

    let inserted = 0;
    if (rowsToInsert.length > 0) {
      const { data, error } = await adminClient
        .from("coupons")
        .insert(rowsToInsert)
        .select("id");

      if (error) {
        return json({
          error: "Failed to import Omolaat coupons",
          details: error,
        }, 500);
      }

      inserted = data?.length ?? 0;
    }

    return json({
      success: true,
      stores: stores.length,
      received: rows.length,
      imported: inserted,
      skipped: rows.length - inserted,
    });
  } catch (err) {
    return json({ error: String((err as Error)?.message ?? err) }, 500);
  }
});
