// Regenerates the README previews (docs/preview-*.png, 880x1680 @2x) with headless Edge
// driven over the DevTools protocol. Needs Node 22+ (global WebSocket/fetch) and the repo
// served on :4599 (`python -m http.server 4599`, the "static" entry in .claude/launch.json).
// Calls to the sync service are answered locally, so demo data never leaves the machine.
// usage: node tools/render-previews.js [OUT_DIR=docs] [shotName ...]
const { spawn } = require("child_process");
const fs = require("fs");
const path = require("path");
const OUT = process.argv[2] || path.join(__dirname, "..", "docs");
const ONLY = process.argv.slice(3);
const EDGE = "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe";
const PORT = 9333;
const APP = "http://localhost:4599/";
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Deterministic demo data, built in the page (so dates match "today").
const SEED = `(function (theme, progress, extra) {
  function dk(d){return d.getFullYear()+"-"+String(d.getMonth()+1).padStart(2,"0")+"-"+String(d.getDate()).padStart(2,"0");}
  function mon(d){var m=new Date(d);m.setHours(0,0,0,0);m.setDate(m.getDate()-((m.getDay()+6)%7));return m;}
  var now=new Date(), today=dk(now), H=3600;
  function obj(id,name,cad,goal,daily,spent,day,total,totalSpent){return {id:id,name:name,cadence:cad,goalSeconds:goal,dailyGoalSeconds:daily,spentSeconds:spent,daySpentSeconds:day,dayKey:today,running:false,startedAt:null,totalGoalSeconds:total||0,totalSpentSeconds:totalSpent||spent,totalStartKey:total?dk(new Date(now.getTime()-20*864e5)):null};}
  var objs=[
    obj("oa1","Linear Algebra course","weekly",5*H,H,2.5*H,0.5*H),
    obj("ob2","Spanish practice","daily",H,0,3*H,0.75*H),
    obj("oc3","Thesis writing","weekly",6*H,0,2*H,0.6*H,40*H,26.5*H),
    obj("od4","Deep reading","weekly",4*H,0,4*H,0)
  ];
  var pattern=[2.6,1.4,0.8,1.2,2.2,1.1,0.4,2.9,3.4,1.8,1.5,2.4,1.2,0.7,3.3,2.0,1.6,0,2.7,3.0,1.3,0.9,2.1,0,1.9,2.8,3.6,1.5,0.6,2.3,1.0,2.5,0,3.2,1.7];
  var dailyLog={}, dayGoals={};
  for (var i=1;i<pattern.length;i++){var d=new Date(now);d.setDate(d.getDate()-i);var k=dk(d);var s=Math.round(pattern[i]*H);dailyLog[k]=s;
    if(i<=14&&s>0){var a=Math.round(s*0.42),b=Math.min(Math.round(s*0.25),Math.round(1.2*H)),c=Math.round(s*0.2);dayGoals[k]={oa1:[a,H],ob2:[b,H],oc3:c,od4:s-a-b-c};}}
  dailyLog[today]=Math.round(1.85*H); dayGoals[today]={oa1:[0.5*H,H],ob2:[0.75*H,H],oc3:0.6*H};
  var wh={}, m=mon(now);
  [[0.78,0.6],[0.92,0.85],[0.64,0.5],[1,0.9],[0.71,0.66],[0.85,0.7]].forEach(function(f,w){var mm=new Date(m);mm.setDate(m.getDate()-7*(w+1));
    var o=[{name:"Linear Algebra course",goalSeconds:5*H,spentSeconds:Math.round(5*H*f[0])},{name:"Thesis writing",goalSeconds:6*H,spentSeconds:Math.round(6*H*f[1])},{name:"Deep reading",goalSeconds:4*H,spentSeconds:Math.round(4*H*f[0])}];
    var g=0,s=0;o.forEach(function(x){g+=x.goalSeconds;s+=Math.min(x.spentSeconds,x.goalSeconds);});wh[dk(mm)]={objectives:o,goalTotal:g,spentTotal:s};});
  var st={weekStart:dk(m),userName:"Ali",updatedAt:Date.now(),objectives:objs,dailyLog:dailyLog,dayGoals:dayGoals,
    goalNames:{oa1:"Linear Algebra course",ob2:"Spanish practice",oc3:"Thesis writing",od4:"Deep reading"},
    weekHistory:wh,excludeWeekends:true,streakMilestone:365,pomodoro:null,backups:[],lastDestructiveAt:0};
  if (extra) extra(st, now);
  localStorage.clear();
  localStorage.setItem("weekly-focus-timer-v1",JSON.stringify(st));
  localStorage.setItem("wft-theme",theme); localStorage.setItem("wft-progress",progress);
  if (st.__sync) localStorage.setItem("wft-sync-code", st.__sync);
})`;

