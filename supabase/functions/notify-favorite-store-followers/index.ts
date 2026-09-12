import "@supabase/functions-js/edge-runtime.d.ts";

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

function base64url(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToKey(pem: string): Promise<CryptoKey> {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const binary = atob(b64);
  const buffer = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) buffer[i] = binary.charCodeAt(i);

  return crypto.subtle.importKey(
    "pkcs8",
    buffer.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

async function createSignedJwt(
  serviceAccount: { client_email: string; private_key: string },
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };

  const enc = new TextEncoder();
  const headerB64 = base64url(enc.encode(JSON.stringify(header)));
  const payloadB64 = base64url(enc.encode(JSON.stringify(payload)));
  const signingInput = `${headerB64}.${payloadB64}`;
  const key = await pemToKey(serviceAccount.private_key);
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    enc.encode(signingInput),
  );

  return `${signingInput}.${base64url(signature)}`;
}

async function getAccessToken(
  serviceAccount: { client_email: string; private_key: string },
): Promise<string> {
  const jwt = await createSignedJwt(serviceAccount);
  const resp = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  if (!resp.ok) {
    const errText = await resp.text();
    throw new Error(`Token exchange failed: ${resp.status} - ${errText}`);
  }

  const data = await resp.json();
  return data.access_token;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const { couponId, storeId, storeName, imageUrl } = await req.json();
    if (!couponId || !storeId || !storeName) {
      return json({ error: "couponId, storeId and storeName are required" }, 400);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const serviceAccountStr = Deno.env.get("FCM_SERVICE_ACCOUNT");

    if (!supabaseUrl || !serviceRoleKey) {
      return json({ error: "Supabase service credentials are not configured" }, 500);
    }
    if (!serviceAccountStr) {
      return json({ error: "FCM_SERVICE_ACCOUNT secret is not configured" }, 500);
    }

    const restHeaders = {
      apikey: serviceRoleKey,
      Authorization: `Bearer ${serviceRoleKey}`,
      "Content-Type": "application/json",
    };

    const followsResp = await fetch(
      `${supabaseUrl}/rest/v1/store_follows?store_id=eq.${encodeURIComponent(storeId)}&select=user_id`,
      { headers: restHeaders },
    );

    if (!followsResp.ok) {
      return json({ error: await followsResp.text() }, followsResp.status);
    }

    const followRows = await followsResp.json();
    const followerIds = Array.from(
      new Set(
        Array.isArray(followRows)
          ? followRows.map((row) => row.user_id).filter(Boolean)
          : [],
      ),
    );

    if (followerIds.length === 0) {
      return json({
        success: false,
        sent: 0,
        followers: 0,
        enabledFollowers: 0,
        failed: 0,
        message: "no_followers",
      });
    }

    const idsFilter = followerIds.join(",");
    const prefsResp = await fetch(
      `${supabaseUrl}/rest/v1/user_notification_preferences?user_id=in.(${idsFilter})&favorite_store_notifications_enabled=eq.false&select=user_id`,
      { headers: restHeaders },
    );
    const disabledRows = prefsResp.ok ? await prefsResp.json() : [];
    const disabledIds = new Set(
      Array.isArray(disabledRows)
        ? disabledRows.map((row) => row.user_id).filter(Boolean)
        : [],
    );
    const enabledFollowerIds = followerIds.filter((id) => !disabledIds.has(id));

    if (enabledFollowerIds.length === 0) {
      return json({
        success: false,
        sent: 0,
        followers: followerIds.length,
        enabledFollowers: 0,
        failed: 0,
        message: "disabled_by_users",
      });
    }

    const enabledFilter = enabledFollowerIds.join(",");
    const tokensResp = await fetch(
      `${supabaseUrl}/rest/v1/fcm_tokens?user_id=in.(${enabledFilter})&is_enabled=eq.true&select=token,user_id`,
      { headers: restHeaders },
    );

    if (!tokensResp.ok) {
      return json({ error: await tokensResp.text() }, tokensResp.status);
    }

    const tokenRows = await tokensResp.json();
    const tokens = Array.isArray(tokenRows)
      ? tokenRows.map((row) => row.token).filter(Boolean)
      : [];

    if (tokens.length === 0) {
      return json({
        success: false,
        sent: 0,
        followers: followerIds.length,
        enabledFollowers: enabledFollowerIds.length,
        failed: 0,
        message: "no_fcm_tokens",
      });
    }

    const title = `كوبون جديد في ${storeName}`;
    const body = "أضيف كوبون جديد لمتجر من متاجرك المفضلة.";

    const serviceAccount = JSON.parse(serviceAccountStr);
    const projectId = serviceAccount.project_id;
    const accessToken = await getAccessToken(serviceAccount);
    const fcmUrl =
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
    const fcmHeaders = {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    };

    const sendResults = await Promise.all(
      tokens.map(async (token) => {
        const resp = await fetch(fcmUrl, {
          method: "POST",
          headers: fcmHeaders,
          body: JSON.stringify({
            message: {
              token,
              notification: {
                title,
                body,
                ...(imageUrl ? { image: imageUrl } : {}),
              },
              data: {
                title,
                body,
                coupon_id: String(couponId),
                store_id: String(storeId),
                notification_type: "favorite_store_new_coupon",
                click_action: "FLUTTER_NOTIFICATION_CLICK",
                ...(imageUrl ? { image_url: imageUrl } : {}),
              },
              android: {
                priority: "HIGH",
                notification: {
                  channel_id: "high_importance_channel",
                  sound: "default",
                },
              },
              apns: {
                headers: { "apns-priority": "10" },
                payload: {
                  aps: { sound: "default" },
                },
              },
            },
          }),
        });
        const result = await resp.json();
        return { ok: resp.ok, status: resp.status, result };
      }),
    );

    await fetch(`${supabaseUrl}/rest/v1/notifications`, {
      method: "POST",
      headers: {
        ...restHeaders,
        Prefer: "return=minimal",
      },
      body: JSON.stringify(
        enabledFollowerIds.map((userId) => ({
          user_id: userId,
          title,
          body,
          image_url: imageUrl || null,
          is_broadcast: false,
        })),
      ),
    });

    const failed = sendResults.filter((result) => !result.ok);
    return json({
      success: failed.length < sendResults.length,
      followers: followerIds.length,
      enabledFollowers: enabledFollowerIds.length,
      sent: sendResults.length - failed.length,
      failed: failed.length,
      tokens: tokens.length,
      errors: failed.slice(0, 5),
    });
  } catch (err) {
    console.error("notify-favorite-store-followers error:", err);
    return json({ error: err.message || "Internal server error" }, 500);
  }
});
