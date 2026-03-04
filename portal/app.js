const SUPABASE_URL = "https://YOUR-PROJECT-REF.supabase.co";
const SUPABASE_ANON_KEY = "YOUR-ANON-KEY";
const supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

const qs = new URLSearchParams(location.search);
const machineId = qs.get("machine_id") || "";
const clientMac = qs.get("client_mac") || "";
const licenseKey = qs.get("license") || "";

const statusEl = document.getElementById("status");
const timeEl = document.getElementById("time");
const msgEl = document.getElementById("message");
const coinBtn = document.getElementById("coinBtn");
const redeemBtn = document.getElementById("redeemBtn");
const voucherInput = document.getElementById("voucherCode");

let countdownTimer = null;
let lastExpiration = null;
let salesChannel = null;

function fmtSeconds(s) {
  const v = Math.max(0, s|0);
  const h = Math.floor(v/3600);
  const m = Math.floor((v%3600)/60);
  const sec = v%60;
  if (h>0) return [h,m,sec].map(n=>String(n).padStart(2,"0")).join(":");
  return [m,sec].map(n=>String(n).padStart(2,"0")).join(":");
}

function setStatus(connected) {
  statusEl.textContent = connected ? "Connected" : "Disconnected";
  statusEl.classList.toggle("ok", connected);
  statusEl.classList.toggle("bad", !connected);
}

function setMessage(t) {
  msgEl.textContent = t || "";
}

function startCountdown(secondsLeft, expiration) {
  if (countdownTimer) clearInterval(countdownTimer);
  lastExpiration = expiration ? new Date(expiration) : new Date(Date.now() + secondsLeft*1000);
  function tick() {
    const remaining = Math.max(0, Math.floor((lastExpiration.getTime() - Date.now())/1000));
    timeEl.textContent = "Time Remaining: " + fmtSeconds(remaining);
    setStatus(remaining > 0);
    if (remaining <= 0) clearInterval(countdownTimer);
  }
  tick();
  countdownTimer = setInterval(tick, 1000);
}

async function checkLicense() {
  if (!licenseKey) return { active: true };
  const { data, error } = await supabase.rpc("is_license_active", { license_key: licenseKey, machine_id: machineId || null });
  if (error) return { active: false };
  const row = Array.isArray(data) && data.length ? data[0] : null;
  if (!row || !row.active) {
    setStatus(false);
    setMessage("License Expired");
    coinBtn.disabled = true;
    redeemBtn.disabled = true;
    return { active: false };
  }
  coinBtn.disabled = false;
  redeemBtn.disabled = false;
  return row;
}

async function checkActive() {
  if (!clientMac) {
    setMessage("Missing client_mac");
    setStatus(false);
    timeEl.textContent = "Time Remaining: 00:00";
    return { is_active:false, seconds_left:0 };
  }
  const lic = await checkLicense();
  if (!lic.active) return { is_active:false, seconds_left:0 };
  const { data, error } = await supabase.rpc("check_active_session", { client_mac: clientMac });
  if (error) {
    setMessage("Error checking status");
    setStatus(false);
    timeEl.textContent = "Time Remaining: 00:00";
    return { is_active:false, seconds_left:0 };
  }
  const row = Array.isArray(data) && data.length ? data[0] : null;
  if (row && row.is_active && row.seconds_left > 0) {
    startCountdown(row.seconds_left, row.expiration_time);
    setMessage("");
    return row;
  } else {
    setStatus(false);
    timeEl.textContent = "Time Remaining: 00:00";
    return { is_active:false, seconds_left:0 };
  }
}

async function redeemVoucher() {
  const code = voucherInput.value.trim();
  if (!code) {
    setMessage("Enter a voucher code");
    return;
  }
  if (!clientMac) {
    setMessage("Missing client_mac");
    return;
  }
  if (!machineId) {
    setMessage("Missing machine_id");
    return;
  }
  const lic = await checkLicense();
  if (!lic.active) return;
  setMessage("Redeeming...");
  const { data, error } = await supabase.rpc("redeem_voucher", { code, client_mac: clientMac, machine_id: machineId });
  if (error) {
    setMessage("Invalid or used voucher");
    return;
  }
  const row = Array.isArray(data) && data.length ? data[0] : null;
  if (row) {
    startCountdown(row.seconds_left, row.expiration_time);
    setMessage("Voucher redeemed");
  } else {
    await checkActive();
  }
}

function listenForCoins() {
  if (!machineId) {
    setMessage("Missing machine_id");
    return;
  }
  if (salesChannel) {
    supabase.removeChannel(salesChannel);
    salesChannel = null;
  }
  setMessage("Waiting for coin...");
  salesChannel = supabase
    .channel("sales-"+machineId)
    .on("postgres_changes", { event: "INSERT", schema: "public", table: "sales", filter: "machine_id=eq."+machineId }, async () => {
      const lic = await checkLicense();
      if (!lic.active) {
        setMessage("License Expired");
        return;
      }
      setMessage("Coin detected");
      await checkActive();
    })
    .subscribe((status) => {
      if (status === "SUBSCRIBED") setMessage("Listening for coins");
    });
}

coinBtn.addEventListener("click", listenForCoins);
redeemBtn.addEventListener("click", redeemVoucher);

checkLicense().then(() => checkActive());
setInterval(checkActive, 10000);
