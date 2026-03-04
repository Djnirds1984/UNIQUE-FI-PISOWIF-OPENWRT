const SUPABASE_URL = "https://YOUR-PROJECT-REF.supabase.co";
const SUPABASE_ANON_KEY = "YOUR-ANON-KEY";

async function hasActiveSession(client_mac) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/check_active_session`, {
    method: "POST",
    headers: {
      apikey: SUPABASE_ANON_KEY,
      Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({ client_mac })
  });
  if (!res.ok) return { is_active:false, seconds_left:0 };
  const data = await res.json();
  const row = Array.isArray(data) && data.length ? data[0] : null;
  if (!row) return { is_active:false, seconds_left:0 };
  return { is_active: !!row.is_active && row.seconds_left > 0, seconds_left: row.seconds_left|0, expiration_time: row.expiration_time };
}

async function isLicenseActive(license_key, machine_id) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/rpc/is_license_active`, {
    method: "POST",
    headers: {
      apikey: SUPABASE_ANON_KEY,
      Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({ license_key, machine_id })
  });
  if (!res.ok) return { active:false };
  const data = await res.json();
  const row = Array.isArray(data) && data.length ? data[0] : null;
  if (!row) return { active:false };
  return { active: !!row.active, expires_at: row.expires_at };
}

module.exports = { hasActiveSession, isLicenseActive };
