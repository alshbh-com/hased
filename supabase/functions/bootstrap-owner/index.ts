// One-shot: creates owner user + role. Safe to re-run.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function codeToEmail(code: string): string {
  return code.replace(/@/g, "_at_").replace(/[^a-zA-Z0-9._-]/g, "_") + "@thepilito.ship";
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response(null, { headers: cors });

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const password = "01278006248";
  const email = codeToEmail(password);

  // Remove any old owner accounts with mismatched emails
  const { data: list } = await admin.auth.admin.listUsers();
  for (const u of list?.users ?? []) {
    if (u.email && u.email.endsWith("@thepilito.ship") && u.email !== email) {
      const { data: roles } = await admin.from("user_roles").select("role").eq("user_id", u.id);
      if (roles?.some((r: any) => r.role === "owner")) {
        await admin.from("user_roles").delete().eq("user_id", u.id);
        await admin.auth.admin.deleteUser(u.id);
      }
    }
  }

  let user = (await admin.auth.admin.listUsers()).data?.users?.find((u) => u.email === email);

  if (!user) {
    const { data, error } = await admin.auth.admin.createUser({
      email, password, email_confirm: true, user_metadata: { full_name: "المالك" },
    });
    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 400, headers: { ...cors, "Content-Type": "application/json" },
      });
    }
    user = data.user!;
  } else {
    await admin.auth.admin.updateUserById(user.id, { password, email_confirm: true });
  }

  await admin.from("profiles").upsert({ id: user.id, full_name: "المالك", login_code: password });
  await admin.from("user_roles").upsert(
    { user_id: user.id, role: "owner" },
    { onConflict: "user_id,role" },
  );

  return new Response(
    JSON.stringify({ ok: true, email, user_id: user.id }),
    { headers: { ...cors, "Content-Type": "application/json" } },
  );
});