const SHOTS = {
  "preview-dark": { theme: "dark", progress: "bar" },
  "preview-light": { theme: "light", progress: "ring" },
  "preview-sync": {
    theme: "dark", progress: "bar",
    extra: `function(st){st.__sync="WFT-K7PM-3QXD-9HWT";}`,
    after: `document.getElementById("settings-btn").click();`
  },
  "preview-pomodoro": {
    theme: "dark", progress: "bar",
    extra: `function(st,now){var t=now.getTime(),start=t-(32*60+14)*1000;var o=st.objectives[0];o.running=true;o.startedAt=start;
      st.pomodoro={id:"oa1",focusSec:1800,breakSec:600,hasTotal:false,totalFocusRemaining:0,phase:"focus",phaseStartedAt:start,phaseEndsAt:start+1800000,over:true,sessionStart:start-2400000,focusDone:1800,breakDone:600};}`,
    after: `document.querySelector(".card.pomo .fs-btn").click();`
  },
  "preview-day": {
    theme: "dark", progress: "bar",
    after: `document.getElementById("progress-btn").click();
      var cells=[...document.querySelectorAll("button.mcell")]; var t=cells.findIndex(c=>c.classList.contains("today"));
      (cells[t-1]||cells[0]).click();`
  },
  "preview-summary": {
    theme: "dark", progress: "bar",
    extra: `function(st,now){var t=now.getTime(),start=t-20*60000;var o=st.objectives[2];o.running=true;o.startedAt=start;
      st.pomodoro={id:"oc3",focusSec:1800,breakSec:600,hasTotal:false,totalFocusRemaining:0,phase:"focus",phaseStartedAt:start,phaseEndsAt:start+1800000,over:false,sessionStart:start-3600000,focusDone:3000,breakDone:600};}`,
    after: `[...document.querySelectorAll(".card.pomo button")].find(b=>b.textContent==="End session").click();`
  }
};

async function main() {
  const prof = fs.mkdtempSync(path.join(require("os").tmpdir(), "wft-previews-")); // fresh profile, or Edge hands off to a running instance
  const edge = spawn(EDGE, ["--headless=new", "--remote-debugging-port=" + PORT, "--user-data-dir=" + prof,
    "--no-first-run", "--hide-scrollbars", "--disable-extensions", "about:blank"], { stdio: "ignore" });
  let targets = null;
  for (let i = 0; i < 40 && !targets; i++) {
    await sleep(250);
    try { targets = await (await fetch(`http://127.0.0.1:${PORT}/json/list`)).json(); } catch (e) {}
  }
  const page = targets.find((t) => t.type === "page");
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise((r) => ws.addEventListener("open", r));
  let id = 0; const pending = {};
  ws.addEventListener("message", (ev) => {
    const m = JSON.parse(ev.data);
    if (m.id && pending[m.id]) { pending[m.id](m); delete pending[m.id]; }
    // Answer sync-service calls locally with an empty 200, so the UI shows a healthy
    // connection while no demo data ever leaves this machine.
    if (m.method === "Fetch.requestPaused") {
      send("Fetch.fulfillRequest", { requestId: m.params.requestId, responseCode: 200,
        responseHeaders: [{ name: "Access-Control-Allow-Origin", value: "*" }, { name: "Content-Type", value: "text/plain" }], body: "" }).catch(() => {});
    }
  });
  const send = (method, params = {}) => new Promise((res, rej) => { const i = ++id; pending[i] = (m) => m.error ? rej(new Error(method + ": " + m.error.message)) : res(m.result); ws.send(JSON.stringify({ id: i, method, params })); });
  const evalJs = async (expr) => { const r = await send("Runtime.evaluate", { expression: expr, awaitPromise: true, returnByValue: true }); if (r.exceptionDetails) throw new Error(JSON.stringify(r.exceptionDetails)); return r.result.value; };

  await send("Page.enable"); await send("Runtime.enable"); await send("Network.enable");
  await send("Fetch.enable", { patterns: [{ urlPattern: "*textdb*" }] }); // intercepted above; never reaches the network
  await send("Emulation.setDeviceMetricsOverride", { width: 880, height: 1680, deviceScaleFactor: 2, mobile: false });
  await send("Page.navigate", { url: APP }); await sleep(1500);

  for (const [name, s] of Object.entries(SHOTS)) {
    if (ONLY.length && !ONLY.includes(name)) continue;
    await send("Emulation.setEmulatedMedia", { features: [{ name: "prefers-color-scheme", value: s.theme }] });
    await evalJs(`${SEED}(${JSON.stringify(s.theme)}, ${JSON.stringify(s.progress)}, ${s.extra || "null"})`);
    await send("Page.reload", { ignoreCache: true }); await sleep(1800);
    if (s.after) { await evalJs(s.after); await sleep(900); }
    const shot = await send("Page.captureScreenshot", { format: "png" });
    fs.writeFileSync(path.join(OUT, name + ".png"), Buffer.from(shot.data, "base64"));
    console.log("wrote", name);
  }
  await evalJs("localStorage.clear()");
  ws.close(); edge.kill();
}
main().catch((e) => { console.error(e); process.exit(1); });
