const SUPABASE_URL = "https://YOUR-PROJECT-REF.supabase.co";
const SUPABASE_ANON_KEY = "YOUR-ANON-KEY";
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

const emailEl = document.getElementById("email");
const passwordEl = document.getElementById("password");
const loginBtn = document.getElementById("loginBtn");
const authMsg = document.getElementById("authMsg");
const authCard = document.getElementById("authCard");
const panel = document.getElementById("panel");
const machinesCard = document.getElementById("machinesCard");
const buyerSelect = document.getElementById("buyerSelect");
const machineSelect = document.getElementById("machineSelect");
const expiresAt = document.getElementById("expiresAt");
const genBtn = document.getElementById("genBtn");
const genMsg = document.getElementById("genMsg");
const licensesDiv = document.getElementById("licenses");
const activeMachinesDiv = document.getElementById("activeMachines");

function setAuthMsg(t){ authMsg.textContent = t || ""; }
function setGenMsg(t){ genMsg.textContent = t || ""; }

async function ensureSession() {
  const { data } = await supabase.auth.getSession();
  if (data.session) {
    authCard.style.display = "none";
    panel.style.display = "";
    machinesCard.style.display = "";
    await loadBuyers();
    await loadLicenses();
    await loadActiveMachines();
  }
}

async function login() {
  const email = emailEl.value.trim();
  const password = passwordEl.value;
  if (!email || !password) {
    setAuthMsg("Enter email and password");
    return;
  }
  setAuthMsg("Signing in...");
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) {
    setAuthMsg("Login failed");
    return;
  }
  setAuthMsg("");
  await ensureSession();
}

loginBtn.addEventListener("click", login);
ensureSession();

async function loadBuyers() {
  buyerSelect.innerHTML = "";
  const { data, error } = await supabase.from("buyers").select("id,name").order("name");
  if (error) { setGenMsg("Cannot load buyers"); return; }
  for (const b of data) {
    const opt = document.createElement("option");
    opt.value = b.id;
    opt.textContent = b.name;
    buyerSelect.appendChild(opt);
  }
  await loadMachinesForBuyer();
}

async function loadMachinesForBuyer() {
  const buyerId = buyerSelect.value;
  machineSelect.innerHTML = "";
  const empty = document.createElement("option");
  empty.value = "";
  empty.textContent = "(Optional) Bind to Machine";
  machineSelect.appendChild(empty);
  if (!buyerId) return;
  const { data, error } = await supabase.from("machines").select("id,machine_name,mac_address").eq("buyer_id", buyerId).order("machine_name");
  if (error) { return; }
  for (const m of data) {
    const opt = document.createElement("option");
    opt.value = m.id;
    opt.textContent = `${m.machine_name} (${m.mac_address})`;
    machineSelect.appendChild(opt);
  }
}

buyerSelect.addEventListener("change", loadMachinesForBuyer);

async function generateLicense() {
  const buyerId = buyerSelect.value;
  const mId = machineSelect.value || null;
  const expStr = expiresAt.value;
  if (!buyerId || !expStr) {
    setGenMsg("Select buyer and expiration");
    return;
  }
  setGenMsg("Generating...");
  const exp = new Date(expStr).toISOString();
  const { data, error } = await supabase.rpc("create_license", { buyer_id: buyerId, machine_id: mId, expires_at: exp });
  if (error) { setGenMsg("Failed to create license"); return; }
  setGenMsg(`License: ${data[0].key}`);
  await loadLicenses();
}

genBtn.addEventListener("click", generateLicense);

function renderLicenses(list) {
  const rows = list.map(l => {
    const status = l.is_revoked ? "revoked" : (new Date(l.expires_at) > new Date() ? "active" : "expired");
    const btn = l.is_revoked ? "" : `<button class="btn" data-id="${l.id}">Disable</button>`;
    return `<div style="display:flex;justify-content:space-between;gap:8px;padding:8px;border:1px solid #1f2b43;border-radius:8px;margin-bottom:8px">
      <div>
        <div><strong>${l.key}</strong> • ${status}</div>
        <div style="font-size:12px;opacity:.8">${l.buyer?.name || ""} • ${l.machine?.machine_name || ""} ${l.machine?.mac_address ? "(" + l.machine.mac_address + ")" : ""}</div>
        <div style="font-size:12px;opacity:.8">Expires: ${new Date(l.expires_at).toLocaleString()}</div>
      </div>
      <div>${btn}</div>
    </div>`;
  }).join("");
  licensesDiv.innerHTML = rows || "No licenses";
  licensesDiv.querySelectorAll("button[data-id]").forEach(btn => {
    btn.addEventListener("click", () => revokeLicense(btn.getAttribute("data-id")));
  });
}

async function loadLicenses() {
  const { data, error } = await supabase
    .from("licenses")
    .select(`id,key,expires_at,is_revoked,buyer:buyer_id(id,name),machine:machine_id(id,machine_name,mac_address)`)
    .order("created_at", { ascending: false })
    .limit(100);
  if (error) { licensesDiv.textContent = "Failed to load licenses"; return; }
  renderLicenses(data);
}

async function revokeLicense(id) {
  const { error } = await supabase.rpc("revoke_license", { license_id: id });
  if (error) { return; }
  await loadLicenses();
}

async function loadActiveMachines() {
  const { data, error } = await supabase
    .from("sessions")
    .select("machine_id, expiration_time, is_active, machine:machine_id(id,machine_name,mac_address,location)")
    .gt("expiration_time", new Date().toISOString())
    .eq("is_active", true)
    .order("expiration_time", { ascending: false })
    .limit(100);
  if (error) { activeMachinesDiv.textContent = "Failed to load active machines"; return; }
  const rows = (data || []).map(s => {
    const m = s.machine;
    return `${m?.machine_name || s.machine_id} (${m?.mac_address || ""}) • until ${new Date(s.expiration_time).toLocaleString()}`;
  });
  activeMachinesDiv.textContent = rows.join("\n") || "No active machines";
}
