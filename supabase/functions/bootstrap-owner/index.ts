// One-shot: creates owner user + role. Safe to re-run.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const email = "owner@thepilito.ship";
  const password = "01278006248";

  // Find existing
  const { data: list } = await admin.auth.admin.listUsers();
  let user = list?.users?.find((u) => u.email === email);

  if (!user) {
    const { data, error } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: { full_name: "Owner" },
    });
    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 400, headers: { ...cors, "Content-Type": "application/json" },
      });
    }
    user = data.user!;
  } else {
    await admin.auth.admin.updateUserById(user.id, { password });
  }

  await admin.from("profiles").upsert({ id: user.id, full_name: "Owner" });
  await admin.from("user_roles").upsert(
    { user_id: user.id, role: "owner" },
    { onConflict: "user_id,role" },
  );

  return new Response(
    JSON.stringify({ ok: true, email, user_id: user.id }),
    { headers: { ...cors, "Content-Type": "application/json" } },
  );
});
