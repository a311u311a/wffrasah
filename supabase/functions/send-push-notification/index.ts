import "@supabase/functions-js/edge-runtime.d.ts";

/**
 * Supabase Edge Function: send-push-notification
 *
 * Sends a push notification via Firebase Cloud Messaging (FCM) HTTP v1 API.
 * The Firebase Service Account key is stored securely in Supabase Secrets,
 * NOT in the client app code.
 *
 * Required Supabase Secrets:
 *   FCM_SERVICE_ACCOUNT  – Full JSON string of the Firebase service account key
 *
 * Request body (JSON):
 *   { "title": "...", "body": "...", "imageUrl": "..." (optional) }
 */

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

// --- Google OAuth2 JWT helpers (Deno-native, no npm deps) ---

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
    ["sign"]
  );
}

async function createSignedJwt(
  serviceAccount: { client_email: string; private_key: string }
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
    enc.encode(signingInput)
  );

  return `${signingInput}.${base64url(signature)}`;
}

async function getAccessToken(
  serviceAccount: { client_email: string; private_key: string }
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
    throw new Error(`Token exchange failed: ${resp.status} – ${errText}`);
  }

  const data = await resp.json();
  return data.access_token;
}

// --- Main handler ---

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    // 1. Parse request body
    const { title, body, imageUrl } = await req.json();

    if (!title || !body) {
      return json({ error: "title and body are required" }, 400);
    }

    // 2. Load service account from Supabase Secrets
    const serviceAccountStr = Deno.env.get("FCM_SERVICE_ACCOUNT");
    if (!serviceAccountStr) {
      return json({ error: "FCM_SERVICE_ACCOUNT secret is not configured" }, 500);
    }

    const serviceAccount = JSON.parse(serviceAccountStr);
    const projectId = serviceAccount.project_id;

    // 3. Get access token using JWT
    const accessToken = await getAccessToken(serviceAccount);

    const fcmUrl =
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
    const fcmHeaders = {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    };

    const buildMessage = (target: { topic?: string; token?: string }) => ({
      message: {
        ...target,
        notification: {
          title,
          body,
          ...(imageUrl ? { image: imageUrl } : {}),
        },
        data: {
          title,
          body,
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
        webpush: {
          notification: {
            title,
            body,
            icon: "/icons/icon-192.png",
            ...(imageUrl ? { image: imageUrl } : {}),
          },
        },
      },
    });

    const sendFcm = async (target: { topic?: string; token?: string }) => {
      const resp = await fetch(fcmUrl, {
        method: "POST",
        headers: fcmHeaders,
        body: JSON.stringify(buildMessage(target)),
      });
      const result = await resp.json();
      return { ok: resp.ok, status: resp.status, result };
    };

    const topicResult = await sendFcm({ topic: "all" });

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    let webResults: Array<{ ok: boolean; status: number; result: unknown }> = [];

    if (supabaseUrl && serviceRoleKey) {
      const tokensResp = await fetch(
        `${supabaseUrl}/rest/v1/fcm_tokens?is_enabled=eq.true&select=token`,
        {
          headers: {
            apikey: serviceRoleKey,
            Authorization: `Bearer ${serviceRoleKey}`,
          },
        }
      );

      if (tokensResp.ok) {
        const rows = await tokensResp.json();
        const tokens = Array.isArray(rows)
          ? rows.map((row) => row.token).filter(Boolean)
          : [];

        webResults = await Promise.all(
          tokens.map((token) => sendFcm({ token }))
        );
      }
    }

    const failedWeb = webResults.filter((result) => !result.ok);
    const success = topicResult.ok || webResults.some((result) => result.ok);

    return json({
      success,
      topic: topicResult,
      web: {
        sent: webResults.length - failedWeb.length,
        failed: failedWeb.length,
        errors: failedWeb.slice(0, 5),
      },
    }, success ? 200 : topicResult.status);
  } catch (err) {
    console.error("send-push-notification error:", err);
    return json({ error: err.message || "Internal server error" }, 500);
  }
});
