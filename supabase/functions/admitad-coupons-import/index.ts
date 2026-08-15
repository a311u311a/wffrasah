import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

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

function normalizeStoreId(value: unknown): string {
  const raw = String(value ?? "store").trim().toLowerCase();
  const compact = raw.replace(/\s+/g, "");
  return compact || "store";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const admitadClientId = Deno.env.get("ADMITAD_CLIENT_ID");
    const admitadClientSecret = Deno.env.get("ADMITAD_CLIENT_SECRET");

    if (!supabaseUrl || !serviceRoleKey) {
      return json({ error: "Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY" }, 500);
    }
    if (!admitadClientId || !admitadClientSecret) {
      return json({ error: "Missing ADMITAD_CLIENT_ID or ADMITAD_CLIENT_SECRET" }, 500);
    }

    const authHeader = req.headers.get("Authorization") ?? "";
    const userClient = createClient(supabaseUrl, serviceRoleKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    });
    const adminClient = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) {
      return json({ error: "Unauthorized" }, 401);
    }

    const { data: adminRow, error: adminError } = await adminClient
      .from("admins")
      .select("user_id")
      .eq("user_id", userData.user.id)
      .maybeSingle();

    if (adminError) return json({ error: "Admin check failed", details: adminError }, 500);
    if (!adminRow) return json({ error: "Forbidden" }, 403);

    const { limit = 50 } = await req.json().catch(() => ({}));
    const safeLimit = Math.max(1, Math.min(Number(limit) || 50, 100));

    const tokenResponse = await fetch("https://api.admitad.com/token/", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Authorization: `Basic ${btoa(`${admitadClientId}:${admitadClientSecret}`)}`,
      },
      body: new URLSearchParams({
        grant_type: "client_credentials",
        client_id: admitadClientId,
        scope: "coupons public_data",
      }),
    });

    if (!tokenResponse.ok) {
      return json(
        { error: "Admitad token request failed", status: tokenResponse.status },
        502,
      );
    }

    const tokenData = await tokenResponse.json();
    const accessToken = tokenData.access_token;
    if (!accessToken) return json({ error: "Admitad token missing access_token" }, 502);

    const couponsUrl = new URL("https://api.admitad.com/coupons/");
    couponsUrl.searchParams.set("limit", String(safeLimit));
    couponsUrl.searchParams.set("active", "true");

    const couponsResponse = await fetch(couponsUrl, {
      headers: { Authorization: `Bearer ${accessToken}` },
    });

    if (!couponsResponse.ok) {
      return json(
        { error: "Admitad coupons request failed", status: couponsResponse.status },
        502,
      );
    }

    const couponsData = await couponsResponse.json();
    const results = Array.isArray(couponsData.results) ? couponsData.results : [];
    const rows = results
      .map((item: Record<string, unknown>) => {
        const campaign = item.campaign as Record<string, unknown> | undefined;
        const name = String(item.name ?? "عرض مميز");
        const code = String(item.promocode ?? "");
        const link = String(item.goto_link ?? "");

        return {
          code,
          created_at: new Date().toISOString(),
          description: name,
          description_ar: name,
          description_en: name,
          name,
          name_ar: name,
          name_en: name,
          web: link,
          store_id: normalizeStoreId(campaign?.name),
          tags: JSON.stringify([]),
        };
      })
      .filter((row) => row.code || row.web);

    if (rows.length === 0) {
      return json({ success: true, imported: 0 });
    }

    const { error: insertError } = await adminClient.from("coupons").insert(rows);
    if (insertError) {
      return json({ error: "Failed to insert coupons", details: insertError }, 500);
    }

    return json({ success: true, imported: rows.length });
  } catch (err) {
    return json({ error: String((err as Error)?.message ?? err) }, 500);
  }
});
