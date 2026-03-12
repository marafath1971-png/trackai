import React, { useState, useRef, useEffect, useCallback, useMemo } from "react";

/* ══════════════════════════════════════════════
   CONSTANTS & UTILS
══════════════════════════════════════════════ */
const MODEL = "claude-sonnet-4-20250514";

const PROMO_CODES = {
  "WELCOME": { discount: 100, label: "Free 30 days", type: "trial" },
  "HEALTH50": { discount: 50, label: "50% off first month", type: "percent" },
  "PILL30": { discount: 30, label: "30% off", type: "percent" },
  "MEDTRACK": { discount: 100, label: "Free 14 days", type: "trial" },
  "FRIEND": { discount: 20, label: "20% off forever", type: "forever" },
};

const PILL_COLORS = ["#10B981","#3B82F6","#8B5CF6","#F59E0B","#EF4444","#14B8A6","#EC4899","#F97316"];
const DAYS7 = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
const DAYS7_SHORT = ["S","M","T","W","T","F","S"];

const todayStr = () => new Date().toISOString().slice(0,10);
const dayIdx = () => new Date().getDay();
const fmt = (h,m) => `${h%12||12}:${String(m).padStart(2,"0")} ${h>=12?"PM":"AM"}`;
const greet = () => { const h=new Date().getHours(); return h<12?"Good morning":h<17?"Good afternoon":"Good evening"; };
const f2b64 = f => new Promise((res,rej) => { const r=new FileReader(); r.onload=()=>res(r.result.split(",")[1]); r.onerror=rej; r.readAsDataURL(f); });
const nowMins = () => new Date().getHours()*60+new Date().getMinutes();

/* ══════════════════════════════════════════════
   GLOBAL CSS
══════════════════════════════════════════════ */
const GLOBAL_CSS = `
  @import url('https://fonts.googleapis.com/css2?family=Figtree:wght@300;400;500;600;700;800;900&display=swap');
  * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
  body { margin: 0; background: #F5F5F5; font-family: 'Figtree', -apple-system, 'Helvetica Neue', Arial, sans-serif; }
  ::-webkit-scrollbar { display: none; }
  
  @keyframes slideInRight { from { transform: translateX(40px); opacity: 0; } to { transform: translateX(0); opacity: 1; } }
  @keyframes slideInLeft  { from { transform: translateX(-40px); opacity: 0; } to { transform: translateX(0); opacity: 1; } }
  @keyframes slideInUp    { from { transform: translateY(30px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
  @keyframes slideInDown  { from { transform: translateY(-30px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
  @keyframes fadeIn       { from { opacity: 0; } to { opacity: 1; } }
  @keyframes popIn        { 0% { transform: scale(0.8); opacity: 0; } 70% { transform: scale(1.05); } 100% { transform: scale(1); opacity: 1; } }
  @keyframes bounceCheck  { 0% { transform: scale(0); } 50% { transform: scale(1.3); } 100% { transform: scale(1); } }
  @keyframes ripple       { 0% { transform: scale(0); opacity: 0.6; } 100% { transform: scale(2.5); opacity: 0; } }
  @keyframes shimmer      { 0% { background-position: -200% center; } 100% { background-position: 200% center; } }
  @keyframes flame        { 0%,100% { transform: rotate(-3deg) scale(1); } 50% { transform: rotate(3deg) scale(1.08); } }
  @keyframes floatUp      { 0%,100% { transform: translateY(0); } 50% { transform: translateY(-6px); } }
  @keyframes pulseDot     { 0%,100% { transform: scale(1); opacity: 1; } 50% { transform: scale(1.4); opacity: 0.7; } }
  @keyframes confettiFall { 0% { transform: translateY(-20px) rotate(0deg); opacity: 1; } 100% { transform: translateY(110vh) rotate(720deg); opacity: 0; } }
  @keyframes celebPop     { 0% { transform: scale(0.5) translateY(20px); opacity: 0; } 60% { transform: scale(1.05); } 100% { transform: scale(1); opacity: 1; } }
  @keyframes notifSlide   { from { transform: translateX(-50%) translateY(-120%); opacity: 0; } to { transform: translateX(-50%) translateY(0); opacity: 1; } }
  @keyframes progressFill { from { width: 0%; } to { width: var(--w); } }
  @keyframes checkDraw    { 0% { stroke-dashoffset: 50; } 100% { stroke-dashoffset: 0; } }
  @keyframes glowPulse    { 0%,100% { box-shadow: 0 0 20px rgba(163,230,53,0.3); } 50% { box-shadow: 0 0 40px rgba(163,230,53,0.6); } }
  @keyframes streakBounce { 0% { transform: scale(0.5) rotate(-10deg); } 60% { transform: scale(1.2) rotate(5deg); } 100% { transform: scale(1) rotate(0); } }
  @keyframes typewriter   { from { width: 0; } to { width: 100%; } }
  @keyframes spin         { to { transform: rotate(360deg); } }
  @keyframes bgFloat      { 0%,100% { transform: translateY(0) scale(1); } 50% { transform: translateY(-20px) scale(1.05); } }
  @keyframes scanLine     { 0% { top: 10%; } 100% { top: 85%; } }
  @keyframes stagger1 { from { opacity:0; transform:translateY(20px); } to { opacity:1; transform:translateY(0); } }
  @keyframes stagger2 { from { opacity:0; transform:translateY(20px); } to { opacity:1; transform:translateY(0); } }
  @keyframes stagger3 { from { opacity:0; transform:translateY(20px); } to { opacity:1; transform:translateY(0); } }
  
  .ob-animate { animation: slideInRight 0.35s cubic-bezier(0.25,0.46,0.45,0.94) forwards; }
  .ob-animate-left { animation: slideInLeft 0.35s cubic-bezier(0.25,0.46,0.45,0.94) forwards; }
  .pulse-cta { animation: glowPulse 2.5s ease-in-out infinite; }
  .flame-icon { animation: flame 1.2s ease-in-out infinite; }
  .float-icon { animation: floatUp 3s ease-in-out infinite; }
  .s1 { animation: stagger1 0.4s 0.1s both; }
  .s2 { animation: stagger2 0.4s 0.2s both; }
  .s3 { animation: stagger3 0.4s 0.3s both; }
  

  @keyframes iosSpring   { 0% { transform: scale(0.85) translateY(40px); opacity: 0; } 60% { transform: scale(1.02) translateY(-4px); opacity: 1; } 80% { transform: scale(0.99); } 100% { transform: scale(1) translateY(0); opacity: 1; } }
  @keyframes iosSlideUp  { from { transform: translateY(100%); opacity: 0; } to { transform: translateY(0); opacity: 1; } }
  @keyframes iosFadeScale { 0% { opacity: 0; transform: scale(0.96); } 100% { opacity: 1; transform: scale(1); } }
  @keyframes iosBounce   { 0%,100% { transform: scale(1); } 40% { transform: scale(0.94); } 70% { transform: scale(1.04); } }

  button:active { transform: scale(0.97); opacity: 0.88; transition: transform 0.08s, opacity 0.08s; }
  input { -webkit-appearance: none; appearance: none; }
  select { -webkit-appearance: none; appearance: none; }
  
  .ios-sheet { animation: iosSlideUp 0.38s cubic-bezier(0.32,0.72,0,1) forwards; }
  .ios-spring { animation: iosSpring 0.5s cubic-bezier(0.34,1.56,0.64,1) forwards; }
  .ios-fade   { animation: iosFadeScale 0.22s ease-out forwards; }
  
  input[type=number]::-webkit-inner-spin-button,
  input[type=number]::-webkit-outer-spin-button { -webkit-appearance: none; }
  .ob-opt:active { transform: scale(0.96); opacity: 0.8; }
  .ob-opt.sel { animation: popIn 0.25s forwards; }
  @keyframes doseCheck { 0%{transform:scale(1)} 40%{transform:scale(1.06)} 100%{transform:scale(1)} }
  @keyframes toastSlide { from{transform:translateX(-50%) translateY(100px);opacity:0} to{transform:translateX(-50%) translateY(0);opacity:1} }
  .dose-taken { animation: doseCheck 0.35s cubic-bezier(0.34,1.56,0.64,1) forwards; }
`;

/* ══════════════════════════════════════════════
   DESIGN TOKENS
══════════════════════════════════════════════ */
const D = {
  bg: "#0A0A0F", card: "#13131A", border: "#1E1E2A", text: "#F0F0F5", sub: "#8080A0",
  lime: "#A3E635", limeDark: "#84CC16", limeDim: "rgba(163,230,53,0.12)",
  green: "#10B981", greenLight: "#D1FAE5",
  red: "#EF4444", redLight: "#FEE2E2",
  amber: "#F59E0B", amberLight: "#FEF3C7",
  blue: "#3B82F6", blueLight: "#EFF6FF",
  purple: "#8B5CF6", purpleLight: "#EDE9FE",
};
const L_LIGHT = {
  bg: "#F5F5F5",
  card: "#FFFFFF",
  card2: "#FAFAFA",
  border: "rgba(0,0,0,0.08)",
  text: "#111111",
  sub: "rgba(0,0,0,0.45)",
  sub2: "rgba(0,0,0,0.25)",
  fill: "rgba(0,0,0,0.06)",
  fill2: "rgba(0,0,0,0.03)",
  green: "#22C55E",
  greenDark: "#16A34A",
  greenLight: "#DCFCE7",
  teal: "#06B6D4",
  red: "#EF4444",
  redLight: "#FEE2E2",
  amber: "#F97316",
  amberLight: "#FFF0E6",
  blue: "#3B82F6",
  blueLight: "#EFF6FF",
  purple: "#8B5CF6",
  purpleLight: "#EDE9FE",
  indigo: "#6366F1",
  pink: "#EC4899",
  accent: "#111111",
  accentText: "#FFFFFF",
};
const L_DARK = {
  bg: "#0A0A0F", card: "#1C1C1E", card2: "#2C2C2E",
  border: "rgba(255,255,255,0.12)", text: "#FFFFFF",
  sub: "rgba(255,255,255,0.55)", sub2: "rgba(255,255,255,0.28)",
  fill: "rgba(255,255,255,0.08)", fill2: "rgba(255,255,255,0.05)",
  green: "#34C759", greenDark: "#248A3D", greenLight: "rgba(52,199,89,0.15)",
  teal: "#5AC8FA", red: "#FF453A", redLight: "rgba(255,69,58,0.18)",
  amber: "#FF9F0A", amberLight: "rgba(255,159,10,0.15)",
  blue: "#0A84FF", blueLight: "rgba(10,132,255,0.15)",
  purple: "#BF5AF2", purpleLight: "rgba(191,90,242,0.15)",
  indigo: "#5E5CE6", pink: "#FF375F",
};
const ThemeContext = React.createContext(L_LIGHT);
const useTheme = () => React.useContext(ThemeContext);

/* ══════════════════════════════════════════════
   ICONS
══════════════════════════════════════════════ */
const Ic = ({d,size=20,c="currentColor",w=1.6,fill="none"}) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill={fill} stroke={c} strokeWidth={w} strokeLinecap="round" strokeLinejoin="round">
    {Array.isArray(d)?d.map((p,i)=><path key={i} d={p}/>):<path d={d}/>}
  </svg>
);
const ic = {
  home:"M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z M9 22V12h6v10",
  camera:["M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z","M12 17a4 4 0 1 0 0-8 4 4 0 0 0 0 8z"],
  bell:["M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9","M13.73 21a2 2 0 0 1-3.46 0"],
  check:"M20 6L9 17l-5-5",
  plus:"M12 5v14 M5 12h14",
  minus:"M5 12h14",
  edit:["M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7","M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"],
  trash:"M3 6h18 M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2",
  back:"M15 18l-6-6 6-6",
  x:"M18 6L6 18 M6 6l12 12",
  sparkle:"M12 3l1.912 5.813a2 2 0 0 0 1.275 1.275L21 12l-5.813 1.912a2 2 0 0 0-1.275 1.275L12 21l-1.912-5.813a2 2 0 0 0-1.275-1.275L3 12l5.813-1.912a2 2 0 0 0 1.275-1.275L12 3z",
  upload:"M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4 M17 8l-5-5-5 5 M12 3v12",
  redo:"M21 2v6h-6 M3 12a9 9 0 0 1 15-6.7L21 8",
  history:"M3 3v5h5 M3.05 13A9 9 0 1 0 6 5.3L3 8",
  star:["M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"],
  trophy:"M6 9H4.5a2.5 2.5 0 0 1 0-5H6 M18 9h1.5a2.5 2.5 0 0 0 0-5H18 M4 22h16 M18 2H6v7a6 6 0 0 0 12 0V2z",
  shield:"M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z",
  crown:"M2 20h20 M5 20V10l7-7 7 7v10",
  zap:"M13 2L3 14h9l-1 8 10-12h-9l1-8z",
  heart:"M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z",
  clock:"M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10z M12 6v6l4 2",
  tag:"M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z M7 7h.01",
  gift:["M20 12v10H4V12","M2 7h20v5H2z","M12 22V7","M12 7H7.5a2.5 2.5 0 0 1 0-5C11 2 12 7 12 7z","M12 7h4.5a2.5 2.5 0 0 0 0-5C13 2 12 7 12 7z"],
  lock:"M19 11H5a2 2 0 0 0-2 2v7a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7a2 2 0 0 0-2-2z M7 11V7a5 5 0 0 1 10 0v4",
  unlock:"M19 11H5a2 2 0 0 0-2 2v7a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7a2 2 0 0 0-2-2z M7 11V7a5 5 0 0 1 9.9-1",
  pill:["M4.5 13.5l6-6","M12 3a4.24 4.24 0 0 1 6 6l-9 9a4.24 4.24 0 0 1-6-6l9-9"],
  chart:["M18 20V10","M12 20V4","M6 20v-6"],
  user:"M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2 M12 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8z",
  users:"M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2 M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8z M23 21v-2a4 4 0 0 0-3-3.87 M16 3.13a4 4 0 0 1 0 7.75",
  phone:"M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07A19.5 19.5 0 0 1 4.69 13a19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 3.6 2h3a2 2 0 0 1 2 1.72 12.05 12.05 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.05 12.05 0 0 0 2.81.7A2 2 0 0 1 22 16.92z",
  send:"M22 2L11 13 M22 2L15 22l-4-9-9-4 22-7z",
  alertTri:"M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z M12 9v4 M12 17h.01",
  settings:["M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z","M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"],
  chevron:"M9 18l6-6-6-6",
  moon:"M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z",
  sun:["M12 1v2","M12 21v2","M4.22 4.22l1.42 1.42","M18.36 18.36l1.42 1.42","M1 12h2","M21 12h2","M4.22 19.78l1.42-1.42","M18.36 5.64l1.42-1.42","M12 17a5 5 0 1 0 0-10 5 5 0 0 0 0 10z"],
  download:"M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4 M7 10l5 5 5-5 M12 15V3",
  info:"M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10z M12 8h.01 M12 12v4",
  eyeOff:["M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94","M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19","M1 1l22 22"],
  profile:"M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2 M12 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8z",
  medkit:["M22 9h-4V7a2 2 0 0 0-2-2H8a2 2 0 0 0-2 2v2H2a1 1 0 0 0-1 1v8a1 1 0 0 0 1 1h20a1 1 0 0 0 1-1v-8a1 1 0 0 0-1-1z","M10 13h4 M12 11v4"],
};



/* ══════════════════════════════════════════════
   SHARED ATOMS
══════════════════════════════════════════════ */
const Badge = ({children,bg,color,sx={}}) => (
  <span style={{background:bg,color,fontSize:11,fontWeight:600,letterSpacing:"-0.1px",padding:"3px 10px",borderRadius:99,fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",...sx}}>{children}</span>
);

const DarkInp = ({label,value,onChange,placeholder,type="text",suffix}) => (
  <div style={{display:"flex",flexDirection:"column",gap:6}}>
    {label&&<label style={{fontSize:11,fontWeight:700,letterSpacing:"0.08em",textTransform:"uppercase",color:D.sub}}>{label}</label>}
    <div style={{position:"relative"}}>
      <input type={type} value={value} onChange={onChange} placeholder={placeholder}
        style={{width:"100%",padding:"15px 16px",background:"rgba(255,255,255,0.1)",border:"none",boxShadow:"inset 0 0 0 1px rgba(255,255,255,0.12)",borderRadius:12,fontSize:16,color:D.text,outline:"none",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",WebkitAppearance:"none",paddingRight:suffix?48:16}}/>
      {suffix&&<span style={{position:"absolute",right:16,top:"50%",transform:"translateY(-50%)",color:D.sub,fontSize:13}}>{suffix}</span>}
    </div>
  </div>
);

function LightInp({label,value,onChange,placeholder,type="text",sx={}}) {
  const L=useTheme();
  return(<div style={{display:"flex",flexDirection:"column",gap:5}}>
    {label&&<label style={{fontSize:11,fontWeight:700,letterSpacing:"0.07em",textTransform:"uppercase",color:L.sub,marginBottom:0}}>{label}</label>}
    <input type={type} value={value} onChange={onChange} placeholder={placeholder}
      style={{padding:"12px 14px",background:L.fill,boxShadow:"inset 0 0 0 1px "+L.border,borderRadius:12,border:"none",outline:"none",fontSize:15,color:L.text,fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",...sx}}/>
  </div>);
}

function Lbl({children,dark}) {
  const L=useTheme();
  return(<p style={{fontSize:18,fontWeight:800,letterSpacing:"-0.3px",textTransform:"none",color:L.text,margin:"0 0 12px",paddingLeft:0,fontFamily:"'Figtree',-apple-system,sans-serif"}}>{children}</p>);
}

function IRow({label,value,bold}) {
  const L=useTheme();
  return(<div style={{display:"flex",gap:10,paddingTop:2,paddingBottom:2}}>
    <span style={{fontSize:14,color:L.sub,minWidth:96,paddingTop:1,flexShrink:0}}>{label}</span>
    <span style={{fontSize:14,color:L.text,fontWeight:bold?600:400,flex:1,lineHeight:1.5}}>{value}</span>
  </div>);
}

function Ring({pct=0,size=140,sw=10,color,bgColor,label,sub}) {
  const L=useTheme();
  color=color||L.green; bgColor=bgColor||"rgba(120,120,128,0.12)";
  const r=(size-sw*2)/2, circ=2*Math.PI*r, dash=circ*Math.min(1,Math.max(0,pct));
  return(
    <div style={{position:"relative",width:size,height:size,flexShrink:0}}>
      <svg width={size} height={size} style={{transform:"rotate(-90deg)"}}>
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={bgColor} strokeWidth={sw}/>
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={color} strokeWidth={sw}
          strokeLinecap="round" strokeDasharray={`${dash} ${circ}`} style={{transition:"stroke-dasharray 0.7s cubic-bezier(0.4,0,0.2,1)"}}/>
      </svg>
      <div style={{position:"absolute",inset:0,display:"flex",flexDirection:"column",alignItems:"center",justifyContent:"center"}}>
        {label&&<span style={{fontSize:size>100?22:16,fontWeight:700,color:L.text,lineHeight:1,letterSpacing:"-0.5px",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>{label}</span>}
        {sub&&<span style={{fontSize:10,color:L.sub,fontWeight:500,marginTop:2,letterSpacing:"-0.1px"}}>{sub}</span>}
      </div>
    </div>
  );
}

/* ══════════════════════════════════════════════
   PRODUCTION ATOMS — Toast, ActionSheet, Toggle, Skeleton, Settings
══════════════════════════════════════════════ */

// ── iOS Toggle Switch ──
function Toggle({on,onChange,color}) {
  const L=useTheme();
  const c=color||L.blue;
  return(
  <div onClick={()=>onChange(!on)} style={{width:51,height:31,borderRadius:99,background:on?c:"rgba(120,120,128,0.32)",position:"relative",cursor:"pointer",transition:"background 0.25s cubic-bezier(0.4,0,0.2,1)",flexShrink:0}}>
    <div style={{position:"absolute",top:2,left:on?22:2,width:27,height:27,borderRadius:99,background:"#fff",transition:"left 0.25s cubic-bezier(0.34,1.56,0.64,1)",boxShadow:"0 2px 6px rgba(0,0,0,0.25)"}}/>
  </div>
  );
}

// ── Settings Row ──
function SettingsRow({icon,color="#007AFF",label,sub,right,onClick,last}) {
  const L=useTheme();
  return(
  <div onClick={onClick} style={{display:"flex",alignItems:"center",gap:13,padding:"13px 16px",background:L.card,cursor:onClick?"pointer":"default",borderBottom:last?"none":"0.5px solid "+L.border}}>
    {icon&&<div style={{width:30,height:30,borderRadius:8,background:color,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}>
      <Ic d={icon} size={16} c="#fff" w={1.8}/>
    </div>}
    <div style={{flex:1,minWidth:0}}>
      <p style={{margin:0,fontSize:16,color:L.text}}>{label}</p>
      {sub&&<p style={{margin:"1px 0 0",fontSize:13,color:L.sub}}>{sub}</p>}
    </div>
    {right&&<div style={{display:"flex",alignItems:"center",gap:6,flexShrink:0}}>{right}</div>}
    {onClick&&!right&&<Ic d={ic.chevron} size={16} c={L.sub}/>}
  </div>
  );
}

// ── Toast notification ──
function Toast({message,type="success",onDone}) {
  useEffect(()=>{const t=setTimeout(()=>{if(onDone)onDone();},3000);return()=>clearTimeout(t);},[message]);
  const icon = type==="error"?"✕":type==="warning"?"⚠":type==="info"?"ℹ":"✓";
  return(
    <div style={{position:"fixed",bottom:108,left:"50%",transform:"translateX(-50%)",zIndex:5000,animation:"slideInUp 0.35s cubic-bezier(0.34,1.56,0.64,1) forwards",pointerEvents:"none"}}>
      {/* Cal AI: pure black pill toast */}
      <div style={{background:"#111",borderRadius:99,padding:"12px 20px",display:"flex",alignItems:"center",gap:8,boxShadow:"0 8px 32px rgba(0,0,0,0.22)",whiteSpace:"nowrap"}}>
        <span style={{fontSize:14,color:"#fff",fontWeight:700}}>{icon} {message}</span>
      </div>
    </div>
  );
}

// ── iOS Action Sheet (destructive confirmation) ──
function ActionSheet({title,sub,actions,onCancel}) {
  const L=useTheme();
  return(
    <div style={{position:"fixed",inset:0,background:"rgba(0,0,0,0.4)",zIndex:3000,display:"flex",flexDirection:"column",justifyContent:"flex-end",padding:"0 8px 8px",backdropFilter:"blur(6px)",WebkitBackdropFilter:"blur(6px)"}} onClick={onCancel}>
      <div onClick={e=>e.stopPropagation()}>
        {(title||sub)&&(
          <div style={{background:"rgba(249,249,249,0.97)",borderRadius:14,padding:"16px 20px",textAlign:"center",marginBottom:8}}>
            {title&&<p style={{margin:"0 0 3px",fontWeight:600,fontSize:13,color:L.text}}>{title}</p>}
            {sub&&<p style={{margin:0,fontSize:13,color:"rgba(60,60,67,0.6)"}}>{sub}</p>}
          </div>
        )}
        <div style={{background:"rgba(249,249,249,0.97)",borderRadius:14,overflow:"hidden",marginBottom:8}}>
          {actions.map((a,i)=>(
            <div key={i}>
              {i>0&&<div style={{height:"0.5px",background:"rgba(60,60,67,0.18)"}}/>}
              <button onClick={a.action} style={{width:"100%",padding:"17px",background:"transparent",border:"none",fontSize:17,fontWeight:a.destructive?400:400,color:a.destructive?"#FF3B30":a.style==="bold"?"#007AFF":L.text,cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",textAlign:"center"}}>
                {a.label}
              </button>
            </div>
          ))}
        </div>
        <button onClick={onCancel} style={{width:"100%",padding:"17px",background:"rgba(249,249,249,0.97)",border:"none",borderRadius:14,fontSize:17,fontWeight:600,color:"#007AFF",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",textAlign:"center"}}>
          Cancel
        </button>
      </div>
    </div>
  );
}

// ── Skeleton shimmer loader ──
const Shimmer = ({w,h,r=10,style:sx={}}) => (
  <div style={{width:w,height:h,borderRadius:r,background:"linear-gradient(90deg,#E8E8ED 25%,#F0F0F5 50%,#E8E8ED 75%)",backgroundSize:"200% 100%",animation:"shimmer 1.4s linear infinite",...sx}}/>
);

function HomeSkeleton() {
  const L=useTheme();
  return(
    <div style={{padding:"0 20px",paddingTop:60}}>
      <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:12}}>
        <div><Shimmer w={120} h={14} r={7} style={{marginBottom:8}}/><Shimmer w={180} h={32} r={8}/></div>
        <Shimmer w={64} h={32} r={16}/>
      </div>
      <div style={{background:"#fff",borderRadius:16,padding:"18px 16px",marginBottom:14,display:"flex",gap:16}}>
        <Shimmer w={112} h={112} r={56}/>
        <div style={{flex:1}}>
          <Shimmer w={100} h={12} r={6} style={{marginBottom:8}}/>
          <Shimmer w={140} h={24} r={8} style={{marginBottom:12}}/>
          <Shimmer w={80} h={20} r={10} style={{marginBottom:14}}/>
          <div style={{display:"flex",gap:3}}>{[...Array(7)].map((_,i)=><Shimmer key={i} w={32} h={28} r={6}/>)}</div>
        </div>
      </div>
      <Shimmer w="100%" h={72} r={13} style={{marginBottom:10}}/>
      <Shimmer w={120} h={12} r={6} style={{marginBottom:8}}/>
      {[...Array(3)].map((_,i)=><Shimmer key={i} w="100%" h={70} r={13} style={{marginBottom:8}}/>)}
    </div>
  );
}

// ── Settings Modal ──
function SettingsModal({profile,onUpdateProfile,darkMode,onToggleDark,meds,history,onDeleteAllData,onClose,onShowToast,streak,streakData}) {
  const L=useTheme();
  const ff="'Figtree',-apple-system,sans-serif";

  // ── Tabs ────────────────────────────────────────────────────────────────────
  const [activeTab,setActiveTab]=useState("profile"); // profile | stats | app | data

  // ── Profile editing ─────────────────────────────────────────────────────────
  const [editingProfile,setEditingProfile]=useState(false);
  const [nameInput,setNameInput]=useState(profile?.name||"");
  const [ageInput,setAgeInput]=useState(profile?.age||"");
  const [genderInput,setGenderInput]=useState(profile?.gender||"");
  const [goalInput,setGoalInput]=useState(profile?.goal||"");

  // ── App preferences ─────────────────────────────────────────────────────────
  const [notifications,setNotifications]=useState(true);
  const [soundEnabled,setSoundEnabled]=useState(true);
  const [reminderLeadMins,setReminderLeadMins]=useState(0); // 0=on time,5,10,15
  const [dataConfirm,setDataConfirm]=useState(false);

  // ── Live stats from real data ────────────────────────────────────────────────
  const allEntries=Object.values(history).flat();
  const totalTaken=allEntries.filter(e=>e.taken).length;
  const totalDoses=allEntries.length;
  const overallAdh=totalDoses?Math.round(totalTaken/totalDoses*100):0;
  const totalAlarms=meds.reduce((a,m)=>a+m.schedule.filter(s=>s.enabled).length,0);
  const lowMedCount=meds.filter(m=>m.count<=m.refillAt&&m.count>0).length;
  const daysTracked=Object.keys(history).length;

  // Last 7-day adherence
  const last7=Array.from({length:7},(_,i)=>{const d=new Date();d.setDate(d.getDate()-i);return d.toISOString().slice(0,10);});
  const last7Entries=last7.flatMap(k=>history[k]||[]);
  const last7Adh=last7Entries.length?Math.round(last7Entries.filter(e=>e.taken).length/last7Entries.length*100):0;

  function saveProfile(){
    onUpdateProfile({name:nameInput.trim(),age:ageInput.trim(),gender:genderInput,goal:goalInput});
    setEditingProfile(false);
    onShowToast("Profile saved ✓");
  }

  function exportData(){
    const rows=[["Date","Medicine","Dose","Label","Taken"]];
    Object.entries(history).sort().forEach(([date,entries])=>{
      entries.forEach(e=>{
        const med=meds.find(m=>m.id===e.medId);
        rows.push([date,med?.name||"Unknown",med?.dose||"",e.label,e.taken?"Yes":"No"]);
      });
    });
    const csv=rows.map(r=>r.map(v=>`"${v}"`).join(",")).join("\n");
    const blob=new Blob([csv],{type:"text/csv"});
    const url=URL.createObjectURL(blob);
    const a=document.createElement("a");
    a.href=url; a.download=`medtrack-${new Date().toISOString().slice(0,10)}.csv`; a.click();
    URL.revokeObjectURL(url);
    onShowToast("Exported as CSV ✓");
  }

  // ── Sub-components ───────────────────────────────────────────────────────────
  function SRow({icon,iconBg="#111",label,sub,right,onClick,border=true}){
    return(
      <div onClick={onClick}
        style={{display:"flex",alignItems:"center",gap:12,padding:"13px 16px",cursor:onClick?"pointer":"default",borderBottom:border?`1px solid ${L.border}`:"none",background:L.card}}>
        <div style={{width:32,height:32,borderRadius:10,background:iconBg,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}>
          {typeof icon==="string"?<span style={{fontSize:16}}>{icon}</span>:<Ic d={icon} size={15} c="#fff" w={2}/>}
        </div>
        <div style={{flex:1,minWidth:0}}>
          <p style={{margin:0,fontSize:15,fontWeight:600,color:L.text,fontFamily:ff}}>{label}</p>
          {sub&&<p style={{margin:"1px 0 0",fontSize:12,color:L.sub,fontFamily:ff}}>{sub}</p>}
        </div>
        {right&&<div style={{display:"flex",alignItems:"center",gap:6,flexShrink:0}}>{right}</div>}
        {onClick&&!right&&<Ic d={ic.chevron} size={16} c={L.sub}/>}
      </div>
    );
  }

  function CalToggle({on,onChange}){
    return(
      <div onClick={()=>onChange(!on)} style={{width:44,height:26,borderRadius:99,background:on?"#111":"rgba(120,120,128,0.3)",position:"relative",cursor:"pointer",transition:"background 0.2s",flexShrink:0}}>
        <div style={{position:"absolute",top:3,left:on?"auto":3,right:on?3:"auto",width:20,height:20,borderRadius:99,background:"#fff",transition:"all 0.22s cubic-bezier(0.34,1.56,0.64,1)",boxShadow:"0 1px 4px rgba(0,0,0,0.25)"}}/>
      </div>
    );
  }

  function Section({title,children}){
    return(
      <div style={{marginBottom:20}}>
        {title&&<p style={{margin:"0 0 6px 4px",fontSize:11,fontWeight:700,letterSpacing:"0.08em",textTransform:"uppercase",color:L.sub,fontFamily:ff}}>{title}</p>}
        <div style={{borderRadius:16,overflow:"hidden",border:`1px solid ${L.border}`}}>{children}</div>
      </div>
    );
  }

  // ── Tab content ──────────────────────────────────────────────────────────────
  function ProfileTab(){
    const GENDERS=["Male","Female","Non-binary","Prefer not to say"];
    const GOALS=["Manage chronic condition","Stay on top of prescriptions","Support family member","Post-surgery recovery","General wellness","Mental health support"];
    return(
      <div>
        {/* Avatar + name hero */}
        <div style={{display:"flex",alignItems:"center",gap:14,background:L.card,borderRadius:16,padding:"16px",marginBottom:16,border:`1px solid ${L.border}`}}>
          <div style={{width:60,height:60,borderRadius:18,background:"#111",display:"flex",alignItems:"center",justifyContent:"center",fontSize:28,flexShrink:0}}>
            {profile?.avatar||"😊"}
          </div>
          <div style={{flex:1}}>
            <p style={{margin:0,fontWeight:800,fontSize:18,color:L.text,fontFamily:ff,letterSpacing:"-0.3px"}}>{profile?.name||"Your Name"}</p>
            <p style={{margin:"2px 0 0",fontSize:13,color:L.sub}}>{profile?.age?`Age ${profile.age}`:"Age not set"}{profile?.gender?` · ${profile.gender}`:""}</p>
          </div>
          {!editingProfile&&(
            <button onClick={()=>setEditingProfile(true)} style={{padding:"8px 16px",background:"#111",border:"none",borderRadius:10,fontSize:13,fontWeight:700,color:"#fff",cursor:"pointer",fontFamily:ff}}>Edit</button>
          )}
        </div>

        {editingProfile?(
          <div style={{marginBottom:16}}>
            <Section title="Edit Profile">
              {[
                {label:"Name",val:nameInput,set:setNameInput,placeholder:"Your name",type:"text"},
                {label:"Age",val:ageInput,set:setAgeInput,placeholder:"e.g. 35",type:"number"},
              ].map((f,i,arr)=>(
                <div key={f.label} style={{padding:"12px 16px",borderBottom:i<arr.length-1?`1px solid ${L.border}`:"none",background:L.card}}>
                  <p style={{margin:"0 0 4px",fontSize:11,fontWeight:700,color:L.sub,textTransform:"uppercase",letterSpacing:"0.06em"}}>{f.label}</p>
                  <input value={f.val} onChange={e=>f.set(e.target.value)} placeholder={f.placeholder} type={f.type}
                    style={{width:"100%",border:"none",background:"transparent",fontSize:16,fontWeight:600,color:L.text,outline:"none",fontFamily:ff}}/>
                </div>
              ))}
            </Section>
            <Section title="Gender">
              {GENDERS.map((g,i)=>(
                <div key={g} onClick={()=>setGenderInput(g)}
                  style={{display:"flex",alignItems:"center",justifyContent:"space-between",padding:"13px 16px",background:L.card,borderBottom:i<GENDERS.length-1?`1px solid ${L.border}`:"none",cursor:"pointer"}}>
                  <span style={{fontSize:15,fontWeight:600,color:L.text,fontFamily:ff}}>{g}</span>
                  {genderInput===g&&<Ic d={ic.check} size={16} c="#111" w={2.5}/>}
                </div>
              ))}
            </Section>
            <Section title="Primary Goal">
              {GOALS.map((g,i)=>(
                <div key={g} onClick={()=>setGoalInput(g)}
                  style={{display:"flex",alignItems:"center",justifyContent:"space-between",padding:"13px 16px",background:L.card,borderBottom:i<GOALS.length-1?`1px solid ${L.border}`:"none",cursor:"pointer"}}>
                  <span style={{fontSize:14,fontWeight:600,color:L.text,fontFamily:ff}}>{g}</span>
                  {goalInput===g&&<Ic d={ic.check} size={16} c="#111" w={2.5}/>}
                </div>
              ))}
            </Section>
            <div style={{display:"flex",gap:8}}>
              <button onClick={()=>{setEditingProfile(false);setNameInput(profile?.name||"");setAgeInput(profile?.age||"");setGenderInput(profile?.gender||"");setGoalInput(profile?.goal||"");}}
                style={{flex:1,padding:"13px",background:L.fill,border:"none",borderRadius:13,fontSize:15,fontWeight:700,color:L.text,cursor:"pointer",fontFamily:ff}}>Cancel</button>
              <button onClick={saveProfile}
                style={{flex:2,padding:"13px",background:"#111",border:"none",borderRadius:13,fontSize:15,fontWeight:800,color:"#fff",cursor:"pointer",fontFamily:ff}}>Save Changes</button>
            </div>
          </div>
        ):(
          <Section title="Your Info">
            <SRow icon="🎯" label="Health Goal" sub={profile?.goal||"Not set"} border={true}/>
            <SRow icon="🩺" label="Conditions" sub={profile?.conditions?.join(", ")||"Not set"} border={true}/>
            <SRow icon="🎂" label="Age" sub={profile?.age?`${profile.age} years old`:"Not set"} border={true}/>
            <SRow icon="🧬" label="Gender" sub={profile?.gender||"Not set"} border={false}/>
          </Section>
        )}
      </div>
    );
  }

  function StatsTab(){
    const adhColor=overallAdh>=80?L.green:overallAdh>=60?L.amber:L.red;
    const weekData=Array.from({length:7},(_,i)=>{
      const d=new Date(); d.setDate(d.getDate()-(6-i));
      const k=d.toISOString().slice(0,10);
      const ds=history[k]||[];
      const rate=ds.length?ds.filter(x=>x.taken).length/ds.length:0;
      return{day:["S","M","T","W","T","F","S"][d.getDay()],rate,k};
    });
    return(
      <div>
        {/* Adherence hero */}
        <div style={{background:"#111",borderRadius:18,padding:"20px",marginBottom:16}}>
          <p style={{margin:"0 0 4px",fontSize:11,fontWeight:700,color:"rgba(255,255,255,0.45)",textTransform:"uppercase",letterSpacing:"0.08em",fontFamily:ff}}>Overall Adherence</p>
          <div style={{display:"flex",alignItems:"flex-end",gap:8,marginBottom:12}}>
            <span style={{fontSize:48,fontWeight:900,color:"#fff",fontFamily:ff,letterSpacing:"-2px",lineHeight:1}}>{overallAdh}%</span>
            <span style={{fontSize:14,color:overallAdh>=80?"#34C759":overallAdh>=60?"#FF9500":"#FF453A",fontWeight:700,marginBottom:6}}>{overallAdh>=80?"Great":"Keep going"}</span>
          </div>
          <div style={{height:6,background:"rgba(255,255,255,0.15)",borderRadius:99,overflow:"hidden"}}>
            <div style={{height:"100%",width:`${overallAdh}%`,background:overallAdh>=80?"#34C759":overallAdh>=60?"#FF9500":"#FF453A",borderRadius:99,transition:"width 0.6s"}}/>
          </div>
        </div>

        {/* Stats grid */}
        <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:10,marginBottom:16}}>
          {[
            {label:"Doses Taken",val:totalTaken,sub:`of ${totalDoses} total`,emoji:"✅",color:L.green},
            {label:"7-Day Rate",val:`${last7Adh}%`,sub:"Last 7 days",emoji:"📈",color:L.blue},
            {label:"Current Streak",val:`${streak}d`,sub:"days in a row",emoji:"🔥",color:L.amber},
            {label:"Days Tracked",val:daysTracked,sub:"days of data",emoji:"📅",color:L.purple},
          ].map((s,i)=>(
            <div key={i} style={{background:L.card,borderRadius:16,padding:"14px 16px",border:`1px solid ${L.border}`}}>
              <span style={{fontSize:20,display:"block",marginBottom:6}}>{s.emoji}</span>
              <p style={{margin:0,fontWeight:900,fontSize:24,color:L.text,fontFamily:ff,letterSpacing:"-1px"}}>{s.val}</p>
              <p style={{margin:"2px 0 0",fontSize:11,fontWeight:600,color:L.sub}}>{s.label}</p>
              <p style={{margin:"1px 0 0",fontSize:10,color:L.sub}}>{s.sub}</p>
            </div>
          ))}
        </div>

        {/* Weekly bar chart */}
        <div style={{background:L.card,borderRadius:16,padding:"16px",marginBottom:16,border:`1px solid ${L.border}`}}>
          <p style={{margin:"0 0 14px",fontSize:13,fontWeight:700,color:L.text,fontFamily:ff}}>This Week</p>
          <div style={{display:"flex",alignItems:"flex-end",gap:6,height:60}}>
            {weekData.map((w,i)=>(
              <div key={i} style={{flex:1,display:"flex",flexDirection:"column",alignItems:"center",gap:4}}>
                <div style={{width:"100%",borderRadius:6,background:w.rate>=0.8?"#111":w.rate>0?L.amber:L.fill,height:`${Math.max(8,w.rate*60)}px`,transition:"height 0.4s"}}/>
                <span style={{fontSize:10,fontWeight:700,color:L.sub}}>{w.day}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Medicines overview */}
        <Section title="Your Medicines">
          {meds.length===0?(
            <div style={{padding:"20px 16px",background:L.card,textAlign:"center"}}>
              <p style={{margin:0,color:L.sub,fontSize:13}}>No medicines added yet</p>
            </div>
          ):meds.map((m,i)=>{
            const pct=Math.max(0,Math.min(1,m.count/m.totalCount));
            const isLow=m.count<=m.refillAt;
            return(
              <div key={m.id} style={{display:"flex",alignItems:"center",gap:10,padding:"12px 16px",background:L.card,borderBottom:i<meds.length-1?`1px solid ${L.border}`:"none"}}>
                <div style={{width:10,height:10,borderRadius:99,background:m.color,flexShrink:0}}/>
                <div style={{flex:1,minWidth:0}}>
                  <p style={{margin:0,fontWeight:700,fontSize:14,color:L.text,fontFamily:ff,overflow:"hidden",textOverflow:"ellipsis",whiteSpace:"nowrap"}}>{m.name}</p>
                  <div style={{height:3,background:L.border,borderRadius:99,overflow:"hidden",marginTop:4}}>
                    <div style={{height:"100%",width:`${pct*100}%`,background:isLow?L.red:m.color,borderRadius:99}}/>
                  </div>
                </div>
                <span style={{fontSize:12,fontWeight:700,color:isLow?L.red:L.sub,flexShrink:0}}>{m.count}/{m.totalCount}</span>
              </div>
            );
          })}
        </Section>
      </div>
    );
  }

  function AppTab(){
    const LEAD_OPTS=[{v:0,l:"On time"},{v:5,l:"5 min early"},{v:10,l:"10 min early"},{v:15,l:"15 min early"}];
    return(
      <div>
        <Section title="Notifications">
          <SRow icon={ic.bell} iconBg="#EF4444" label="Dose Reminders" sub="Get notified when it's time" right={<CalToggle on={notifications} onChange={setNotifications}/>} border={true}/>
          <SRow icon={ic.zap} iconBg="#F59E0B" label="Sound & Haptics" sub="Vibrate and play sound" right={<CalToggle on={soundEnabled} onChange={setSoundEnabled}/>} border={true}/>
          <SRow icon={ic.clock} iconBg="#6366F1" label="Refill Alerts" sub={`Alert when ${meds.length>0?"any medicine is low":"meds run low"}`} right={<CalToggle on={true} onChange={()=>onShowToast("Toggle in each med's settings")}/>} border={false}/>
        </Section>
        <Section title="Reminder Timing">
          {LEAD_OPTS.map((o,i)=>(
            <div key={o.v} onClick={()=>setReminderLeadMins(o.v)}
              style={{display:"flex",alignItems:"center",justifyContent:"space-between",padding:"13px 16px",background:L.card,borderBottom:i<LEAD_OPTS.length-1?`1px solid ${L.border}`:"none",cursor:"pointer"}}>
              <span style={{fontSize:15,fontWeight:600,color:L.text,fontFamily:ff}}>{o.l}</span>
              {reminderLeadMins===o.v&&<Ic d={ic.check} size={16} c="#111" w={2.5}/>}
            </div>
          ))}
        </Section>
        <Section title="Appearance">
          <SRow icon={darkMode?ic.moon:ic.sun} iconBg={darkMode?"#5856D6":"#F59E0B"} label="Dark Mode" sub={darkMode?"Using dark theme":"Using light theme"} right={<CalToggle on={darkMode} onChange={onToggleDark}/>} border={false}/>
        </Section>
        <Section title="App Info">
          <SRow icon="💊" label="MedTrackAI" sub="Version 2.0 · Production" border={true}/>
          <SRow icon={ic.shield} iconBg="#22C55E" label="Privacy" sub="Your data stays on this device" border={true}/>
          <SRow icon={ic.info} iconBg="#6366F1" label={`${meds.length} medicine${meds.length!==1?"s":""} · ${totalAlarms} reminder${totalAlarms!==1?"s":""}`} sub={lowMedCount>0?`⚠️ ${lowMedCount} medicine${lowMedCount>1?"s":""} running low`:"All medicines stocked"} border={false}/>
        </Section>
      </div>
    );
  }

  function DataTab(){
    return(
      <div>
        {/* Data summary */}
        <div style={{background:"#111",borderRadius:18,padding:"18px 20px",marginBottom:16}}>
          <p style={{margin:"0 0 12px",fontWeight:800,fontSize:16,color:"#fff",fontFamily:ff}}>Your Data Summary</p>
          <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:8}}>
            {[
              ["Medicines",meds.length],
              ["Alarms set",totalAlarms],
              ["Days tracked",daysTracked],
              ["Doses logged",totalDoses],
            ].map(([l,v])=>(
              <div key={l} style={{background:"rgba(255,255,255,0.08)",borderRadius:12,padding:"10px 12px"}}>
                <p style={{margin:0,fontWeight:800,fontSize:22,color:"#fff",fontFamily:ff,letterSpacing:"-0.8px"}}>{v}</p>
                <p style={{margin:0,fontSize:11,color:"rgba(255,255,255,0.45)",fontWeight:600}}>{l}</p>
              </div>
            ))}
          </div>
        </div>

        <Section title="Export & Backup">
          <SRow icon={ic.download} iconBg="#22C55E" label="Export History as CSV" sub={`${totalDoses} dose records`} onClick={exportData} border={false}/>
        </Section>
        <Section title="Reset">
          <SRow icon={ic.trash} iconBg="#EF4444" label="Delete All Data" sub="Removes all medicines, history & settings" onClick={()=>setDataConfirm(true)} border={false}/>
        </Section>

        {dataConfirm&&(
          <ActionSheet
            title="Delete All Data?"
            sub={`This will permanently delete ${meds.length} medicine${meds.length!==1?"s":""}, ${daysTracked} days of history, and all settings. This cannot be undone.`}
            actions={[{label:"Delete Everything",destructive:true,action:()=>{onDeleteAllData();setDataConfirm(false);onClose();onShowToast("All data deleted","warning");}}]}
            onCancel={()=>setDataConfirm(false)}
          />
        )}
      </div>
    );
  }

  const TABS=[
    {id:"profile",label:"Profile",icon:"👤"},
    {id:"stats",label:"Stats",icon:"📊"},
    {id:"app",label:"App",icon:"⚙️"},
    {id:"data",label:"Data",icon:"🗂️"},
  ];

  return(
    <div style={{position:"fixed",inset:0,background:"rgba(0,0,0,0.5)",zIndex:2000,backdropFilter:"blur(12px)",WebkitBackdropFilter:"blur(12px)"}} onClick={onClose}>
      <div style={{position:"absolute",inset:0,display:"flex",flexDirection:"column",justifyContent:"flex-end",maxWidth:430,margin:"0 auto"}}>
        <div style={{background:L.bg,borderRadius:"24px 24px 0 0",maxHeight:"92vh",display:"flex",flexDirection:"column",animation:"iosSlideUp 0.38s cubic-bezier(0.32,0.72,0,1) forwards"}} onClick={e=>e.stopPropagation()}>
          {/* Handle */}
          <div style={{display:"flex",justifyContent:"center",paddingTop:10,flexShrink:0}}>
            <div style={{width:36,height:4,borderRadius:99,background:L.border}}/>
          </div>
          {/* Header */}
          <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",padding:"12px 20px 0",flexShrink:0}}>
            <p style={{margin:0,fontWeight:800,fontSize:22,color:L.text,fontFamily:ff,letterSpacing:"-0.5px"}}>Settings</p>
            <button onClick={onClose} style={{width:32,height:32,borderRadius:99,background:L.fill,border:"none",cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center"}}><Ic d={ic.x} size={14} c={L.sub}/></button>
          </div>
          {/* Tab bar */}
          <div style={{display:"flex",gap:6,padding:"12px 20px 0",flexShrink:0,overflowX:"auto"}}>
            {TABS.map(t=>(
              <button key={t.id} onClick={()=>setActiveTab(t.id)}
                style={{display:"flex",alignItems:"center",gap:6,padding:"8px 14px",borderRadius:99,border:"none",cursor:"pointer",background:activeTab===t.id?"#111":L.fill,fontFamily:ff,whiteSpace:"nowrap",transition:"all 0.15s"}}>
                <span style={{fontSize:13}}>{t.icon}</span>
                <span style={{fontSize:13,fontWeight:700,color:activeTab===t.id?"#fff":L.text}}>{t.label}</span>
              </button>
            ))}
          </div>
          {/* Scrollable content */}
          <div style={{overflowY:"auto",flex:1,padding:"16px 20px 40px"}}>
            {activeTab==="profile"&&<ProfileTab/>}
            {activeTab==="stats"&&<StatsTab/>}
            {activeTab==="app"&&<AppTab/>}
            {activeTab==="data"&&<DataTab/>}
          </div>
        </div>
      </div>
    </div>
  );
}

/* ══════════════════════════════════════════════
   ONBOARDING STEPS CONFIG
══════════════════════════════════════════════ */
const OB_STEPS = [
  // 0 - Splash
  { type:"splash" },
  // 1 - Name
  { type:"text", field:"name", emoji:"👋", title:"What's your name?", sub:"We'll personalise everything for you", placeholder:"Your first name" },
  // 2 - Age
  { type:"text", field:"age", emoji:"🎂", title:"How old are you?", sub:"Helps tailor health insights", placeholder:"e.g. 35", inputType:"number" },
  // 3 - Gender
  { type:"single", field:"gender", emoji:"🧬", title:"How do you identify?", sub:"For personalised health guidance",
    opts:[ {v:"Male",e:"👨"},{v:"Female",e:"👩"},{v:"Non-binary",e:"🌈"},{v:"Prefer not",e:"🤝"} ] },
  // 4 - Primary goal
  { type:"single", field:"goal", emoji:"🎯", title:"What's your main health goal?", sub:"This shapes your entire experience",
    opts:[ {v:"Manage chronic condition",e:"🏥"},{v:"Stay on top of prescriptions",e:"💊"},{v:"Support family member",e:"👨‍👩‍👧"},{v:"Post-surgery recovery",e:"🔬"},{v:"General wellness",e:"🌿"},{v:"Mental health support",e:"🧠"} ] },
  // 5 - Conditions
  { type:"multi", field:"conditions", emoji:"🩺", title:"Any health conditions?", sub:"Select all that apply — helps us customise",
    opts:[ {v:"Diabetes",e:"🩸"},{v:"Hypertension",e:"❤️"},{v:"Heart disease",e:"💓"},{v:"Asthma",e:"🫁"},{v:"Thyroid",e:"🦋"},{v:"Arthritis",e:"🦴"},{v:"Depression",e:"🌧️"},{v:"Anxiety",e:"🌀"},{v:"None",e:"✅"} ] },
  // 6 - Med count
  { type:"single", field:"medCount", emoji:"💊", title:"How many medications do you take?", sub:"Include vitamins, supplements & prescriptions",
    opts:[ {v:"1",e:"1️⃣"},{v:"2–3",e:"2️⃣"},{v:"4–6",e:"🔢"},{v:"7+",e:"📦"} ] },
  // 7 - Forget pattern
  { type:"single", field:"forgetting", emoji:"🧠", title:"When do you most forget to take meds?", sub:"We'll build reminders around this",
    opts:[ {v:"Morning rush",e:"🌅"},{v:"After work",e:"🌆"},{v:"Bedtime",e:"🌙"},{v:"Midday",e:"☀️"},{v:"Varies",e:"🔀"} ] },
  // 8 - Wake time
  { type:"time", field:"wakeTime", emoji:"⏰", title:"What time do you wake up?", sub:"We'll schedule your morning reminder", defaultH:7 },
  // 9 - Breakfast
  { type:"time", field:"breakfastTime", emoji:"🍳", title:"When do you usually have breakfast?", sub:"Some meds are best taken with food", defaultH:8 },
  // 10 - Lunch
  { type:"time", field:"lunchTime", emoji:"🥗", title:"What time is your lunch break?", sub:"We'll set your midday check-in", defaultH:12 },
  // 11 - Dinner
  { type:"time", field:"dinnerTime", emoji:"🍽️", title:"When do you have dinner?", sub:"Evening meds work best with your meal", defaultH:19 },
  // 12 - Sleep
  { type:"time", field:"sleepTime", emoji:"😴", title:"What time do you usually sleep?", sub:"We'll send a last reminder before bed", defaultH:22 },
  // 13 - Doctor visits
  { type:"single", field:"doctorVisits", emoji:"👨‍⚕️", title:"How often do you see your doctor?", sub:"Helps us remind you before appointments",
    opts:[ {v:"Weekly",e:"📅"},{v:"Monthly",e:"🗓️"},{v:"Every 3 months",e:"📆"},{v:"Twice a year",e:"📋"},{v:"Rarely",e:"🤷"} ] },
  // 14 - Support
  { type:"single", field:"support", emoji:"🤝", title:"Do you have someone who helps you with medication?", sub:"We'll tailor reminders accordingly",
    opts:[ {v:"Yes, family member",e:"👨‍👩‍👧"},{v:"Yes, caregiver",e:"👩‍⚕️"},{v:"Managing alone",e:"💪"},{v:"It varies",e:"🔄"} ] },
  // 15 - Challenge
  { type:"single", field:"challenge", emoji:"😤", title:"What's your biggest medication challenge?", sub:"Let's solve it together",
    opts:[ {v:"Remembering times",e:"⏰"},{v:"Side effects",e:"😵"},{v:"Cost of meds",e:"💰"},{v:"Complex schedule",e:"📋"},{v:"Motivation",e:"⚡"},{v:"Tracking refills",e:"📦"} ] },
  // 16 - Previous app
  { type:"single", field:"prevApp", emoji:"📱", title:"Have you tried a medication app before?", sub:"We'll show you what makes us different",
    opts:[ {v:"Never",e:"🆕"},{v:"Yes, but stopped using",e:"😞"},{v:"Currently using one",e:"🔄"},{v:"Used many apps",e:"📱"} ] },
  // 17 - Motivation
  { type:"multi", field:"motivation", emoji:"💪", title:"What motivates you to stay healthy?", sub:"We'll personalise your encouragement",
    opts:[ {v:"Living longer",e:"🌟"},{v:"My family",e:"❤️"},{v:"Feeling better",e:"😊"},{v:"Doctor's orders",e:"📋"},{v:"Saving money",e:"💰"},{v:"Sport & fitness",e:"🏃"} ] },
  // 18 - Reminder style
  { type:"single", field:"reminderStyle", emoji:"🔔", title:"How should we remind you?", sub:"Pick the style that works for you",
    opts:[ {v:"Gentle nudge",e:"🤫"},{v:"Firm reminder",e:"🔔"},{v:"With health tip",e:"💡"},{v:"With motivation",e:"⚡"} ] },
  // 19 - Notification permission
  { type:"notif", field:"notifPerm" },
  // 20 - Plan ready
  { type:"plan" },
  // 21 - Paywall (internally manages 3 sub-steps)
  { type:"paywall" },
];

/* ══════════════════════════════════════════════
   ONBOARDING COMPONENT
══════════════════════════════════════════════ */
function Onboarding({ onDone }) {
  const [step, setStep] = useState(0);
  const [dir, setDir] = useState(1);
  const [animKey, setAnimKey] = useState(0);
  const [form, setForm] = useState({
    name:"", age:"", gender:"", goal:"", conditions:[], medCount:"", forgetting:"",
    wakeTime:{h:7,m:0}, breakfastTime:{h:8,m:0}, lunchTime:{h:12,m:0},
    dinnerTime:{h:19,m:0}, sleepTime:{h:22,m:0},
    doctorVisits:"", support:"", challenge:"", prevApp:"", motivation:[],
    reminderStyle:"", notifPerm:false, promoCode:"", appliedPromo:null,
  });
  const [promoInput, setPromoInput] = useState("");
  const [promoError, setPromoError] = useState("");
  const [promoSuccess, setPromoSuccess] = useState(null);
  const [selectedPlan, setSelectedPlan] = useState("annual");
  const [paywallStep, setPaywallStep] = useState(1);
  const totalSteps = OB_STEPS.length;

  const goNext = useCallback(() => {
    setDir(1);
    setAnimKey(k=>k+1);
    setStep(prev => Math.min(prev+1, totalSteps-1));
  }, [totalSteps]);

  const goBack = useCallback(() => {
    if(step===0) return;
    setDir(-1);
    setAnimKey(k=>k+1);
    setStep(prev => prev-1);
  }, [step]);

  const setValue = (field, val) => setForm(p=>({...p,[field]:val}));
  const toggleMulti = (field, val) => setForm(p=>{
    const arr = p[field]||[];
    return {...p,[field]: arr.includes(val) ? arr.filter(x=>x!==val) : [...arr,val]};
  });

  const applyPromo = () => {
    const code = promoInput.trim().toUpperCase();
    if(PROMO_CODES[code]){
      setPromoSuccess(PROMO_CODES[code]);
      setValue("appliedPromo", PROMO_CODES[code]);
      setValue("promoCode", code);
      setPromoError("");
    } else {
      setPromoError("Invalid code. Try WELCOME for a free trial.");
      setPromoSuccess(null);
    }
  };

  const s = OB_STEPS[step] ?? OB_STEPS[0];
  const isPaywall = s.type === "paywall";
  const isSplash  = s.type === "splash";
  const showProgress = !isSplash && !isPaywall;
  const progress = step / (totalSteps - 1);

  return (
    <div style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif", background:D.bg, minHeight:"100vh", maxWidth:430, margin:"0 auto", display:"flex", flexDirection:"column", position:"relative", overflow:"hidden"}}>
      <style>{GLOBAL_CSS}</style>

      {/* Ambient background */}
      <div style={{position:"fixed",inset:0,pointerEvents:"none",overflow:"hidden",zIndex:0}}>
        <div style={{position:"absolute",top:-100,left:-100,width:400,height:400,background:"radial-gradient(circle,rgba(163,230,53,0.06) 0%,transparent 70%)",animation:"bgFloat 8s ease-in-out infinite"}}/>
        <div style={{position:"absolute",bottom:-100,right:-100,width:300,height:300,background:"radial-gradient(circle,rgba(16,185,129,0.05) 0%,transparent 70%)",animation:"bgFloat 10s ease-in-out infinite reverse"}}/>
      </div>

      {/* Progress bar */}
      {showProgress && (
        <div style={{position:"fixed",top:0,left:"50%",transform:"translateX(-50%)",width:"100%",maxWidth:430,zIndex:100,padding:"16px 20px 0"}}>
          <div style={{height:3,background:D.border,borderRadius:99,overflow:"hidden"}}>
            <div style={{height:"100%",background:`linear-gradient(90deg,${D.lime},${D.green})`,borderRadius:99,transition:"width 0.4s ease",width:`${progress*100}%`}}/>
          </div>
          <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginTop:12}}>
            <button onClick={goBack} style={{background:"none",border:"none",color:D.sub,cursor:"pointer",padding:"4px 0",fontSize:13,fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",display:"flex",alignItems:"center",gap:4}}>
              <Ic d={ic.back} size={16} c={D.sub}/> Back
            </button>
            <span style={{fontSize:12,color:D.sub,fontWeight:600}}>{step} of {totalSteps-2}</span>
          </div>
        </div>
      )}

      <div key={animKey} className={step>0?(dir>=0?"ob-animate":"ob-animate-left"):""} style={{flex:1,display:"flex",flexDirection:"column",position:"relative",zIndex:1,paddingTop:showProgress?72:0}}>
        {s.type==="splash"  && <SplashStep onNext={()=>goNext()}/>}
        {s.type==="text"    && <TextStep s={s} form={form} onChange={v=>setValue(s.field,v)} onNext={()=>goNext()}/>}
        {s.type==="single"  && <SingleStep s={s} form={form} onSelect={v=>setValue(s.field,v)} onNext={()=>goNext()}/>}
        {s.type==="multi"   && <MultiStep s={s} form={form} onToggle={v=>toggleMulti(s.field,v)} onNext={()=>goNext()}/>}
        {s.type==="time"    && <TimeStep s={s} form={form} onChange={v=>setValue(s.field,v)} onNext={()=>goNext()}/>}
        {s.type==="notif"   && <NotifStep form={form} onAllow={()=>{setValue("notifPerm",true);goNext();}} onSkip={()=>goNext()}/>}
        {s.type==="plan"    && <PlanReadyStep form={form} onNext={()=>goNext()}/>}
        {s.type==="paywall" && (
          <PaywallStep
            form={form} paywallStep={paywallStep} setPaywallStep={setPaywallStep}
            selectedPlan={selectedPlan} setSelectedPlan={setSelectedPlan}
            promoInput={promoInput} setPromoInput={setPromoInput}
            promoError={promoError} promoSuccess={promoSuccess} onApplyPromo={applyPromo}
            onDone={()=>onDone(form)} onBack={()=>paywallStep>1?setPaywallStep(p=>p-1):goBack()}
          />
        )}
      </div>
    </div>
  );
}

/* ── Splash Step ── */
function SplashStep({onNext}) {
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",alignItems:"center",justifyContent:"center",padding:"40px 32px",textAlign:"center",minHeight:"100vh"}}>
      <div className="s1" style={{marginBottom:24}}>
        <div style={{width:88,height:88,background:D.limeDim,borderRadius:28,display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 20px",border:`1px solid rgba(163,230,53,0.2)`,animation:"floatUp 3s ease-in-out infinite"}}>
          <span style={{fontSize:44}}>💊</span>
        </div>
        <h1 style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:36,fontWeight:700,color:D.text,margin:"0 0 12px",letterSpacing:"-1px",lineHeight:1.1}}>
          MedTrack<span style={{color:D.lime}}>AI</span>
        </h1>
        <p style={{color:D.sub,fontSize:16,lineHeight:1.6,margin:0}}>Your intelligent medicine tracker. Scan, track, and never miss a dose again.</p>
      </div>
      <div className="s2" style={{display:"flex",flexDirection:"column",gap:10,width:"100%",marginBottom:32}}>
        {[["🔍 Scan","AI identifies any medicine instantly"],["⏰ Remind","Smart reminders built around your life"],["📈 Track","Monitor adherence & streak progress"]].map(([t,d],i)=>(
          <div key={i} style={{display:"flex",alignItems:"center",gap:14,background:D.card,borderRadius:16,padding:"14px 16px",border:`1px solid ${D.border}`,textAlign:"left"}}>
            <span style={{fontSize:22,minWidth:32}}>{t.split(" ")[0]}</span>
            <div>
              <p style={{margin:0,fontWeight:700,fontSize:14,color:D.text}}>{t.split(" ")[1]}</p>
              <p style={{margin:0,fontSize:12,color:D.sub}}>{d}</p>
            </div>
          </div>
        ))}
      </div>
      <div className="s3" style={{width:"100%"}}>
        <button onClick={onNext} style={{width:"100%",padding:"18px",background:D.lime,border:"none",borderRadius:13,fontSize:16,fontWeight:700,color:"#0A0A0F",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",animation:"glowPulse 2s ease-in-out infinite"}}>
          Get Started →
        </button>
        <p style={{color:D.sub,fontSize:12,marginTop:12,textAlign:"center"}}>Free to start · No credit card required</p>
      </div>
    </div>
  );
}

/* ── Text Input Step ── */
function TextStep({s,form,onChange,onNext}) {
  const val = form[s.field]||"";
  return(
    <div style={{flex:1,padding:"20px 24px 40px",display:"flex",flexDirection:"column"}}>
      <div style={{marginBottom:32,paddingTop:8}}>
        <div style={{fontSize:52,marginBottom:16}} className="s1">{s.emoji}</div>
        <h2 className="s1" style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:28,fontWeight:700,color:D.text,margin:"0 0 8px",letterSpacing:"-0.5px",lineHeight:1.2}}>{s.title}</h2>
        <p className="s2" style={{color:D.sub,fontSize:14,margin:0}}>{s.sub}</p>
      </div>
      <input
        className="s3"
        type={s.inputType||"text"}
        value={val}
        onChange={e=>onChange(e.target.value)}
        placeholder={s.placeholder}
        autoFocus
        onKeyDown={e=>e.key==="Enter"&&val.trim()&&onNext()}
        style={{background:D.card,border:`1.5px solid ${val?D.lime:D.border}`,borderRadius:16,padding:"16px 18px",fontSize:17,color:D.text,outline:"none",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontWeight:600,transition:"border-color 0.2s",marginBottom:"auto"}}
      />
      <button onClick={onNext} disabled={!val.trim()} style={{width:"100%",padding:"17px",background:val.trim()?D.lime:"#1E1E2A",border:"none",borderRadius:13,fontSize:15,fontWeight:700,color:val.trim()?"#0A0A0F":D.sub,cursor:val.trim()?"pointer":"default",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",marginTop:24,transition:"all 0.2s"}}>
        {val.trim()?`Hi ${s.field==="name"?val:"there"}, Continue →`:"Enter your answer"}
      </button>
    </div>
  );
}

/* ── Single Select Step ── */
function SingleStep({s,form,onSelect,onNext}) {
  const val = form[s.field];
  const grid = s.opts.length>4;
  return(
    <div style={{flex:1,padding:"20px 24px 40px",display:"flex",flexDirection:"column",overflowY:"auto"}}>
      <div style={{marginBottom:24,paddingTop:8}}>
        <div style={{fontSize:48,marginBottom:14}} className="s1">{s.emoji}</div>
        <h2 className="s1" style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:26,fontWeight:700,color:D.text,margin:"0 0 6px",letterSpacing:"-0.5px",lineHeight:1.2}}>{s.title}</h2>
        <p className="s2" style={{color:D.sub,fontSize:14,margin:0}}>{s.sub}</p>
      </div>
      <div className="s3" style={{display:grid?"grid":"flex",gridTemplateColumns:grid?"1fr 1fr":undefined,flexDirection:grid?undefined:"column",gap:10,flex:1}}>
        {s.opts.map((opt,i)=>{
          const sel = val===opt.v;
          return(
            <button key={i} onClick={()=>onSelect(opt.v)}
              style={{display:"flex",alignItems:"center",gap:grid?10:12,padding:grid?"14px 12px":"14px 18px",background:sel?"rgba(163,230,53,0.15)":"rgba(255,255,255,0.07)",border:sel?"1px solid rgba(163,230,53,0.4)":"1px solid rgba(255,255,255,0.08)",borderRadius:14,cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",transition:"all 0.15s",textAlign:"left",flexDirection:grid?"column":"row"}}>
              <span style={{fontSize:grid?28:24,lineHeight:1}}>{opt.e}</span>
              <span style={{fontSize:13,fontWeight:600,color:sel?D.lime:D.text,lineHeight:1.3,flex:grid?undefined:1}}>{opt.v}</span>
              {!grid&&sel&&<div style={{width:20,height:20,borderRadius:99,background:D.lime,display:"flex",alignItems:"center",justifyContent:"center",marginLeft:"auto",flexShrink:0}}><Ic d={ic.check} size={11} c="#0A0A0F" w={2.5}/></div>}
            </button>
          );
        })}
      </div>
      <button onClick={onNext} disabled={!val} style={{width:"100%",padding:"17px",background:val?D.lime:"#1E1E2A",border:"none",borderRadius:13,fontSize:15,fontWeight:700,color:val?"#0A0A0F":D.sub,cursor:val?"pointer":"default",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",marginTop:16,transition:"all 0.2s"}}>
        {val?"Continue →":"Select an option"}
      </button>
    </div>
  );
}

/* ── Multi Select Step ── */
function MultiStep({s,form,onToggle,onNext}) {
  const vals = form[s.field]||[];
  return(
    <div style={{flex:1,padding:"20px 24px 40px",display:"flex",flexDirection:"column",overflowY:"auto"}}>
      <div style={{marginBottom:24,paddingTop:8}}>
        <div style={{fontSize:48,marginBottom:14}} className="s1">{s.emoji}</div>
        <h2 className="s1" style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:26,fontWeight:700,color:D.text,margin:"0 0 6px",letterSpacing:"-0.5px",lineHeight:1.2}}>{s.title}</h2>
        <p className="s2" style={{color:D.sub,fontSize:14,margin:0}}>{s.sub} <span style={{color:D.lime,fontWeight:600}}>(select multiple)</span></p>
      </div>
      <div className="s3" style={{display:"flex",flexDirection:"column",gap:10,flex:1}}>
        {s.opts.map((opt,i)=>{
          const sel = vals.includes(opt.v);
          return(
            <button key={i} onClick={()=>onToggle(opt.v)}
              style={{display:"flex",alignItems:"center",gap:12,padding:"14px 18px",background:sel?"rgba(163,230,53,0.15)":"rgba(255,255,255,0.07)",border:sel?"1px solid rgba(163,230,53,0.4)":"1px solid rgba(255,255,255,0.08)",borderRadius:14,cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",transition:"all 0.15s",textAlign:"left"}}>
              <span style={{fontSize:22,lineHeight:1}}>{opt.e}</span>
              <span style={{fontSize:13,fontWeight:600,color:sel?D.lime:D.text,flex:1}}>{opt.v}</span>
              {sel&&<div style={{width:20,height:20,borderRadius:99,background:D.lime,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}><Ic d={ic.check} size={11} c="#0A0A0F" w={2.5}/></div>}
            </button>
          );
        })}
      </div>
      <button onClick={onNext} disabled={vals.length===0} style={{width:"100%",padding:"17px",background:vals.length>0?D.lime:"#1E1E2A",border:"none",borderRadius:13,fontSize:15,fontWeight:700,color:vals.length>0?"#0A0A0F":D.sub,cursor:vals.length>0?"pointer":"default",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",marginTop:16,transition:"all 0.2s"}}>
        {vals.length>0?`Continue (${vals.length} selected)`:"Select at least one"}
      </button>
    </div>
  );
}

/* ── Time Picker Step ── */
function TimeStep({s,form,onChange,onNext}) {
  const v = form[s.field]||{h:s.defaultH||8,m:0};
  const ampm = v.h>=12?"PM":"AM";
  const h12  = v.h%12||12;
  const toggleAmpm = () => onChange({...v,h:v.h>=12?v.h-12:v.h+12});
  return(
    <div style={{flex:1,padding:"20px 24px 40px",display:"flex",flexDirection:"column"}}>
      <div style={{marginBottom:28,paddingTop:8}}>
        <div style={{fontSize:48,marginBottom:14}} className="s1">{s.emoji}</div>
        <h2 className="s1" style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:26,fontWeight:700,color:D.text,margin:"0 0 6px",letterSpacing:"-0.5px",lineHeight:1.2}}>{s.title}</h2>
        <p className="s2" style={{color:D.sub,fontSize:14,margin:0}}>{s.sub}</p>
      </div>
      <div className="s3" style={{flex:1,display:"flex",flexDirection:"column",alignItems:"center",justifyContent:"center",gap:24}}>
        <div style={{display:"flex",alignItems:"center",gap:12,background:D.card,borderRadius:16,padding:"20px 28px",border:`1px solid ${D.border}`}}>
          <input type="number" min={1} max={12} value={h12}
            onChange={e=>{const b=parseInt(e.target.value)||12;const h24=ampm==="PM"?(b%12)+12:b%12;onChange({...v,h:h24});}}
            style={{width:72,background:"none",border:"none",outline:"none",fontSize:56,fontWeight:700,color:D.text,fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",textAlign:"center",letterSpacing:"-2px"}}/>
          <span style={{fontSize:48,fontWeight:700,color:D.sub,lineHeight:1}}>:</span>
          <select value={v.m} onChange={e=>onChange({...v,m:parseInt(e.target.value)})}
            style={{width:72,background:"none",border:"none",outline:"none",fontSize:56,fontWeight:700,color:D.text,fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",textAlign:"center",letterSpacing:"-2px",appearance:"none"}}>
            {[0,5,10,15,20,25,30,35,40,45,50,55].map(m=><option key={m} value={m}>{String(m).padStart(2,"0")}</option>)}
          </select>
          <button onClick={toggleAmpm} style={{fontSize:18,fontWeight:700,color:D.lime,background:"none",border:`1px solid ${D.lime}`,borderRadius:10,padding:"6px 10px",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>{ampm}</button>
        </div>
        <div style={{display:"flex",gap:8,flexWrap:"wrap",justifyContent:"center"}}>
          {[[6,"6 AM"],[7,"7 AM"],[8,"8 AM"],[9,"9 AM"],[12,"Noon"],[19,"7 PM"],[21,"9 PM"],[22,"10 PM"]].map(([h,label])=>{
            const sel=v.h===h;
            return <button key={h} onClick={()=>onChange({h,m:0})} style={{padding:"8px 14px",background:sel?D.limeDim:D.card,border:`1px solid ${sel?D.lime:D.border}`,borderRadius:99,fontSize:12,fontWeight:700,color:sel?D.lime:D.sub,cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",transition:"all 0.15s"}}>{label}</button>;
          })}
        </div>
      </div>
      <button onClick={onNext} style={{width:"100%",padding:"17px",background:D.lime,border:"none",borderRadius:13,fontSize:15,fontWeight:700,color:"#0A0A0F",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",marginTop:16}}>
        Set {fmt(v.h,v.m)} →
      </button>
    </div>
  );
}

/* ── Notification Permission Step ── */
function NotifStep({form,onAllow,onSkip}) {
  return(
    <div style={{flex:1,padding:"20px 24px 40px",display:"flex",flexDirection:"column",alignItems:"center",textAlign:"center"}}>
      <div style={{flex:1,display:"flex",flexDirection:"column",alignItems:"center",justifyContent:"center",gap:20}}>
        <div className="s1" style={{width:96,height:96,background:D.limeDim,borderRadius:28,display:"flex",alignItems:"center",justifyContent:"center",border:`1px solid rgba(163,230,53,0.2)`,animation:"floatUp 3s ease-in-out infinite"}}>
          <span style={{fontSize:48}}>🔔</span>
        </div>
        <div className="s1">
          <h2 style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:28,fontWeight:700,color:D.text,margin:"0 0 10px",lineHeight:1.2,letterSpacing:"-0.5px"}}>Stay on track with reminders</h2>
          <p style={{color:D.sub,fontSize:15,lineHeight:1.6,margin:0}}>89% of users who enable notifications never miss a dose.</p>
        </div>
        <div className="s2" style={{width:"100%",display:"flex",flexDirection:"column",gap:10}}>
          {[["⏰","Timed reminders","At exactly the right moment"],["🍽️","With food alerts","Never forget to eat before meds"],["🔥","Streak protection","Keep your streak alive"]].map(([e,t,d],i)=>(
            <div key={i} style={{display:"flex",alignItems:"center",gap:14,background:D.card,borderRadius:16,padding:"13px 16px",border:`1px solid ${D.border}`,textAlign:"left"}}>
              <span style={{fontSize:24,minWidth:32}}>{e}</span>
              <div><p style={{margin:0,fontWeight:700,fontSize:14,color:D.text}}>{t}</p><p style={{margin:0,fontSize:12,color:D.sub}}>{d}</p></div>
            </div>
          ))}
        </div>
      </div>
      <div className="s3" style={{width:"100%",display:"flex",flexDirection:"column",gap:10}}>
        <button onClick={onAllow} style={{width:"100%",padding:"17px",background:D.lime,border:"none",borderRadius:13,fontSize:15,fontWeight:700,color:"#0A0A0F",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",animation:"glowPulse 2s ease-in-out infinite"}}>
          Allow Notifications 🔔
        </button>
        <button onClick={onSkip} style={{width:"100%",padding:"14px",background:"none",border:"none",fontSize:14,color:D.sub,cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>
          Skip for now
        </button>
      </div>
    </div>
  );
}

/* ── Plan Ready Step ── */
function PlanReadyStep({form,onNext}) {
  const highlights = [
    form.goal&&`Goal: ${form.goal}`,
    form.conditions?.length?"Conditions: "+form.conditions.slice(0,2).join(", ")+(form.conditions.length>2?" +"+(form.conditions.length-2)+" more":""):null,
    form.wakeTime&&`Wake reminder: ${fmt(form.wakeTime.h,form.wakeTime.m)}`,
    form.reminderStyle&&`Style: ${form.reminderStyle}`,
    form.motivation?.length?`Motivated by: ${form.motivation[0]}`:null,
  ].filter(Boolean);
  return(
    <div style={{flex:1,padding:"20px 24px 40px",display:"flex",flexDirection:"column",alignItems:"center",textAlign:"center"}}>
      <div style={{flex:1,display:"flex",flexDirection:"column",alignItems:"center",justifyContent:"center",gap:20}}>
        <div className="s1" style={{fontSize:72,animation:"floatUp 3s ease-in-out infinite"}}>🎯</div>
        <div className="s1">
          <h2 style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:30,fontWeight:700,color:D.text,margin:"0 0 8px",letterSpacing:"-1px",lineHeight:1.1}}>Your plan is ready</h2>
          <p style={{color:D.lime,fontSize:15,fontWeight:700,margin:0}}>Personalised just for you ✨</p>
        </div>
        <div className="s2" style={{width:"100%",display:"flex",flexDirection:"column",gap:10,textAlign:"left"}}>
          {highlights.map((h,i)=>(
            <div key={i} style={{display:"flex",alignItems:"center",gap:12,background:D.card,borderRadius:14,padding:"12px 16px",border:`1px solid ${D.border}`}}>
              <div style={{width:22,height:22,borderRadius:99,background:D.limeDim,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}>
                <Ic d={ic.check} size={11} c={D.lime} w={2.5}/>
              </div>
              <span style={{fontSize:13,fontWeight:600,color:D.text}}>{h}</span>
            </div>
          ))}
        </div>
        <div className="s3" style={{background:D.limeDim,borderRadius:14,padding:"16px 20px",width:"100%",border:`1px solid rgba(163,230,53,0.2)`,textAlign:"center"}}>
          <p style={{margin:"0 0 4px",fontSize:28,fontWeight:700,color:D.lime}}>94%</p>
          <p style={{margin:0,fontSize:13,color:D.sub}}>of users like you improved adherence in 2 weeks</p>
        </div>
      </div>
      <button onClick={onNext} style={{width:"100%",padding:"18px",background:D.lime,border:"none",borderRadius:13,fontSize:16,fontWeight:700,color:"#0A0A0F",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",marginTop:20,animation:"glowPulse 2s ease-in-out infinite"}}>
        See My Plan →
      </button>
    </div>
  );
}

/* ══════════════════════════════════════════════
   PAYWALL (3-step) — dark theme
══════════════════════════════════════════════ */
function PaywallStep({form,paywallStep,setPaywallStep,selectedPlan,setSelectedPlan,promoInput,setPromoInput,promoError,promoSuccess,onApplyPromo,onDone,onBack}) {
  const goPayNext = () => setPaywallStep(p=>Math.min(p+1,3));
  const goPayBack = () => paywallStep>1?setPaywallStep(p=>p-1):onBack();
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",overflowY:"auto"}}>
      {paywallStep===1&&<PaywallStep1 form={form} selectedPlan={selectedPlan} setSelectedPlan={setSelectedPlan} promoInput={promoInput} setPromoInput={setPromoInput} promoError={promoError} promoSuccess={promoSuccess} onApplyPromo={onApplyPromo} onNext={goPayNext} onSkip={onDone}/>}
      {paywallStep===2&&<PaywallStep2 form={form} selectedPlan={selectedPlan} promoSuccess={promoSuccess} onNext={goPayNext} onBack={goPayBack}/>}
      {paywallStep===3&&<PaywallStep3 form={form} selectedPlan={selectedPlan} promoSuccess={promoSuccess} onDone={onDone} onBack={goPayBack}/>}
    </div>
  );
}

function PaywallStep1({form,selectedPlan,setSelectedPlan,promoInput,setPromoInput,promoError,promoSuccess,onApplyPromo,onNext,onSkip}) {
  const PLANS=[
    {id:"annual",label:"Annual",price:"$2.99",period:"/mo",total:"Billed $35.88/year",badge:"Best value · Save 62%"},
    {id:"monthly",label:"Monthly",price:"$7.99",period:"/mo",total:"Billed monthly",badge:null},
  ];
  const FEATS=["AI Medicine Scanner","Smart Reminders","Streak Protection","Unlimited Medicines","Low Stock Alerts","AI Health Insights","Family Sharing","Private & Secure"];
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",background:D.bg}}>
      <div style={{padding:"20px 20px 0",display:"flex",justifyContent:"space-between",alignItems:"center"}}>
        <div>
          <p style={{margin:"0 0 2px",fontSize:11,fontWeight:700,color:D.lime,letterSpacing:"0.08em",textTransform:"uppercase"}}>MedTrack Pro</p>
          <h2 style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:26,fontWeight:700,color:D.text,margin:0,letterSpacing:"-0.5px"}}>Start your free trial</h2>
        </div>
        <button onClick={onSkip} style={{background:"none",border:"none",color:D.sub,cursor:"pointer",fontSize:13,fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>Skip</button>
      </div>
      <div style={{padding:"0 20px",overflowY:"auto",flex:1}}>
        <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:8,margin:"20px 0 16px"}}>
          {FEATS.map((f,i)=>(
            <div key={i} style={{display:"flex",alignItems:"center",gap:8,background:D.card,borderRadius:12,padding:"10px 12px",border:`1px solid ${D.border}`}}>
              <div style={{width:6,height:6,borderRadius:99,background:D.lime,flexShrink:0}}/>
              <span style={{fontSize:11,fontWeight:600,color:D.text,lineHeight:1.3}}>{f}</span>
            </div>
          ))}
        </div>
        {PLANS.map(p=>{
          const sel=selectedPlan===p.id;
          return(
            <button key={p.id} onClick={()=>setSelectedPlan(p.id)} style={{width:"100%",display:"flex",alignItems:"center",gap:14,padding:"16px 18px",background:sel?D.limeDim:D.card,border:`2px solid ${sel?D.lime:D.border}`,borderRadius:16,cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",textAlign:"left",transition:"all 0.2s",marginBottom:10,position:"relative"}}>
              {p.badge&&sel&&<div style={{position:"absolute",top:-10,right:14,background:D.lime,color:"#0A0A0F",fontSize:10,fontWeight:700,padding:"3px 10px",borderRadius:99}}>{p.badge}</div>}
              <div style={{width:22,height:22,borderRadius:99,border:`2px solid ${sel?D.lime:D.sub}`,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}>
                {sel&&<div style={{width:12,height:12,borderRadius:99,background:D.lime}}/>}
              </div>
              <div style={{flex:1}}>
                <p style={{margin:0,fontWeight:700,fontSize:15,color:sel?D.lime:D.text}}>{p.label}</p>
                <p style={{margin:"2px 0 0",fontSize:11,color:D.sub}}>{p.total}</p>
              </div>
              <div style={{textAlign:"right"}}>
                <p style={{margin:0,fontWeight:700,fontSize:20,color:sel?D.lime:D.text}}>{promoSuccess?.type==="percent"?`$${(parseFloat(p.price.slice(1))*(1-promoSuccess.discount/100)).toFixed(2)}`:p.price}</p>
                <p style={{margin:0,fontSize:11,color:D.sub}}>{p.period}</p>
              </div>
            </button>
          );
        })}
        <div style={{display:"flex",gap:8,marginBottom:16}}>
          <input value={promoInput} onChange={e=>setPromoInput(e.target.value.toUpperCase())} placeholder="Promo code (try WELCOME)"
            style={{flex:1,padding:"12px 14px",background:D.card,border:`1.5px solid ${promoSuccess?D.lime:promoError?"#EF4444":D.border}`,borderRadius:12,fontSize:13,color:D.text,outline:"none",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}/>
          <button onClick={onApplyPromo} style={{padding:"12px 18px",background:promoSuccess?D.limeDim:D.card,border:`1px solid ${promoSuccess?D.lime:D.border}`,borderRadius:12,fontSize:13,fontWeight:700,color:promoSuccess?D.lime:D.text,cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>
            {promoSuccess?"✓":"Apply"}
          </button>
        </div>
        {promoError&&<p style={{color:"#EF4444",fontSize:12,margin:"-8px 0 12px"}}>{promoError}</p>}
        {promoSuccess&&<p style={{color:D.lime,fontSize:12,margin:"-8px 0 12px",fontWeight:600}}>🎉 {promoSuccess.label} applied!</p>}
      </div>
      <div style={{padding:"0 20px 32px"}}>
        <button onClick={onNext} style={{width:"100%",padding:"17px",background:D.lime,border:"none",borderRadius:13,fontSize:15,fontWeight:700,color:"#0A0A0F",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",animation:"glowPulse 2s ease-in-out infinite"}}>
          Start Free Trial →
        </button>
        <p style={{textAlign:"center",color:D.sub,fontSize:12,margin:"10px 0 0"}}><span style={{color:D.lime,fontWeight:700}}>No payment due now</span> · Cancel anytime</p>
      </div>
    </div>
  );
}

function PaywallStep2({form,selectedPlan,promoSuccess,onNext,onBack}) {
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",padding:"24px 20px 32px",background:D.bg}}>
      <button onClick={onBack} style={{background:"none",border:"none",color:D.sub,cursor:"pointer",display:"flex",alignItems:"center",gap:4,fontSize:13,fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",padding:"0 0 20px 0",alignSelf:"flex-start"}}>
        <Ic d={ic.back} size={16} c={D.sub}/> Back
      </button>
      <h2 style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:26,fontWeight:700,color:D.text,margin:"0 0 8px",letterSpacing:"-0.5px"}}>We've got you covered</h2>
      <p style={{color:D.sub,fontSize:14,margin:"0 0 24px",lineHeight:1.5}}>Your trust matters. Here's what happens next.</p>
      <div style={{display:"flex",flexDirection:"column",gap:12,flex:1}}>
        {[["🔒","No charge today","Your trial starts immediately, completely free"],["📨","Reminder 3 days before","We'll email you before anything charges"],["❌","Cancel any time","Cancel in the app — no questions asked"],["🔐","Secure payment","256-bit encryption, trusted by thousands"]].map(([e,t,d],i)=>(
          <div key={i} style={{display:"flex",gap:14,alignItems:"flex-start",background:D.card,borderRadius:16,padding:"16px 18px",border:`1px solid ${D.border}`}}>
            <span style={{fontSize:26,lineHeight:1,marginTop:2}}>{e}</span>
            <div><p style={{margin:"0 0 3px",fontWeight:700,fontSize:14,color:D.text}}>{t}</p><p style={{margin:0,fontSize:13,color:D.sub,lineHeight:1.4}}>{d}</p></div>
          </div>
        ))}
      </div>
      <div style={{background:D.limeDim,borderRadius:13,padding:"14px 18px",border:`1px solid rgba(163,230,53,0.2)`,margin:"16px 0 20px"}}>
        <p style={{margin:"0 0 4px",fontSize:13,color:D.text,fontStyle:"italic",lineHeight:1.5}}>"I haven't missed a single dose in 3 months. The reminders are perfectly timed."</p>
        <p style={{margin:0,fontSize:11,color:D.sub}}>— Sarah K., managing Type 2 Diabetes ⭐⭐⭐⭐⭐</p>
      </div>
      <button onClick={onNext} style={{width:"100%",padding:"17px",background:D.lime,border:"none",borderRadius:13,fontSize:15,fontWeight:700,color:"#0A0A0F",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>
        I Understand, Continue →
      </button>
    </div>
  );
}

function PaywallStep3({form,selectedPlan,promoSuccess,onDone,onBack}) {
  const trialDays = promoSuccess?.type==="trial"?(promoSuccess.label.includes("30")?30:14):7;
  const today=new Date(), trialEnd=new Date(today);
  trialEnd.setDate(today.getDate()+trialDays);
  const reminderDate=new Date(trialEnd);
  reminderDate.setDate(trialEnd.getDate()-3);
  const fmtDate=d=>d.toLocaleDateString("en-US",{month:"short",day:"numeric"});
  const TIMELINE=[
    {label:"Today",date:fmtDate(today),desc:"Start free trial",color:D.lime,icon:"🚀"},
    {label:`Day ${trialDays-3}`,date:fmtDate(reminderDate),desc:"We email you a reminder",color:D.amber,icon:"📧"},
    {label:`Day ${trialDays}`,date:fmtDate(trialEnd),desc:selectedPlan==="annual"?"$35.88 billed":"$7.99 billed",color:D.blue,icon:"💳"},
  ];
  return(
    <div style={{flex:1,display:"flex",flexDirection:"column",padding:"24px 20px 32px",background:D.bg}}>
      <button onClick={onBack} style={{background:"none",border:"none",color:D.sub,cursor:"pointer",display:"flex",alignItems:"center",gap:4,fontSize:13,fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",padding:"0 0 20px 0",alignSelf:"flex-start"}}>
        <Ic d={ic.back} size={16} c={D.sub}/> Back
      </button>
      <h2 style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:26,fontWeight:700,color:D.text,margin:"0 0 8px",letterSpacing:"-0.5px"}}>Here's exactly what happens</h2>
      <p style={{color:D.sub,fontSize:14,margin:"0 0 24px"}}>No surprises. No confusion.</p>
      <div style={{position:"relative",flex:1}}>
        <div style={{position:"absolute",left:27,top:40,bottom:40,width:2,background:`linear-gradient(to bottom,${D.lime},${D.amber},${D.blue})`,borderRadius:99,opacity:0.3}}/>
        {TIMELINE.map((t,i)=>(
          <div key={i} style={{display:"flex",gap:16,alignItems:"flex-start",padding:"12px 0",position:"relative",zIndex:1}}>
            <div style={{width:40,height:40,borderRadius:99,background:i===0?t.color:D.card,border:`2px solid ${t.color}`,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}>
              <span style={{fontSize:16}}>{t.icon}</span>
            </div>
            <div style={{flex:1,background:D.card,borderRadius:16,padding:"14px 16px",border:`1px solid ${i===0?t.color:D.border}`}}>
              <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:4}}>
                <p style={{margin:0,fontWeight:700,fontSize:14,color:i===0?t.color:D.text}}>{t.label}</p>
                <span style={{fontSize:11,fontWeight:700,color:D.sub}}>{t.date}</span>
              </div>
              <p style={{margin:0,fontSize:13,color:i===0?D.text:D.sub}}>{t.desc}</p>
            </div>
          </div>
        ))}
      </div>
      <div style={{background:D.card,borderRadius:13,padding:"16px 18px",border:`1px solid ${D.border}`,margin:"12px 0 16px"}}>
        <div style={{display:"flex",justifyContent:"space-between",marginBottom:8}}>
          <span style={{fontSize:14,fontWeight:700,color:D.text}}>Free trial</span>
          <span style={{fontSize:14,fontWeight:700,color:D.lime}}>{trialDays} days FREE</span>
        </div>
        {promoSuccess&&<div style={{display:"flex",justifyContent:"space-between",marginBottom:8}}><span style={{fontSize:13,color:D.sub}}>Promo</span><span style={{fontSize:13,fontWeight:700,color:D.lime}}>🎉 {promoSuccess.label}</span></div>}
        <div style={{display:"flex",justifyContent:"space-between"}}>
          <span style={{fontSize:14,fontWeight:700,color:D.text}}>Then</span>
          <span style={{fontSize:14,fontWeight:700,color:D.sub}}>{selectedPlan==="annual"?"$2.99/mo":"$7.99/mo"}</span>
        </div>
      </div>
      <button onClick={onDone} style={{width:"100%",padding:"18px",background:D.lime,border:"none",borderRadius:13,fontSize:15,fontWeight:700,color:"#0A0A0F",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",animation:"glowPulse 2s ease-in-out infinite"}}>
        Start My {trialDays}-Day Free Trial 🚀
      </button>
      <p style={{textAlign:"center",color:D.sub,fontSize:11,margin:"10px 0 0",lineHeight:1.5}}>Cancel any time before {fmtDate(trialEnd)} to avoid being charged.</p>
    </div>
  );
}

function Confetti() {
  const pieces=Array.from({length:60},(_,i)=>({
    id:i,color:["#A3E635","#10B981","#3B82F6","#F59E0B","#EF4444","#8B5CF6","#EC4899"][i%7],
    left:`${Math.random()*100}%`,delay:`${Math.random()*1.5}s`,duration:`${2+Math.random()*2}s`,
    size:`${6+Math.random()*8}px`,shape:Math.random()>0.5?"circle":"square",
  }));
  return(
    <div style={{position:"fixed",inset:0,pointerEvents:"none",zIndex:9999,overflow:"hidden"}}>
      {pieces.map(p=>(
        <div key={p.id} style={{position:"absolute",top:-20,left:p.left,width:p.size,height:p.size,background:p.color,borderRadius:p.shape==="circle"?"50%":"3px",animation:`confettiFall ${p.duration} ${p.delay} ease-in forwards`}}/>
      ))}
    </div>
  );
}

function CelebrationModal({med,onDone}) {
  const L=useTheme();
  return(
    <div style={{position:"fixed",inset:0,background:"rgba(0,0,0,0.45)",zIndex:1000,display:"flex",alignItems:"center",justifyContent:"center",padding:20,backdropFilter:"blur(24px) saturate(160%)",WebkitBackdropFilter:"blur(24px) saturate(160%)"}}>
      <Confetti/>
      <div style={{background:L.card,borderRadius:20,padding:32,textAlign:"center",maxWidth:320,width:"100%",animation:"celebPop 0.5s cubic-bezier(0.34,1.56,0.64,1) forwards",position:"relative",zIndex:1001,border:`1px solid rgba(163,230,53,0.3)`}}>
        <div style={{fontSize:64,marginBottom:4,animation:"floatUp 2s ease-in-out infinite"}}>🏆</div>
        <h2 style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:26,color:L.text,margin:"12px 0 8px",lineHeight:1.2}}>Course Complete!</h2>
        <p style={{color:L.blue,fontWeight:700,fontSize:18,margin:"0 0 6px"}}>{med.name}</p>
        <p style={{color:"rgba(60,60,67,0.6)",fontSize:15,lineHeight:1.6,margin:"0 0 24px"}}>Outstanding! You finished your full course. 🌟</p>
        <button onClick={onDone} style={{width:"100%",padding:"14px",background:L.blue,border:"none",borderRadius:14,fontSize:17,fontWeight:600,color:"#fff",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>Done ✓</button>
      </div>
    </div>
  );
}

function ReminderNotification({queue,onDone,onSnooze,onDismiss}) {
  const n=queue[0];
  const L=useTheme();
  if(!n) return null;
  const {med,sched,key}=n;
  return(
    <div style={{position:"fixed",top:12,left:"50%",transform:"translateX(-50%)",width:"calc(100% - 32px)",maxWidth:398,zIndex:2000,animation:"notifSlide 0.45s cubic-bezier(0.34,1.56,0.64,1) forwards"}}>
      <div style={{background:"#13131A",borderRadius:14,padding:"16px 18px",boxShadow:"0 12px 40px rgba(0,0,0,0.5)",border:`1px solid rgba(163,230,53,0.2)`}}>
        {queue.length>1&&<div style={{display:"flex",gap:4,marginBottom:10}}>{queue.map((_,i)=><div key={i} style={{height:3,flex:1,background:i===0?"#A3E635":"#1E1E2A",borderRadius:99}}/>)}</div>}
        <div style={{display:"flex",alignItems:"center",gap:12,marginBottom:14}}>
          <div style={{width:46,height:46,borderRadius:15,background:`${med.color}25`,border:`2px solid ${med.color}`,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0,animation:"pulseDot 2s ease-in-out infinite"}}>
            <span style={{fontSize:22}}>{med.isLiquid?"🧴":"💊"}</span>
          </div>
          <div style={{flex:1}}>
            <p style={{margin:0,fontWeight:700,fontSize:14,color:"#F0F0F5"}}>Time to take your medicine</p>
            <p style={{margin:"2px 0 0",fontSize:14,color:"rgba(235,235,245,0.55)"}}>{med.name} {med.dose} · {sched.label}</p>
            {sched.withFood&&<p style={{margin:"2px 0 0",fontSize:11,color:"#666"}}>🍽️ Take with food</p>}
          </div>
          <button onClick={()=>onDismiss(key)} style={{background:"none",border:"none",color:"#666",cursor:"pointer",padding:4}}><Ic d={ic.x} size={16} c="#666"/></button>
        </div>
        <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:1}}>
          <button onClick={()=>onSnooze(key)} style={{padding:"12px",background:"rgba(255,255,255,0.1)",border:"none",borderRadius:10,fontSize:14,fontWeight:500,color:"rgba(235,235,245,0.8)",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>Snooze 10m</button>
          <button onClick={()=>onDone(n)} style={{padding:"12px",background:med.color,border:"none",borderRadius:12,fontSize:13,fontWeight:700,color:"#fff",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",display:"flex",alignItems:"center",justifyContent:"center",gap:6}}>
            <Ic d={ic.check} size={14} c="#fff" w={2.5}/> Taken ✓
          </button>
        </div>
      </div>
    </div>
  );
}

function LowStockBanner({med,onDismiss}) {
  const unit = med.isLiquid ? (med.volumeUnit||"ml") : "pill";
  const L=useTheme();
  return(
    <div style={{position:"fixed",top:12,left:"50%",transform:"translateX(-50%)",width:"calc(100% - 32px)",maxWidth:398,zIndex:2001,animation:"notifSlide 0.4s cubic-bezier(0.34,1.56,0.64,1) forwards"}}>
      <div style={{background:"#7C2D12",borderRadius:13,padding:"14px 18px",boxShadow:"0 8px 32px rgba(0,0,0,0.4)",border:"1px solid #B91C1C",display:"flex",alignItems:"center",gap:12}}>
        <span style={{fontSize:24}}>⚠️</span>
        <div style={{flex:1}}>
          <p style={{margin:0,fontWeight:600,fontSize:13,color:"rgba(235,235,245,0.9)"}}>Low Stock</p>
          <p style={{margin:"2px 0 0",fontSize:12,color:L.red}}>{med.name} — only {med.count} {unit}{med.count!==1&&!med.isLiquid?"s":""} left</p>
        </div>
        <button onClick={onDismiss} style={{background:"none",border:"none",color:"#FCA5A5",cursor:"pointer",padding:4}}><Ic d={ic.x} size={16} c="#FCA5A5"/></button>
      </div>
    </div>
  );
}

/* ══════════════════════════════════════════════
   APP SHELL — Cal AI Style Bottom Nav + FAB
══════════════════════════════════════════════ */
function AppShell({children,tab,setTab,notifCount,missedAlertCount,darkMode=false,onScanFAB}) {
  const L=useTheme();
  // Cal AI: 3 nav items + floating action button (like Cal AI's +)
  const navItems=[
    {id:"home",    label:"Home",     icon:"M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z M9 22V12h6v10"},
    {id:"history", label:"Progress", icon:"M18 20V10 M12 20V4 M6 20v-6"},
    {id:"alarms",  label:"Alarms",   icon:ic.bell},
  ];
  const bg = darkMode ? "rgba(18,18,24,0.97)" : "rgba(255,255,255,0.97)";
  const borderCol = darkMode ? "rgba(255,255,255,0.08)" : "rgba(0,0,0,0.08)";
  return(
    <div style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',Arial,sans-serif",background:darkMode?"#111":"#F5F5F5",minHeight:"100vh",maxWidth:430,margin:"0 auto",paddingBottom:96}}>
      {children}
      {/* Cal AI style bottom nav */}
      <nav style={{position:"fixed",bottom:0,left:"50%",transform:"translateX(-50%)",width:"100%",maxWidth:430,zIndex:100}}>
        <div style={{background:bg,borderTop:`1px solid ${borderCol}`,backdropFilter:"blur(24px) saturate(180%)",WebkitBackdropFilter:"blur(24px) saturate(180%)",display:"flex",alignItems:"center",paddingTop:10,paddingBottom:28,paddingLeft:8,paddingRight:8,position:"relative"}}>
          {/* Left 2 nav items */}
          <div style={{display:"flex",flex:1}}>
            {navItems.slice(0,2).map(n=>{
              const active=tab===n.id;
              const cnt=n.id==="alarms"?notifCount:n.id==="family"?missedAlertCount:0;
              return(
                <button key={n.id} onClick={()=>setTab(n.id)}
                  style={{flex:1,background:"transparent",border:"none",cursor:"pointer",display:"flex",flexDirection:"column",alignItems:"center",gap:4,padding:"2px 0",WebkitTapHighlightColor:"transparent"}}>
                  <div style={{position:"relative",width:26,height:26,display:"flex",alignItems:"center",justifyContent:"center"}}>
                    <Ic d={n.icon} size={22} c={active?L.text:L.sub} w={active?2.2:1.7}/>
                    {cnt>0&&(
                      <div style={{position:"absolute",top:-3,right:-6,minWidth:14,height:14,borderRadius:7,background:"#EF4444",border:`2px solid ${bg}`,display:"flex",alignItems:"center",justifyContent:"center",padding:"0 2px"}}>
                        <span style={{fontSize:8,fontWeight:800,color:"#fff",lineHeight:1}}>{cnt>9?"9+":cnt}</span>
                      </div>
                    )}
                  </div>
                  <span style={{fontSize:10,fontWeight:active?700:500,color:active?L.text:L.sub,letterSpacing:"-0.1px",lineHeight:1}}>{n.label}</span>
                </button>
              );
            })}
          </div>

          {/* Cal AI floating + FAB in center */}
          <div style={{width:80,display:"flex",justifyContent:"center",position:"relative"}}>
            <button onClick={()=>setTab("scan")}
              style={{width:56,height:56,borderRadius:"50%",background:"#111111",border:"none",cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center",boxShadow:"0 4px 20px rgba(0,0,0,0.25),0 1px 4px rgba(0,0,0,0.15)",marginTop:-28,transition:"transform 0.15s cubic-bezier(0.34,1.56,0.64,1)",WebkitTapHighlightColor:"transparent"}}>
              <svg width={22} height={22} viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth={2.5} strokeLinecap="round" strokeLinejoin="round">
                <path d="M12 5v14 M5 12h14"/>
              </svg>
            </button>
          </div>

          {/* Right nav items */}
          <div style={{display:"flex",flex:1}}>
            {navItems.slice(2).map(n=>{
              const active=tab===n.id;
              const cnt=n.id==="family"?missedAlertCount:0;
              return(
                <button key={n.id} onClick={()=>setTab(n.id)}
                  style={{flex:1,background:"transparent",border:"none",cursor:"pointer",display:"flex",flexDirection:"column",alignItems:"center",gap:4,padding:"2px 0",WebkitTapHighlightColor:"transparent"}}>
                  <div style={{position:"relative",width:26,height:26,display:"flex",alignItems:"center",justifyContent:"center"}}>
                    <Ic d={n.icon} size={22} c={active?L.text:L.sub} w={active?2.2:1.7}/>
                  </div>
                  <span style={{fontSize:10,fontWeight:active?700:500,color:active?L.text:L.sub,letterSpacing:"-0.1px",lineHeight:1}}>{n.label}</span>
                </button>
              );
            })}
            {/* Family tab (badge only, no bottom nav slot) */}
            <button onClick={()=>setTab("family")}
              style={{flex:1,background:"transparent",border:"none",cursor:"pointer",display:"flex",flexDirection:"column",alignItems:"center",gap:4,padding:"2px 0",WebkitTapHighlightColor:"transparent"}}>
              <div style={{position:"relative",width:26,height:26,display:"flex",alignItems:"center",justifyContent:"center"}}>
                <Ic d={ic.users} size={22} c={tab==="family"?L.text:L.sub} w={tab==="family"?2.2:1.7}/>
                {missedAlertCount>0&&(
                  <div style={{position:"absolute",top:-3,right:-6,minWidth:14,height:14,borderRadius:7,background:"#EF4444",border:`2px solid ${bg}`,display:"flex",alignItems:"center",justifyContent:"center",padding:"0 2px"}}>
                    <span style={{fontSize:8,fontWeight:800,color:"#fff",lineHeight:1}}>{missedAlertCount>9?"9+":missedAlertCount}</span>
                  </div>
                )}
              </div>
              <span style={{fontSize:10,fontWeight:tab==="family"?700:500,color:tab==="family"?L.text:L.sub,letterSpacing:"-0.1px",lineHeight:1}}>Family</span>
            </button>
          </div>
        </div>
      </nav>
    </div>
  );
}

/* ══════════════════════════════════════════════
   APP ROOT
══════════════════════════════════════════════ */
export default function App() {
  const [phase,setPhase]=useState("loading");  // loading → onboarding → app
  const [profile,setProfile]=useState(null);
  const [tab,setTab]=useState("home");
  const prevTab=useRef("home");
  const [meds,setMeds]=useState([]);
  const [history,setHistory]=useState({});
  const [takenToday,setTakenToday]=useState({});
  const [streakData,setStreakData]=useState({frozen:false,freezeUsedWeek:false});
  const [scanState,setScanState]=useState("idle");
  const [scanResult,setScanResult]=useState(null);
  const [detailMed,setDetailMed]=useState(null);
  const [editMed,setEditMed]=useState(null);
  const [deleteConfirm,setDeleteConfirm]=useState(null); // med to confirm delete
  const [notifQueue,setNotifQueue]=useState([]);
  const [snoozed,setSnoozed]=useState({});
  const [dismissed,setDismissed]=useState({});
  const [lowStockBanner,setLowStockBanner]=useState(null);
  const [celebration,setCelebration]=useState(null);
  const [insight,setInsight]=useState("");
  const [loadingInsight,setLoadingInsight]=useState(false);
  const [feedbackKey,setFeedbackKey]=useState({});
  const [caregivers,setCaregivers]=useState([]);
  const [missedAlerts,setMissedAlerts]=useState([]);
  const [caregiverBanner,setCaregiverBanner]=useState(null);
  const [showSettings,setShowSettings]=useState(false);
  const [darkMode,setDarkMode]=useState(false);
  const [toast,setToast]=useState(null);  // {message, type}
  const missedChecked=useRef({});
  const reminderShown=useRef({});
  const storageLoaded=useRef(false);

  // ── Show toast helper
  const toastTimer=useRef(null);
  const showToast = useCallback((message,type="success")=>{
    clearTimeout(toastTimer.current);
    setToast({message,type,id:Date.now()});
    toastTimer.current=setTimeout(()=>setToast(null),3000);
  },[]);

  // ── Load ALL state from storage on mount
  useEffect(()=>{
    (async()=>{
      try{
        const [savedProfile,savedMeds,savedHistory,savedCg,savedStreak,savedTaken,savedDark] = await Promise.allSettled([
          window.storage.get("profile"),
          window.storage.get("meds"),
          window.storage.get("history"),
          window.storage.get("caregivers"),
          window.storage.get("streakData"),
          window.storage.get("takenToday"),
          window.storage.get("darkMode"),
        ]);
        let hasProfile=false;
        if(savedProfile.value?.value){try{const p=JSON.parse(savedProfile.value.value);if(p?.name){setProfile(p);hasProfile=true;}}catch(e){}}
        if(savedMeds.value?.value){try{const m=JSON.parse(savedMeds.value.value);if(Array.isArray(m)&&m.length>0)setMeds(m);}catch(e){}}
        if(savedHistory.value?.value){try{const h=JSON.parse(savedHistory.value.value);if(h&&typeof h==="object")setHistory(h);}catch(e){}}
        if(savedCg.value?.value){try{const c=JSON.parse(savedCg.value.value);if(Array.isArray(c))setCaregivers(c);}catch(e){}}
        if(savedStreak.value?.value){try{const s=JSON.parse(savedStreak.value.value);if(s)setStreakData(s);}catch(e){}}
        if(savedTaken.value?.value){try{const t=JSON.parse(savedTaken.value.value);if(t&&typeof t==="object")setTakenToday(t);}catch(e){}}
        if(savedDark.value?.value){try{setDarkMode(JSON.parse(savedDark.value.value));}catch(e){}}
        const savedAlerts=await window.storage.get("missedAlerts").catch(()=>null);
        if(savedAlerts?.value){try{const a=JSON.parse(savedAlerts.value);if(Array.isArray(a))setMissedAlerts(a);}catch(e){}}
        storageLoaded.current=true;
        const newPhase=hasProfile?"app":"onboarding";
        setPhase(newPhase);
      }catch(e){
        storageLoaded.current=true;
        setPhase("onboarding");
      }
    })();
  },[]);

  // ── Persist all state on change (debounced)
  const persistTimer=useRef(null);
  useEffect(()=>{
    if(!storageLoaded.current) return;
    clearTimeout(persistTimer.current);
    persistTimer.current=setTimeout(async()=>{
      try{
        await Promise.allSettled([
          window.storage.set("meds",JSON.stringify(meds)),
          window.storage.set("history",JSON.stringify(history)),
          window.storage.set("caregivers",JSON.stringify(caregivers)),
          window.storage.set("streakData",JSON.stringify(streakData)),
          window.storage.set("takenToday",JSON.stringify(takenToday)),
          window.storage.set("darkMode",JSON.stringify(darkMode)),
          window.storage.set("missedAlerts",JSON.stringify(missedAlerts.slice(0,30))),
        ]);
      }catch(e){}
    },600);
  },[meds,history,caregivers,streakData,takenToday,darkMode,missedAlerts]);

  // Persist profile immediately
  useEffect(()=>{
    if(!storageLoaded.current||!profile) return;
    window.storage.set("profile",JSON.stringify(profile)).catch(()=>{});
  },[profile]);

  // Trigger low-stock banner when a med's count drops to/below refillAt
  useEffect(()=>{
    if(phase!=="app") return;
    const low=meds.find(m=>m.count<=m.refillAt&&m.count>0);
    if(low&&(!lowStockBanner||lowStockBanner.id!==low.id)){
      setLowStockBanner(low);
    } else if(!low&&lowStockBanner){
      setLowStockBanner(null);
    }
  },[meds,phase]);

  // Auto-load insight once app is ready
  useEffect(()=>{
    if(phase==="app"&&meds.length>0&&!insight&&!loadingInsight){
      const t=setTimeout(getInsight,1200);
      return()=>clearTimeout(t);
    }
  },[phase]);

  // Scroll to top on tab switch
  useEffect(()=>{
    if(tab!==prevTab.current){
      prevTab.current=tab;
      window.scrollTo({top:0,behavior:"smooth"});
    }
  },[tab]);

  // Reset takenToday at midnight
  useEffect(()=>{
    const now=new Date();
    const msUntilMidnight=new Date(now.getFullYear(),now.getMonth(),now.getDate()+1)-now;
    const t=setTimeout(()=>setTakenToday({}),msUntilMidnight);
    return()=>clearTimeout(t);
  },[]);

  function deleteAllData(){
    setMeds([]); setHistory({}); setCaregivers([]); setTakenToday({});
    setStreakData({frozen:false,freezeUsedWeek:false}); setInsight("");
    setMissedAlerts([]); setCaregiverBanner(null); setLowStockBanner(null);
    ['meds','history','caregivers','streakData','takenToday','missedAlerts'].forEach(k=>window.storage.delete(k).catch(()=>{}));
  }

  const camRef=useRef(), galRef=useRef();

  const today=useMemo(()=>todayStr(),[]);
  const doses=useMemo(()=>
    meds.flatMap(m=>m.schedule.filter(s=>s.enabled&&s.days.includes(dayIdx())).map(s=>({med:m,sched:s,key:`${m.id}-${s.label}`}))).sort((a,b)=>(a.sched.time.h*60+a.sched.time.m)-(b.sched.time.h*60+b.sched.time.m))
  ,[meds]);
  const takenCount=useMemo(()=>doses.filter(d=>takenToday[d.key]).length,[doses,takenToday]);
  const dosePct=useMemo(()=>doses.length?takenCount/doses.length:0,[doses.length,takenCount]);
  const lowMeds=useMemo(()=>meds.filter(m=>m.count<=m.refillAt&&m.count>0),[meds]);

  const streak=useMemo(()=>{
    let s=0;
    const keys=Object.keys(history).sort().reverse();
    for(const k of keys){
      if(k===today) continue;
      const ds=history[k]||[];
      if(!ds.length){if(s===0&&streakData.frozen)continue;break;}
      const rate=ds.filter(d=>d.taken).length/ds.length;
      if(rate>=0.8) s++; else break;
    }
    return s;
  },[history,today,streakData]);

  useEffect(()=>{
    if(phase!=="app") return;
    const check=()=>{
      const now=nowMins();
      const newQueue=[];
      for(const d of doses){
        const schedMins=d.sched.time.h*60+d.sched.time.m;
        const key=d.key+"-"+today;
        const snoozeUntil=snoozed[key]||0;
        if(Math.abs(now-schedMins)<=2&&!takenToday[d.key]&&!dismissed[key]&&now>=snoozeUntil&&!reminderShown.current[key]){
          reminderShown.current[key]=true;
          newQueue.push(d);
        }
      }
      if(newQueue.length>0) setNotifQueue(q=>[...q,...newQueue.filter(n=>!q.find(x=>x.key===n.key))]);
    };
    const id=setInterval(check,30000);
    return()=>clearInterval(id);
  },[phase,doses,takenToday,snoozed,dismissed,today]);

  // Missed-dose caregiver alert (fires 30 min after scheduled time)
  useEffect(()=>{
    if(phase!=="app") return;
    const activeCaregivers=caregivers.filter(c=>c.status==="active");
    if(!activeCaregivers.length) return;
    const check=()=>{
      const now=nowMins();
      for(const d of doses){
        const schedMins=d.sched.time.h*60+d.sched.time.m;
        const ckKey=d.key+"-"+today+"-cg";
        if(now>schedMins+30&&!takenToday[d.key]&&!missedChecked.current[ckKey]){
          missedChecked.current[ckKey]=true;
          const timeLabel=fmt(d.sched.time.h,d.sched.time.m);
          const alert={id:Date.now()+Math.random(),medName:d.med.name,doseLabel:d.sched.label,time:timeLabel,timestamp:new Date().toLocaleTimeString("en-US",{hour:"2-digit",minute:"2-digit"}),caregivers:activeCaregivers};
          setMissedAlerts(p=>[alert,...p].slice(0,20));
          setCaregiverBanner(alert);
        }
      }
    };
    const id=setInterval(check,60000);
    check();
    return()=>clearInterval(id);
  },[phase,doses,takenToday,today,caregivers]);

  const updateMed=useCallback((id,ch)=>{
    setMeds(p=>p.map(m=>{
      if(m.id!==id) return m;
      const updated={...m,...ch};
      if(ch.count!==undefined&&updated.count<=updated.refillAt&&updated.count>0&&m.count>m.refillAt)
        setTimeout(()=>setLowStockBanner(updated),600);
      if(ch.count!==undefined&&updated.count===0&&m.count>0)
        setTimeout(()=>setCelebration(updated),800);
      return updated;
    }));
  },[]);

  const deleteMed=useCallback((id)=>{
    setMeds(p=>p.filter(m=>m.id!==id));
    setDetailMed(null);
    setDeleteConfirm(null);
    showToast("Medicine removed");
  },[showToast]);

  const handleTakenFromNotif=useCallback((n)=>{
    const {med,sched,key}=n;
    setTakenToday(p=>({...p,[key]:true}));
    const timeStr=`${String(sched.time.h).padStart(2,"0")}:${String(sched.time.m).padStart(2,"0")}`;
    setHistory(p=>{
      const todayKey=todayStr();
      return {...p,[todayKey]:[...(p[todayKey]||[]),{medId:med.id,label:sched.label,time:timeStr,taken:true}]};
    });
    updateMed(med.id,{count:Math.max(0,med.count-1)});
    setNotifQueue(q=>q.filter(x=>x.key!==key));
    setFeedbackKey(p=>({...p,[key]:Date.now()}));
  },[updateMed]);

  const handleToggleDose=useCallback((key)=>{
    const todayKey=todayStr();
    setTakenToday(prev=>{
      const wasTaken=prev[key];
      const newTaken={...prev,[key]:!prev[key]};
      if(!wasTaken){
        const dose=doses.find(d=>d.key===key);
        if(dose){
          const {med,sched}=dose;
          const timeStr=String(sched.time.h).padStart(2,"0")+":"+String(sched.time.m).padStart(2,"0");
          setHistory(p=>({...p,[todayKey]:[...(p[todayKey]||[]),{medId:med.id,label:sched.label,time:timeStr,taken:true}]}));
          updateMed(med.id,{count:Math.max(0,med.count-1)});
          showToast("✓ "+med.name+" taken","success");
          const newTakenCount=Object.keys(newTaken).filter(k=>newTaken[k]).length;
          if(newTakenCount===doses.length&&doses.length>0&&!celebration){
            setTimeout(()=>setCelebration({name:"All Done! 🎉",color:"#34C759"}),400);
          }
        }
      } else {
        showToast("Dose unmarked","info");
      }
      setFeedbackKey(p=>({...p,[key]:Date.now()}));
      return newTaken;
    });
  },[doses,updateMed,showToast,celebration]);

  const saveScan=useCallback((r)=>{
    const isLiq=r.isLiquid;
    const count=isLiq?(r.volumeAmount||100):(r.pillCount||30);
    const total=isLiq?(r.volumeAmount||100):(r.packSize||r.pillCount||30);
    setMeds(p=>[...p,{
      id:Date.now(),name:r.name||"Unknown",brand:r.brand||"",dose:r.dose||"",
      form:r.form||"tablet",category:r.category||"",
      count,totalCount:total,
      color:PILL_COLORS[p.length%PILL_COLORS.length],
      refillAt:r.refillAlert||7,imageUrl:r.imageUrl,notes:r.description||"",
      schedule:[],courseStartDate:todayStr(),
      isLiquid:isLiq,volumeUnit:r.volumeUnit||"ml",dosePerTake:r.dosePerTake||"",
    }]);
    setScanState("idle"); setScanResult(null); setTab("home");
  },[]);

  async function doScan(file){
    try{
      const b64=await f2b64(file), imgUrl=URL.createObjectURL(file);
      const prompt=`You are a clinical pharmacist. Analyse this medicine image carefully.
Determine if it's a SOLID form (tablet/capsule/pill) or LIQUID form (syrup/suspension/drops/solution/cream/gel/inhaler/injection).
Respond ONLY with valid JSON, no markdown, no explanation:
{
  "identified": true,
  "name": "generic name",
  "brand": "brand name if visible",
  "dose": "strength e.g. 500mg or 100mg/5ml",
  "form": "tablet|capsule|syrup|suspension|drops|cream|gel|inhaler|injection|powder|other",
  "isLiquid": false,
  "category": "e.g. Antibiotic",
  "description": "what it treats in 1 sentence",
  "howToTake": "brief instructions",
  "sideEffects": "top 2-3 side effects",
  "interactions": "key interactions",
  "storage": "storage instructions",
  "pillCount": 30,
  "packSize": 30,
  "refillAlert": 7,
  "volumeAmount": 0,
  "volumeUnit": "ml",
  "dosePerTake": "",
  "confidence": "high|medium|low"
}
Rules:
- For LIQUID medicines (syrup, suspension, solution, drops, cream, gel): set isLiquid=true, volumeAmount to total volume in ml (e.g. 100 for a 100ml bottle), volumeUnit to the appropriate unit (ml, mg/5ml, drops), dosePerTake to typical dose e.g. "5ml", pillCount=0
- For SOLID medicines (tablet, capsule): set isLiquid=false, pillCount to count of tablets/capsules visible or standard pack size, volumeAmount=0
- For INHALERS: set isLiquid=true, volumeUnit="puffs", volumeAmount=200 (or detected puff count)
- If no medicine detected: set identified=false`;
      const res=await fetch("https://api.anthropic.com/v1/messages",{method:"POST",headers:{"Content-Type":"application/json","anthropic-dangerous-direct-browser-access":"true"},body:JSON.stringify({model:MODEL,max_tokens:600,messages:[{role:"user",content:[{type:"image",source:{type:"base64",media_type:file.type||"image/jpeg",data:b64}},{type:"text",text:prompt}]}]})});
      if(!res.ok){const err=await res.text();throw new Error("API error: "+res.status+" "+err.slice(0,100));}
      const data=await res.json();
      const raw=data.content?.map(c=>c.text||"").join("")||"";
      const txt=raw.replace(/^[\s\S]*?(\{[\s\S]*\})[\s\S]*$/, "$1").trim();
      if(!txt) throw new Error("Empty response from API");
      setScanResult({...JSON.parse(txt),imageUrl:imgUrl});
      setScanState("result");
    }catch(e){
      const errMsg=e?.message?.includes("API error")?e.message:"Could not identify — try a clearer, well-lit photo.";
      setScanResult({identified:false,name:"",brand:"",dose:"",form:"tablet",isLiquid:false,category:"",description:errMsg,howToTake:"",sideEffects:"",interactions:"",storage:"",pillCount:30,packSize:30,refillAlert:7,volumeAmount:0,volumeUnit:"ml",dosePerTake:"",confidence:"low",imageUrl:null});
      setScanState("result");
    }
  }

  const getInsight=useCallback(async()=>{
    setLoadingInsight(true); setInsight("");
    try{
      const medList=meds.map(m=>`${m.name} ${m.dose}`).join(", ");
      const res=await fetch("https://api.anthropic.com/v1/messages",{method:"POST",headers:{"Content-Type":"application/json","anthropic-dangerous-direct-browser-access":"true"},body:JSON.stringify({model:MODEL,max_tokens:180,messages:[{role:"user",content:"Patient"+(profile?.name?" "+profile.name:"")+` taking: ${medList}. Today: ${takenCount}/${doses.length} doses. Streak: ${streak} days. Give ONE warm, specific 2-sentence health tip. No lists. No markdown.`}]})});
      if(!res.ok) throw new Error("API "+res.status);
      const data=await res.json();
      setInsight(data.content?.[0]?.text||"Keep it up — consistency is everything! 💚");
    }catch(e){setInsight("Great job staying on track! Every dose counts towards your health goals. 💚");}
    setLoadingInsight(false);
  },[meds,profile,takenCount,doses.length,streak]);

  // Phase guards — loading first, then onboarding, then detail views
  if(phase==="loading"){
    return(
      <div style={{fontFamily:"'Figtree',-apple-system,sans-serif",background:"#F5F5F5",minHeight:"100vh",maxWidth:430,margin:"0 auto"}}>
        <style>{GLOBAL_CSS}</style>
        <HomeSkeleton/>
      </div>
    );
  }
  if(phase==="onboarding"){
    return <Onboarding onDone={p=>{setProfile(p);setPhase("app");window.storage.set("profile",JSON.stringify(p)).catch(()=>{});}}/>;
  }
  if(detailMed){
    const med=meds.find(m=>m.id===detailMed.id)||detailMed;
    return <MedDetail med={med} showToast={showToast} onBack={()=>setDetailMed(null)} onUpdate={updateMed} onDelete={deleteMed} onEdit={m=>{setEditMed(m);setDetailMed(null);}}/>;
  }
  if(editMed) return <EditMed med={editMed} onSave={ch=>{updateMed(editMed.id,ch);setEditMed(null);showToast("Changes saved");}} onBack={()=>setEditMed(null)} showToast={showToast}/>;

  return(
    <ThemeContext.Provider value={darkMode?L_DARK:L_LIGHT}>
    <AppShell tab={tab} setTab={setTab} notifCount={notifQueue.length} missedAlertCount={missedAlerts.filter(a=>!a.seen).length} darkMode={darkMode}>
      <style>{GLOBAL_CSS}</style>
      {/* System-level overlays */}
      {notifQueue.length>0&&<ReminderNotification queue={notifQueue} onDone={handleTakenFromNotif} onSnooze={(key)=>{setSnoozed(p=>({...p,[key+"-"+today]:nowMins()+10}));setNotifQueue(q=>q.filter(x=>x.key!==key));}} onDismiss={(key)=>{setDismissed(p=>({...p,[key+"-"+today]:true}));setNotifQueue(q=>q.filter(x=>x.key!==key));}}/>}
      {lowStockBanner&&<LowStockBanner med={lowStockBanner} onDismiss={()=>setLowStockBanner(null)}/>}
      {celebration&&<CelebrationModal med={celebration} onDone={()=>setCelebration(null)}/>}
      {caregiverBanner&&<CaregiverAlertBanner alert={caregiverBanner} onDismiss={()=>setCaregiverBanner(null)} onView={()=>{setTab("family");setCaregiverBanner(null);}}/>}
      {toast&&<Toast key={toast.id} message={toast.message} type={toast.type} onDone={()=>setToast(null)}/>}
      {/* Delete confirmation action sheet */}
      {deleteConfirm&&(
        <ActionSheet
          title={`Remove "${deleteConfirm.name}"`}
          sub="This will delete all schedule and history for this medicine."
          actions={[{label:"Delete Medicine",destructive:true,action:()=>deleteMed(deleteConfirm.id)}]}
          onCancel={()=>setDeleteConfirm(null)}
        />
      )}
      {/* Settings modal */}
      {showSettings&&(
        <SettingsModal
          profile={profile}
          onUpdateProfile={p=>setProfile(prev=>({...prev,...p}))}
          darkMode={darkMode}
          onToggleDark={()=>setDarkMode(v=>!v)}
          meds={meds}
          history={history}
          onDeleteAllData={deleteAllData}
          onClose={()=>setShowSettings(false)}
          onShowToast={showToast}
          streak={streak}
          streakData={streakData}
        />
      )}
      {/* Tabs */}
      {tab==="home"&&<HomeTab setTab={setTab} profile={profile} meds={meds} doses={doses} takenToday={takenToday} takenCount={takenCount} dosePct={dosePct} streak={streak} streakData={streakData} setStreakData={setStreakData} lowMeds={lowMeds} history={history} today={today} onToggle={handleToggleDose} onDetail={setDetailMed} onEdit={setEditMed} onDelete={m=>setDeleteConfirm(m)} onUpdate={updateMed} insight={insight} loadingInsight={loadingInsight} onInsight={getInsight} feedbackKey={feedbackKey} onSettings={()=>setShowSettings(true)} showToast={showToast}/>}
      {tab==="scan"&&<ScanTab showToast={showToast} state={scanState} result={scanResult} camRef={camRef} galRef={galRef} onFile={doScan} onReset={()=>{setScanState("idle");setScanResult(null);}} onSave={(r)=>{saveScan(r);showToast((r.name||"Medicine")+" added");}} setScanResult={setScanResult} setScanState={setScanState}/>}
      {tab==="history"&&<HistoryTab meds={meds} history={history} today={today} onRelog={entry=>{if(!entry.taken){setHistory(p=>({...p,[today]:(p[today]||[]).map(e=>e===entry?{...e,taken:true}:e)}));const doseKey=entry.medId+"-"+entry.label;setTakenToday(p=>({...p,[doseKey]:true}));const med=meds.find(m=>m.id===entry.medId);if(med)updateMed(med.id,{count:Math.max(0,med.count-1)});showToast("✓ Dose logged");}}} showToast={showToast}/>}
      {tab==="alarms"&&<AlarmsTab meds={meds} onUpdate={updateMed} showToast={showToast} setTab={setTab}/>}
      {tab==="family"&&<FamilyTab profile={profile} meds={meds} doses={doses} takenToday={takenToday} history={history} today={today} lowMeds={lowMeds} caregivers={caregivers} setCaregivers={setCaregivers} missedAlerts={missedAlerts} setMissedAlerts={setMissedAlerts} showToast={showToast} onSimulateMiss={()=>{const activeCGs=caregivers.filter(c=>c.status==="active");if(!activeCGs.length)return;const med=meds[0]||{name:"Medication",id:0};const al={id:Date.now(),medName:med.name,doseLabel:"Evening",time:fmt(20,0),timestamp:new Date().toLocaleTimeString("en-US",{hour:"2-digit",minute:"2-digit"}),caregivers:activeCGs,ts:Date.now(),escalation:["reminder","snooze","missed","caregiver_alert"]};setMissedAlerts(p=>[al,...p].slice(0,20));setCaregiverBanner(al);}}/>}
    </AppShell>
    </ThemeContext.Provider>
  );
}

/* ══════════════════════════════════════════════
   HOME TAB
══════════════════════════════════════════════ */
function HomeTab({profile,meds,doses,takenToday,takenCount,dosePct,streak,streakData,setStreakData,lowMeds,history,today,onToggle,onDetail,onEdit,onDelete,onUpdate,insight,loadingInsight,onInsight,feedbackKey,onSettings,showToast,setTab}) {
  const remaining=doses.length-takenCount;
  const L=useTheme();
  const ringCol=dosePct===1?L.green:dosePct>0.5?L.amber:L.blue;  // iOS activity ring
  const [showStreakModal,setShowStreakModal]=useState(false);
  return(
    <div style={{padding:"0 20px"}}>
      {/* Cal AI style header: logo left, streak pill right */}
      <div style={{paddingTop:54,paddingBottom:8}}>
        <div style={{display:"flex",justifyContent:"space-between",alignItems:"center"}}>
          {/* App name + apple icon — Cal AI style */}
          <div style={{display:"flex",alignItems:"center",gap:8}}>
            <div style={{width:34,height:34,borderRadius:10,background:"#111",display:"flex",alignItems:"center",justifyContent:"center",boxShadow:"0 2px 8px rgba(0,0,0,0.15)"}}>
              <span style={{fontSize:18,lineHeight:1}}>💊</span>
            </div>
            <span style={{fontFamily:"'Figtree',-apple-system,sans-serif",fontSize:20,fontWeight:800,color:L.text,letterSpacing:"-0.5px"}}>MedTrack<span style={{color:L.green}}>AI</span></span>
          </div>
          {/* Right pill group: streak + settings */}
          <div style={{display:"flex",alignItems:"center",gap:8}}>
            <button onClick={()=>setShowStreakModal(true)}
              style={{display:"flex",alignItems:"center",gap:6,background:"#111",padding:"8px 14px",borderRadius:99,border:"none",cursor:"pointer",boxShadow:"0 2px 8px rgba(0,0,0,0.18)",WebkitTapHighlightColor:"transparent"}}>
              <span className={streak>0?"flame-icon":""} style={{fontSize:16,lineHeight:1}}>🔥</span>
              <span style={{fontWeight:800,fontSize:14,color:"#fff",fontFamily:"'Figtree',-apple-system,sans-serif",letterSpacing:"-0.2px"}}>{streak}</span>
            </button>
            <button onClick={onSettings}
              style={{width:38,height:38,borderRadius:99,background:"#111",border:"none",cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center",boxShadow:"0 2px 8px rgba(0,0,0,0.18)",WebkitTapHighlightColor:"transparent"}}>
              <Ic d={ic.settings} size={16} c="#fff" w={1.8}/>
            </button>
          </div>
        </div>
        {/* Cal AI style week strip */}
        <div style={{marginTop:20,display:"flex",gap:6}}>
          {Array.from({length:7}).map((_,i)=>{
            const d=new Date(); d.setDate(d.getDate()-(6-i));
            const k=d.toISOString().slice(0,10);
            const isT=k===today;
            const ds=history[k]||[];
            const rate=ds.length?ds.filter(x=>x.taken).length/ds.length:0;
            const dayLabel=["S","M","T","W","T","F","S"][d.getDay()];
            const dayNum=d.getDate();
            return(
              <div key={i} style={{flex:1,display:"flex",flexDirection:"column",alignItems:"center",gap:4}}>
                <span style={{fontSize:11,fontWeight:600,color:isT?L.text:L.sub}}>{dayLabel}</span>
                <div style={{width:36,height:36,borderRadius:"50%",border:`2px solid ${isT?"#111":rate>=0.8?L.green:L.border}`,display:"flex",alignItems:"center",justifyContent:"center",background:isT?"#111":rate>=0.8?L.greenLight:"transparent",transition:"all 0.3s"}}>
                  <span style={{fontSize:12,fontWeight:isT?800:600,color:isT?"#fff":rate>=0.8?L.green:L.sub}}>{dayNum}</span>
                </div>
              </div>
            );
          })}
        </div>
      </div>
      {showStreakModal&&<StreakModal streak={streak} history={history} today={today} streakData={streakData} onFreeze={()=>{setStreakData(p=>({...p,frozen:true,freezeUsedWeek:true}));setShowStreakModal(false);}} onClose={()=>setShowStreakModal(false)}/>}
      {/* Cal AI style two-column stat cards */}
      <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:10,marginBottom:12}}>
        {/* Doses card */}
        <div style={{background:L.card,borderRadius:18,padding:"16px 16px 18px",boxShadow:"0 1px 4px rgba(0,0,0,0.06)"}}>
          <div style={{display:"flex",alignItems:"center",gap:6,marginBottom:4}}>
            <span style={{fontSize:16}}>💊</span>
            <span style={{fontSize:26,fontWeight:800,color:L.text,letterSpacing:"-1px",fontFamily:"'Figtree',-apple-system,sans-serif"}}>{takenCount}</span>
            <span style={{fontSize:13,color:L.sub,fontWeight:500}}>/{doses.length}</span>
          </div>
          <p style={{margin:"0 0 12px",fontSize:12,color:L.sub,fontWeight:500}}>Doses today</p>
          <Ring pct={dosePct} size={80} sw={7} color={ringCol} label={`${Math.round(dosePct*100)}%`} sub=""/>
        </div>
        {/* Adherence card */}
        <div style={{background:L.card,borderRadius:18,padding:"16px 16px 18px",boxShadow:"0 1px 4px rgba(0,0,0,0.06)"}}>
          <div style={{display:"flex",alignItems:"center",gap:6,marginBottom:4}}>
            <span style={{fontSize:16}}>📈</span>
            <span style={{fontSize:26,fontWeight:800,color:L.text,letterSpacing:"-1px",fontFamily:"'Figtree',-apple-system,sans-serif"}}>{remaining>0?remaining:0}</span>
          </div>
          <p style={{margin:"0 0 10px",fontSize:12,color:L.sub,fontWeight:500}}>Doses remaining</p>
          <div style={{display:"flex",flexDirection:"column",gap:5}}>
            {doses.slice(0,3).map((d,i)=>(
              <div key={i} style={{display:"flex",alignItems:"center",gap:6}}>
                <div style={{width:8,height:8,borderRadius:"50%",background:takenToday[d.key]?L.green:L.amber,flexShrink:0}}/>
                <span style={{fontSize:11,color:L.text,fontWeight:600,flex:1,overflow:"hidden",textOverflow:"ellipsis",whiteSpace:"nowrap"}}>{d.med.name}</span>
                <span style={{fontSize:10,color:L.sub}}>+{d.med.dose||"?"}</span>
              </div>
            ))}
            {doses.length===0&&<span style={{fontSize:11,color:L.sub}}>No doses scheduled</span>}
          </div>
        </div>
      </div>

      {/* AI Insight — Cal AI style clean card */}
      <div onClick={()=>!loadingInsight&&!insight&&onInsight()} style={{background:L.card,borderRadius:18,padding:"14px 16px",marginBottom:12,cursor:"pointer",boxShadow:"0 1px 4px rgba(0,0,0,0.06)"}}>
        <div style={{display:"flex",alignItems:"center",gap:10,marginBottom:insight||loadingInsight?10:0}}>
          <div style={{width:36,height:36,background:"#111",borderRadius:11,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}>
            <Ic d={ic.sparkle} size={16} c="#fff"/>
          </div>
          <div style={{flex:1}}>
            <p style={{margin:0,fontWeight:700,fontSize:14,color:L.text}}>AI Health Insight</p>
            {!insight&&!loadingInsight&&<p style={{margin:"1px 0 0",fontSize:11,color:L.sub}}>Tap for a personalised tip ✨</p>}
          </div>
          {insight&&<button onClick={e=>{e.stopPropagation();onInsight();}} style={{background:L.fill,border:"none",cursor:"pointer",borderRadius:8,padding:6}}><Ic d={ic.redo} size={13} c={L.sub}/></button>}
        </div>
        {loadingInsight&&<p style={{margin:0,fontSize:13,color:L.sub,fontStyle:"italic"}}>Thinking... ✨</p>}
        {insight&&<p style={{margin:0,fontSize:13,color:L.text,lineHeight:1.6}}>{insight}</p>}
      </div>

      {lowMeds.length>0&&(
        <div style={{background:"#FFF5F5",borderRadius:16,padding:"13px 16px",marginBottom:12,display:"flex",alignItems:"center",gap:12,border:"1px solid #FED7D7"}}>
          <Ic d={ic.alertTri} size={20} c={L.red}/>
          <div style={{flex:1}}>
            <p style={{margin:0,fontSize:13,fontWeight:700,color:L.red}}>Refill Soon</p>
            <p style={{margin:"2px 0 0",fontSize:12,color:L.sub}}>{lowMeds.map(m=>`${m.name} (${m.count}${m.isLiquid?m.volumeUnit||"ml":""} left)`).join(" · ")}</p>
          </div>
        </div>
      )}

      {/* Cal AI "Recently logged" style section header */}
      {doses.length>0&&(
        <section style={{marginBottom:20}}>
          <p style={{fontFamily:"'Figtree',-apple-system,sans-serif",fontSize:18,fontWeight:800,color:L.text,margin:"0 0 12px",letterSpacing:"-0.3px"}}>Today's Schedule</p>
          <div style={{display:"flex",flexDirection:"column",gap:8}}>
            {doses.map(d=>{
              const taken=takenToday[d.key];
              const now=new Date();
              const overdue=!taken&&(d.sched.time.h*60+d.sched.time.m)<(now.getHours()*60+now.getMinutes());
              const fbk=feedbackKey[d.key];
              const timeLabel=fmt(d.sched.time.h,d.sched.time.m);
              return(
                <div key={d.key} onClick={()=>onToggle(d.key)} style={{background:taken?"#F0FDF4":L.card,borderRadius:16,padding:"14px 16px",border:`1.5px solid ${taken?"#BBF7D0":overdue&&!taken?"#FCA5A5":L.border}`,display:"flex",alignItems:"center",gap:12,cursor:"pointer",transition:"all 0.22s cubic-bezier(0.34,1.56,0.64,1)",boxShadow:"0 1px 4px rgba(0,0,0,0.05)",position:"relative",overflow:"hidden"}}>
                  {taken&&fbk&&<div key={fbk} style={{position:"absolute",inset:0,background:"rgba(34,197,94,0.08)",animation:"popIn 0.35s forwards",pointerEvents:"none",borderRadius:16}}/>}
                  {/* Time badge — Cal AI style */}
                  <div style={{width:52,height:52,borderRadius:15,background:taken?"#DCFCE7":`${d.med.color}15`,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}>
                    <span style={{fontSize:24}}>{d.med.isLiquid?"🧴":"💊"}</span>
                  </div>
                  <div style={{flex:1,position:"relative",zIndex:1}}>
                    <div style={{display:"flex",alignItems:"center",gap:6,flexWrap:"wrap"}}>
                      <p style={{margin:0,fontWeight:700,fontSize:15,color:taken?"rgba(0,0,0,0.35)":L.text,textDecoration:taken?"line-through":"none",fontFamily:"'Figtree',-apple-system,sans-serif"}}>{d.med.name}</p>
                      {overdue&&!taken&&<span style={{fontSize:9,fontWeight:800,padding:"2px 7px",borderRadius:99,background:"#FEE2E2",color:"#EF4444",letterSpacing:"0.03em",textTransform:"uppercase"}}>OVERDUE</span>}
                    </div>
                    <p style={{margin:"3px 0 0",fontSize:12,color:L.sub}}>{d.med.dose}{d.sched.withFood?" · 🍽️ With food":""}{d.med.dosePerTake?" · "+d.med.dosePerTake:""}</p>
                  </div>
                  {/* Time + check — Cal AI style */}
                  <div style={{display:"flex",flexDirection:"column",alignItems:"flex-end",gap:6,flexShrink:0}}>
                    <span style={{fontSize:11,fontWeight:600,color:L.sub,background:L.fill,padding:"3px 8px",borderRadius:99}}>{timeLabel}</span>
                    <div style={{width:28,height:28,borderRadius:99,background:taken?"#111":L.fill,display:"flex",alignItems:"center",justifyContent:"center",transition:"all 0.2s cubic-bezier(0.34,1.56,0.64,1)"}}>
                      {taken&&<Ic d={ic.check} size={13} c="#fff" w={2.8}/>}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </section>
      )}
      <section style={{marginBottom:28}}>
        <p style={{fontFamily:"'Figtree',-apple-system,sans-serif",fontSize:18,fontWeight:800,color:L.text,margin:"0 0 12px",letterSpacing:"-0.3px"}}>My Medicines</p>
        {meds.length===0&&(
          <div style={{textAlign:"center",padding:"40px 20px",background:L.card,borderRadius:18,boxShadow:"0 1px 4px rgba(0,0,0,0.06)"}}>
            <span style={{fontSize:44,display:"block",marginBottom:12}}>💊</span>
            <p style={{fontWeight:800,fontSize:16,color:L.text,margin:"0 0 6px",letterSpacing:"-0.3px",fontFamily:"'Figtree',-apple-system,sans-serif"}}>No medicines yet</p>
            <p style={{color:L.sub,fontSize:13,margin:"0 0 16px",lineHeight:1.5}}>Tap the + button below to add your first medicine.</p>
          </div>
        )}
        {meds.length>0&&(
          <div style={{display:"flex",flexDirection:"column",gap:10}}>
            {meds.map(m=><MedCard key={m.id} med={m} onDetail={onDetail} onEdit={onEdit} onUpdate={onUpdate} onDelete={onDelete}/>)}
          </div>
        )}
      </section>
    </div>
  );
}

/* ── Streak Modal ── */
function StreakModal({streak,history,today,streakData,onFreeze,onClose}) {
  const L=useTheme();
  const ff="'Figtree',-apple-system,sans-serif";

  // ── Compute real stats ──────────────────────────────────────────────────────
  const allKeys=Object.keys(history).sort();
  const totalDaysTracked=allKeys.length;
  const allEntries=Object.values(history).flat();
  const totalTaken=allEntries.filter(e=>e.taken).length;
  const totalDoses=allEntries.length;
  const overallAdh=totalDoses?Math.round(totalTaken/totalDoses*100):0;

  // best streak calculation
  const bestStreak=()=>{
    let best=0,cur=0,prev=null;
    for(const k of allKeys){
      const ds=history[k]||[];
      const rate=ds.length?ds.filter(x=>x.taken).length/ds.length:0;
      if(rate>=0.8){
        // Check consecutive
        if(prev){
          const diff=(new Date(k)-new Date(prev))/(1000*60*60*24);
          cur=diff<=1?cur+1:1;
        } else { cur=1; }
        best=Math.max(best,cur);
      } else { cur=0; }
      prev=k;
    }
    return best;
  };
  const best=bestStreak();

  // 30-day grid
  const grid=Array.from({length:30},(_,i)=>{
    const d=new Date(); d.setDate(d.getDate()-(29-i));
    const k=d.toISOString().slice(0,10);
    const ds=history[k]||[];
    const isT=k===today;
    const rate=ds.length?ds.filter(x=>x.taken).length/ds.length:0;
    return{k,isT,rate,d,has:ds.length>0};
  });

  // Next milestone
  const MILESTONES=[[3,"🌱","3 Days"],[7,"⚡","1 Week"],[14,"🏅","2 Weeks"],[30,"🏆","1 Month"],[60,"💎","2 Months"],[100,"👑","100 Days"],[365,"🌟","1 Year"]];
  const nextM=MILESTONES.find(([n])=>streak<n);
  const prevM=[...MILESTONES].reverse().find(([n])=>streak>=n);
  const nextDays=nextM?nextM[0]-streak:0;
  const progressToNext=nextM?(prevM?(streak-prevM[0])/(nextM[0]-prevM[0]):streak/nextM[0]):1;

  return(
    <div style={{position:"fixed",inset:0,background:"rgba(0,0,0,0.5)",zIndex:500,display:"flex",alignItems:"flex-end",justifyContent:"center",backdropFilter:"blur(12px)",WebkitBackdropFilter:"blur(12px)"}} onClick={onClose}>
      <div style={{background:L.card,borderRadius:"24px 24px 0 0",width:"100%",maxWidth:430,maxHeight:"90vh",overflowY:"auto",animation:"iosSlideUp 0.38s cubic-bezier(0.32,0.72,0,1) forwards"}} onClick={e=>e.stopPropagation()}>
        {/* Handle */}
        <div style={{display:"flex",justifyContent:"center",paddingTop:12,paddingBottom:0}}>
          <div style={{width:36,height:4,borderRadius:99,background:L.border}}/>
        </div>
        {/* Header */}
        <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",padding:"16px 20px 0"}}>
          <p style={{margin:0,fontWeight:800,fontSize:22,color:L.text,fontFamily:ff,letterSpacing:"-0.5px"}}>Streak <span className="flame-icon" style={{display:"inline-block"}}>🔥</span></p>
          <button onClick={onClose} style={{width:32,height:32,borderRadius:99,background:L.fill,border:"none",cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center"}}><Ic d={ic.x} size={14} c={L.sub}/></button>
        </div>

        <div style={{padding:"16px 20px 40px"}}>
          {/* Big streak number — Cal AI hero stat style */}
          <div style={{background:"#111",borderRadius:20,padding:"20px 24px",marginBottom:16,display:"flex",alignItems:"center",gap:16}}>
            <div>
              <p style={{margin:0,fontWeight:900,fontSize:56,color:"#fff",fontFamily:ff,letterSpacing:"-3px",lineHeight:1}}>{streak}</p>
              <p style={{margin:"4px 0 0",fontSize:13,fontWeight:600,color:"rgba(255,255,255,0.55)"}}>day{streak!==1?"s":""} in a row</p>
            </div>
            <div style={{flex:1}}/>
            <div style={{textAlign:"right"}}>
              <div style={{display:"flex",flexDirection:"column",gap:8}}>
                <div>
                  <p style={{margin:0,fontWeight:800,fontSize:20,color:"#fff",fontFamily:ff,letterSpacing:"-0.5px"}}>{best}</p>
                  <p style={{margin:0,fontSize:10,color:"rgba(255,255,255,0.45)",fontWeight:600,textTransform:"uppercase",letterSpacing:"0.06em"}}>Best</p>
                </div>
                <div>
                  <p style={{margin:0,fontWeight:800,fontSize:20,color:"#fff",fontFamily:ff,letterSpacing:"-0.5px"}}>{overallAdh}%</p>
                  <p style={{margin:0,fontSize:10,color:"rgba(255,255,255,0.45)",fontWeight:600,textTransform:"uppercase",letterSpacing:"0.06em"}}>Adherence</p>
                </div>
              </div>
            </div>
          </div>

          {/* Stats row — Cal AI mini cards */}
          <div style={{display:"grid",gridTemplateColumns:"1fr 1fr 1fr",gap:8,marginBottom:16}}>
            {[
              {label:"Days Tracked",val:totalDaysTracked,emoji:"📅"},
              {label:"Doses Taken",val:totalTaken,emoji:"✅"},
              {label:"Total Logged",val:totalDoses,emoji:"💊"},
            ].map((s,i)=>(
              <div key={i} style={{background:L.fill,borderRadius:14,padding:"12px 10px",textAlign:"center"}}>
                <span style={{fontSize:18,display:"block",marginBottom:4}}>{s.emoji}</span>
                <p style={{margin:0,fontWeight:800,fontSize:18,color:L.text,fontFamily:ff,letterSpacing:"-0.5px"}}>{s.val}</p>
                <p style={{margin:"2px 0 0",fontSize:10,color:L.sub,fontWeight:600}}>{s.label}</p>
              </div>
            ))}
          </div>

          {/* Next milestone progress */}
          {nextM&&(
            <div style={{background:L.fill,borderRadius:16,padding:"14px 16px",marginBottom:16}}>
              <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",marginBottom:10}}>
                <div style={{display:"flex",alignItems:"center",gap:8}}>
                  <span style={{fontSize:22}}>{nextM[1]}</span>
                  <div>
                    <p style={{margin:0,fontWeight:700,fontSize:14,color:L.text,fontFamily:ff}}>{nextM[2]}</p>
                    <p style={{margin:0,fontSize:11,color:L.sub}}>{nextDays} day{nextDays!==1?"s":""} to go</p>
                  </div>
                </div>
                <span style={{fontSize:13,fontWeight:800,color:"#111",fontFamily:ff,background:L.greenLight,padding:"4px 10px",borderRadius:99,color:L.green}}>{streak}/{nextM[0]}</span>
              </div>
              <div style={{height:6,background:L.border,borderRadius:99,overflow:"hidden"}}>
                <div style={{height:"100%",width:`${progressToNext*100}%`,background:"#111",borderRadius:99,transition:"width 0.6s cubic-bezier(0.34,1.56,0.64,1)"}}/>
              </div>
            </div>
          )}

          {/* 30-day heatmap */}
          <p style={{margin:"0 0 10px",fontSize:11,fontWeight:700,letterSpacing:"0.08em",textTransform:"uppercase",color:L.sub,fontFamily:ff}}>Last 30 Days</p>
          <div style={{display:"grid",gridTemplateColumns:"repeat(10,1fr)",gap:4,marginBottom:16}}>
            {grid.map(({k,isT,rate,has,d})=>{
              const bg=isT?"#111":rate>=0.8?L.green:rate>0?L.amber:has?"#FCA5A5":L.fill;
              const label=d.getDate();
              return(
                <div key={k} title={`${d.toLocaleDateString()}: ${rate>=0.8?"✓ On track":rate>0?"Partial":"No data"}`}
                  style={{aspectRatio:"1",borderRadius:8,background:bg,display:"flex",alignItems:"center",justifyContent:"center",border:isT?"2px solid #111":"none",position:"relative"}}>
                  <span style={{fontSize:8,fontWeight:700,color:isT?"#fff":rate>0?"#fff":L.sub}}>{label}</span>
                </div>
              );
            })}
          </div>

          {/* Streak Freeze */}
          {!streakData.freezeUsedWeek&&streak>0&&(
            <div style={{background:"#EFF6FF",borderRadius:16,padding:"14px 16px",marginBottom:16,border:"1px solid #BFDBFE"}}>
              <div style={{display:"flex",alignItems:"center",gap:10}}>
                <div style={{width:40,height:40,borderRadius:12,background:"#3B82F6",display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}>
                  <span style={{fontSize:20}}>🧊</span>
                </div>
                <div style={{flex:1}}>
                  <p style={{margin:0,fontWeight:700,fontSize:14,color:"#1D4ED8",fontFamily:ff}}>Streak Freeze Available</p>
                  <p style={{margin:"2px 0 0",fontSize:12,color:"#3B82F6"}}>Protect your streak for 1 missed day · Resets Monday</p>
                </div>
                <button onClick={onFreeze}
                  style={{padding:"9px 14px",background:"#3B82F6",border:"none",borderRadius:10,fontSize:12,fontWeight:800,color:"#fff",cursor:"pointer",fontFamily:ff,flexShrink:0}}>
                  Use Freeze
                </button>
              </div>
            </div>
          )}
          {streakData.freezeUsedWeek&&(
            <div style={{background:L.fill,borderRadius:14,padding:"12px 16px",marginBottom:16,display:"flex",alignItems:"center",gap:10}}>
              <span style={{fontSize:18}}>🧊</span>
              <p style={{margin:0,fontSize:13,color:L.sub,fontFamily:ff}}>Freeze used this week · Resets next Monday</p>
            </div>
          )}

          {/* Milestones */}
          <p style={{margin:"0 0 10px",fontSize:11,fontWeight:700,letterSpacing:"0.08em",textTransform:"uppercase",color:L.sub,fontFamily:ff}}>Milestones</p>
          <div style={{display:"flex",flexDirection:"column",gap:8}}>
            {MILESTONES.map(([n,e,l])=>{
              const achieved=streak>=n;
              return(
                <div key={n} style={{display:"flex",alignItems:"center",gap:12,padding:"10px 14px",background:achieved?"#111":L.fill,borderRadius:14,transition:"all 0.2s"}}>
                  <span style={{fontSize:22,opacity:achieved?1:0.3,filter:achieved?"none":"grayscale(1)"}}>{e}</span>
                  <div style={{flex:1}}>
                    <p style={{margin:0,fontWeight:700,fontSize:14,color:achieved?"#fff":L.text,fontFamily:ff}}>{l}</p>
                    <p style={{margin:0,fontSize:11,color:achieved?"rgba(255,255,255,0.5)":L.sub}}>{achieved?"Achieved ✓":`${n-streak} days away`}</p>
                  </div>
                  {achieved&&<Ic d={ic.check} size={16} c="#fff" w={2.5}/>}
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}

/* ── Med Card ── */
function MedCard({med,onDetail,onEdit,onUpdate,onDelete}) {
  const pct=Math.max(0,Math.min(1,med.count/med.totalCount));
  const L=useTheme();
  const [confirmDelete,setConfirmDelete]=useState(false);
  const isLow=med.count<=med.refillAt;
  const unit=med.isLiquid?(med.volumeUnit||"ml"):"";
  const icon=med.isLiquid?"🧴":"💊";
  return(
    <>
    {/* Cal AI "Recently logged" style card */}
    <div style={{background:L.card,borderRadius:18,overflow:"hidden",boxShadow:"0 1px 4px rgba(0,0,0,0.06)"}}>
      <div style={{display:"flex",alignItems:"center",gap:12,padding:"14px 16px"}}>
        {med.imageUrl
          ?<div style={{width:56,height:56,borderRadius:14,overflow:"hidden",flexShrink:0}}><img src={med.imageUrl} alt={med.name} style={{width:"100%",height:"100%",objectFit:"cover"}}/></div>
          :<div style={{width:56,height:56,borderRadius:14,background:`${med.color}18`,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}><span style={{fontSize:26}}>{icon}</span></div>
        }
        <div style={{flex:1,minWidth:0}}>
          <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",gap:8,marginBottom:2}}>
            <p style={{margin:0,fontWeight:800,fontSize:15,color:L.text,fontFamily:"'Figtree',-apple-system,sans-serif",letterSpacing:"-0.2px",overflow:"hidden",textOverflow:"ellipsis",whiteSpace:"nowrap",flex:1}}>{med.name}</p>
            <span style={{fontSize:11,fontWeight:600,color:L.sub,background:L.fill,padding:"3px 8px",borderRadius:99,flexShrink:0}}>{new Date().toLocaleTimeString("en-US",{hour:"numeric",minute:"2-digit"})}</span>
          </div>
          {/* Cal AI macro row */}
          <div style={{display:"flex",alignItems:"center",gap:10,marginTop:4}}>
            <span style={{fontSize:13,fontWeight:700,color:L.amber}}>💊 {med.count}{unit}</span>
            {med.dose&&<span style={{fontSize:11,color:L.sub,fontWeight:500}}>{med.dose}</span>}
            {med.category&&<span style={{fontSize:11,color:L.sub}}>· {med.category}</span>}
          </div>
          {/* Pill progress bar */}
          <div style={{display:"flex",alignItems:"center",gap:8,marginTop:8}}>
            <div style={{flex:1,height:4,background:L.border,borderRadius:99,overflow:"hidden"}}>
              <div style={{width:`${pct*100}%`,height:"100%",background:isLow?L.red:L.green,borderRadius:99,transition:"width 0.4s"}}/>
            </div>
            <span style={{fontSize:10,fontWeight:700,color:isLow?L.red:L.sub,minWidth:50,textAlign:"right"}}>{med.count}/{med.totalCount}{unit}</span>
          </div>
        </div>
      </div>
      {/* Cal AI action row */}
      <div style={{display:"flex",borderTop:`1px solid ${L.border}`,padding:"0 16px"}}>
        <button onClick={()=>onDetail(med)} style={{flex:1,padding:"10px 0",background:"transparent",border:"none",fontSize:13,fontWeight:700,color:L.text,cursor:"pointer",fontFamily:"'Figtree',-apple-system,sans-serif",textAlign:"center"}}>Details</button>
        <div style={{width:1,background:L.border,margin:"6px 0"}}/>
        <button onClick={()=>onEdit(med)} style={{flex:1,padding:"10px 0",background:"transparent",border:"none",fontSize:13,fontWeight:700,color:L.text,cursor:"pointer",fontFamily:"'Figtree',-apple-system,sans-serif",textAlign:"center"}}>Edit</button>
        <div style={{width:1,background:L.border,margin:"6px 0"}}/>
        <div style={{flex:1,display:"flex",alignItems:"center",justifyContent:"center",gap:4}}>
          <button onClick={e=>{e.stopPropagation();onUpdate(med.id,{count:Math.max(0,med.count-1)});}} style={{width:26,height:26,borderRadius:99,background:L.fill,border:"none",cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center"}}><Ic d={ic.minus} size={12} c={L.text}/></button>
          <span style={{fontSize:13,fontWeight:800,color:L.text,minWidth:24,textAlign:"center",fontVariantNumeric:"tabular-nums",fontFamily:"'Figtree',-apple-system,sans-serif"}}>{med.count}</span>
          <button onClick={e=>{e.stopPropagation();onUpdate(med.id,{count:med.count+1});}} style={{width:26,height:26,borderRadius:99,background:"#111",border:"none",cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center"}}><Ic d={ic.plus} size={12} c="#fff"/></button>
        </div>
      </div>
    </div>
    {confirmDelete&&(
      <ActionSheet
        title={"Remove \""+med.name+"\""}
        sub="This will permanently delete this medicine and all its schedules."
        actions={[{label:"Delete Medicine",destructive:true,action:()=>{onDelete(med);setConfirmDelete(false);}}]}
        onCancel={()=>setConfirmDelete(false)}
      />
    )}
    </>
  );
}

/* ── Manual Medicine Entry Form ── */
function ManualAddForm({onSave,onCancel}) {
  const [form,setForm]=useState({name:"",brand:"",dose:"",form:"tablet",category:"",count:"30",totalCount:"30",refillAt:"7",notes:""});
  const L=useTheme();
  const [errors,setErrors]=useState({});
  function validate(){const e={};if(!form.name.trim())e.name="Medicine name is required";if(!form.count||isNaN(form.count)||parseInt(form.count)<1)e.count="Enter a valid count";return e;}
  function handleSave(){const e=validate();if(Object.keys(e).length){setErrors(e);return;}onSave({identified:true,name:form.name.trim(),brand:form.brand,dose:form.dose,form:form.form,category:form.category,description:form.notes,pillCount:parseInt(form.count)||30,packSize:parseInt(form.totalCount)||30,refillAlert:parseInt(form.refillAt)||7,isLiquid:false,confidence:"high",imageUrl:null});}
  const Field=({label,fk,placeholder,type="text",required})=>(
    <div>
      <p style={{margin:"0 0 5px",fontSize:12,fontWeight:400,color:"rgba(60,60,67,0.6)",textTransform:"uppercase",letterSpacing:"0.04em"}}>{label}{required&&" *"}</p>
      <input value={form[fk]} onChange={e=>{setForm(p=>({...p,[fk]:e.target.value}));if(errors[fk])setErrors(p=>{const n={...p};delete n[fk];return n;});}}
        placeholder={placeholder} type={type}
        style={{width:"100%",padding:"13px 14px",background:L.card,border:`1px solid ${errors[fk]?"#FF3B30":"rgba(60,60,67,0.15)"}`,borderRadius:12,fontSize:16,color:L.text,outline:"none",fontFamily:"'Figtree',-apple-system,sans-serif",boxSizing:"border-box"}}/>
      {errors[fk]&&<p style={{margin:"4px 0 0",fontSize:12,color:"#FF3B30"}}>{errors[fk]}</p>}
    </div>
  );
  return(
    <div style={{paddingBottom:20}}>
      <div style={{display:"flex",alignItems:"center",gap:12,marginBottom:20}}>
        <button onClick={onCancel} style={{width:34,height:34,borderRadius:17,background:L.fill,border:"none",cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center"}}>
          <Ic d={ic.x} size={16} c="rgba(60,60,67,0.6)"/>
        </button>
        <h2 style={{margin:0,fontSize:20,fontWeight:700,color:L.text,letterSpacing:"-0.3px"}}>Add Medicine</h2>
      </div>
      <div style={{display:"flex",flexDirection:"column",gap:14}}>
        <Field label="Medicine Name" fk="name" placeholder="e.g. Metformin" required/>
        <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:12}}>
          <Field label="Brand (optional)" fk="brand" placeholder="e.g. Glucophage"/>
          <Field label="Dosage" fk="dose" placeholder="e.g. 500mg"/>
        </div>
        <div>
          <p style={{margin:"0 0 5px",fontSize:12,fontWeight:400,color:"rgba(60,60,67,0.6)",textTransform:"uppercase",letterSpacing:"0.04em"}}>Form</p>
          <div style={{display:"flex",gap:6,flexWrap:"wrap"}}>
            {["tablet","capsule","syrup","inhaler","drops","cream","injection","other"].map(f=>(
              <button key={f} onClick={()=>setForm(p=>({...p,form:f}))}
                style={{padding:"7px 14px",background:form.form===f?L.blue:L.fill,border:"none",borderRadius:99,fontSize:13,fontWeight:500,color:form.form===f?"#fff":"rgba(60,60,67,0.7)",cursor:"pointer",fontFamily:"'Figtree',-apple-system,sans-serif",transition:"all 0.15s",textTransform:"capitalize"}}>
                {f}
              </button>
            ))}
          </div>
        </div>
        <Field label="Category" fk="category" placeholder="e.g. Diabetes, Antibiotic"/>
        <div style={{display:"grid",gridTemplateColumns:"1fr 1fr 1fr",gap:10}}>
          <Field label="Count" fk="count" placeholder="30" type="number" required/>
          <Field label="Pack Size" fk="totalCount" placeholder="30" type="number"/>
          <Field label="Refill At" fk="refillAt" placeholder="7" type="number"/>
        </div>
        <div>
          <p style={{margin:"0 0 5px",fontSize:12,fontWeight:400,color:"rgba(60,60,67,0.6)",textTransform:"uppercase",letterSpacing:"0.04em"}}>Notes (optional)</p>
          <textarea value={form.notes} onChange={e=>setForm(p=>({...p,notes:e.target.value}))} placeholder="Instructions, side effects..."
            style={{width:"100%",padding:"13px 14px",background:L.card,border:"1px solid rgba(60,60,67,0.15)",borderRadius:12,fontSize:15,color:L.text,outline:"none",fontFamily:"'Figtree',-apple-system,sans-serif",resize:"none",minHeight:80,boxSizing:"border-box",lineHeight:1.5}}/>
        </div>
        <button onClick={handleSave} style={{width:"100%",padding:"16px",background:L.blue,border:"none",borderRadius:14,fontSize:17,fontWeight:600,color:"#fff",cursor:"pointer",fontFamily:"'Figtree',-apple-system,sans-serif",marginTop:4}}>
          Add to My Medicines
        </button>
      </div>
    </div>
  );
}

/* ══════════════════════════════════════════════
   SCAN TAB — with inline editable count + liquid support
══════════════════════════════════════════════ */
function ScanTab({state,result,camRef,galRef,onFile,onReset,onSave,setScanResult,setScanState,showToast}) {
  const [editForm,setEditForm]=useState(null);
  const L=useTheme();
  useEffect(()=>{if(state==="edit"&&result) setEditForm({...result});},[state,result]);

  const isLiq = result?.isLiquid;
  const qtyLabel = isLiq ? (result?.volumeUnit||"ml") : "pills";
  const qtyIcon  = isLiq ? "🧴" : "💊";
  const qtyTitle = isLiq ? "Volume detected" : "Pills detected";

  /* inline quantity update */
  const updateQty = (delta) => {
    if(!result) return;
    if(isLiq){
      const next=Math.max(0,(result.volumeAmount||0)+delta);
      setScanResult(p=>({...p,volumeAmount:next}));
    } else {
      const next=Math.max(0,(result.pillCount||0)+delta);
      setScanResult(p=>({...p,pillCount:next}));
    }
  };
  const qty = isLiq ? (result?.volumeAmount||0) : (result?.pillCount||0);

  return(
    <div style={{padding:"0 20px"}}>
      <div style={{paddingTop:60,paddingBottom:12}}>
        <h1 style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:28,fontWeight:700,margin:0,color:L.text,letterSpacing:"-0.5px"}}>Scan Medicine</h1>
        <p style={{color:L.sub,fontSize:13,margin:"4px 0 0"}}>AI reads name, dose & quantity from photo</p>
      </div>

      {state==="idle"&&(
        <>
          <div onClick={()=>camRef.current?.click()} style={{border:`2px dashed ${L.border}`,borderRadius:16,padding:"44px 24px",textAlign:"center",cursor:"pointer",background:L.card,marginBottom:12,boxShadow:"0 2px 12px rgba(0,0,0,0.04)"}}>
            <div style={{width:72,height:72,background:L.greenLight,borderRadius:14,display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 16px",animation:"floatUp 3s ease-in-out infinite"}}>
              <Ic d={ic.camera} size={32} c={L.green}/>
            </div>
            <p style={{fontWeight:700,fontSize:17,color:L.text,margin:"0 0 6px",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>Take a Photo</p>
            <p style={{color:L.sub,fontSize:13,margin:0}}>Works for tablets, capsules, syrups, creams & more</p>
          </div>
          <input ref={camRef} type="file" accept="image/*" capture="environment" style={{display:"none"}} onChange={e=>e.target.files[0]&&onFile(e.target.files[0])}/>
          <button onClick={()=>galRef.current?.click()} style={{width:"100%",padding:"13px",background:L.fill,border:"none",borderRadius:12,fontSize:15,fontWeight:500,color:L.text,cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center",gap:8,fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",marginBottom:20}}>
            <Ic d={ic.upload} size={15}/> Upload from Gallery
          </button>
          <input ref={galRef} type="file" accept="image/*" style={{display:"none"}} onChange={e=>e.target.files[0]&&onFile(e.target.files[0])}/>
          <div style={{display:"flex",flexDirection:"column",gap:8}}>
            {[["💊","Tablets & capsules","Shows pill count from blister pack or bottle"],["🧴","Syrups & liquids","Detects volume in ml, mg/5ml"],["💉","Inhalers & sprays","Counts doses / puffs remaining"],["✏️","Fully editable","AI pre-fills — tap to correct any detail"]].map(([e,t,d],i)=>(
              <div key={i} style={{display:"flex",alignItems:"center",gap:12,padding:"11px 14px",background:L.card,borderRadius:13}}>
                <span style={{fontSize:20,minWidth:26}}>{e}</span>
                <div><p style={{margin:0,fontSize:13,fontWeight:600,color:L.text}}>{t}</p><p style={{margin:0,fontSize:12,color:"rgba(60,60,67,0.6)"}}>{d}</p></div>
              </div>
            ))}
          </div>
          <button onClick={()=>setScanState("manual")} style={{width:"100%",marginTop:16,padding:"14px",background:L.card,border:"1px dashed rgba(60,60,67,0.2)",borderRadius:13,fontSize:15,fontWeight:500,color:"rgba(60,60,67,0.7)",cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center",gap:8,fontFamily:"'Figtree',-apple-system,sans-serif"}}>
            ✏️ Add Medicine Manually
          </button>
        </>
      )}

      {state==="manual"&&(
        <ManualAddForm onSave={r=>{onSave(r);onReset();}} onCancel={onReset}/>
      )}
      {state==="scanning"&&(
        <div style={{textAlign:"center",paddingTop:60}}>
          <div style={{position:"relative",width:100,height:100,margin:"0 auto 24px"}}>
            <div style={{width:100,height:100,background:L.greenLight,borderRadius:28,display:"flex",alignItems:"center",justifyContent:"center"}}>
              <Ic d={ic.sparkle} size={44} c={L.green}/>
            </div>
            <div style={{position:"absolute",inset:-4,border:`2px solid ${L.green}`,borderRadius:32,opacity:0.3,animation:"spin 2s linear infinite"}}/>
          </div>
          <p style={{fontWeight:700,fontSize:20,color:L.text,margin:"0 0 8px",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>Analysing...</p>
          <p style={{color:L.sub,fontSize:14,margin:"0 0 4px"}}>Identifying medicine type & measuring quantity</p>
          <p style={{color:L.sub,fontSize:12}}>Detecting pills, liquid, or puffs ✨</p>
        </div>
      )}

      {state==="result"&&result&&(
        <div>
          {result.imageUrl&&(
            <div style={{borderRadius:14,overflow:"hidden",marginBottom:14,height:180,position:"relative"}}>
              <img src={result.imageUrl} alt="Scanned" style={{width:"100%",height:"100%",objectFit:"cover"}}/>
              <div style={{position:"absolute",inset:0,background:"linear-gradient(to top,rgba(0,0,0,0.3),transparent)"}}/>
              <div style={{position:"absolute",top:10,right:10,display:"flex",gap:6}}>
                {isLiq&&<Badge bg="rgba(234,88,12,0.85)" color="#fff" sx={{backdropFilter:"blur(24px) saturate(160%)",WebkitBackdropFilter:"blur(24px) saturate(160%)"}}>Liquid 🧴</Badge>}
                <Badge bg={result.confidence==="high"?"rgba(16,185,129,0.9)":"rgba(245,158,11,0.9)"} color="#fff" sx={{backdropFilter:"blur(24px) saturate(160%)",WebkitBackdropFilter:"blur(24px) saturate(160%)"}}>
                  {result.confidence==="high"?"✓ High confidence":"~ Possible match"}
                </Badge>
              </div>
            </div>
          )}
          <div style={{background:L.card,borderRadius:14,padding:18,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)",marginBottom:12}}>
            {result.identified?(
              <div style={{display:"flex",flexDirection:"column",gap:10}}>
                <div style={{display:"flex",alignItems:"center",gap:10,paddingBottom:12,borderBottom:`1px solid ${L.border}`}}>
                  <div style={{flex:1}}>
                    <p style={{margin:"0 0 2px",fontWeight:700,fontSize:20,color:L.text,fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>{result.name}</p>
                    {result.brand&&<p style={{margin:0,fontSize:13,color:L.sub}}>{result.brand}{result.dose&&` · ${result.dose}`}</p>}
                  </div>
                  {result.form&&<Badge bg={isLiq?"#FFF7ED":L.blueLight} color={isLiq?"#C2410C":L.blue}>{result.form}</Badge>}
                </div>

                {/* ── INLINE EDITABLE QUANTITY CARD ── */}
                <div style={{background:`${L.green}08`,border:`1.5px solid ${L.green}30`,borderRadius:16,padding:"14px 16px"}}>
                  <p style={{margin:"0 0 10px",fontSize:11,fontWeight:700,color:L.green,letterSpacing:"0.07em",textTransform:"uppercase"}}>{qtyTitle} · tap to edit</p>
                  <div style={{display:"flex",alignItems:"center",gap:12}}>
                    <div style={{width:44,height:44,background:L.greenLight,borderRadius:13,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0,fontSize:22}}>{qtyIcon}</div>
                    <div style={{flex:1,display:"flex",alignItems:"center",gap:8}}>
                      <button onClick={()=>updateQty(-1)} style={{width:32,height:32,borderRadius:99,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)",background:L.bg,cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}><Ic d={ic.minus} size={14} c={L.text}/></button>
                      <input
                        type="number"
                        value={qty}
                        onChange={e=>{
                          const v=Math.max(0,parseInt(e.target.value)||0);
                          if(isLiq) setScanResult(p=>({...p,volumeAmount:v}));
                          else setScanResult(p=>({...p,pillCount:v}));
                        }}
                        style={{width:70,textAlign:"center",fontSize:26,fontWeight:700,color:L.text,fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",border:`1.5px solid ${L.border}`,borderRadius:10,padding:"4px 0",background:"#fff",outline:"none",letterSpacing:"-0.5px"}}
                      />
                      <button onClick={()=>updateQty(1)} style={{width:32,height:32,borderRadius:99,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)",background:L.bg,cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}><Ic d={ic.plus} size={14} c={L.text}/></button>
                      <span style={{fontSize:14,fontWeight:700,color:L.sub}}>{qtyLabel}</span>
                    </div>
                    <div style={{textAlign:"right",flexShrink:0}}>
                      <p style={{margin:0,fontSize:10,color:L.sub}}>Refill alert</p>
                      <div style={{display:"flex",alignItems:"center",gap:4,justifyContent:"flex-end",marginTop:2}}>
                        <button onClick={()=>setScanResult(p=>({...p,refillAlert:Math.max(1,(p.refillAlert||7)-1)}))} style={{width:20,height:20,borderRadius:99,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)",background:L.bg,cursor:"pointer",fontSize:10,display:"flex",alignItems:"center",justifyContent:"center"}}>−</button>
                        <span style={{fontSize:13,fontWeight:700,color:L.text,minWidth:18,textAlign:"center"}}>{result.refillAlert||7}</span>
                        <button onClick={()=>setScanResult(p=>({...p,refillAlert:(p.refillAlert||7)+1}))} style={{width:20,height:20,borderRadius:99,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)",background:L.bg,cursor:"pointer",fontSize:10,display:"flex",alignItems:"center",justifyContent:"center"}}>+</button>
                      </div>
                    </div>
                  </div>
                  {isLiq&&result.dosePerTake&&<p style={{margin:"10px 0 0",fontSize:12,color:L.sub}}>💧 Dose per take: <strong>{result.dosePerTake}</strong></p>}
                </div>

                <IRow label="Category" value={result.category}/>
                {result.description&&<IRow label="Treats" value={result.description}/>}
                {result.howToTake&&<IRow label="How to take" value={result.howToTake}/>}
                {result.sideEffects&&<IRow label="Side effects" value={result.sideEffects}/>}
                {result.storage&&<IRow label="Storage" value={result.storage}/>}
              </div>
            ):(
              <p style={{color:L.sub,fontSize:14,margin:0}}>{result.description||"Could not identify medicine. Please try again with a clearer photo."}</p>
            )}
          </div>
          <p style={{fontSize:11,color:L.sub,textAlign:"center",marginBottom:12}}>AI may not be 100% accurate. Tap Fix to correct any detail.</p>
          <div style={{display:"flex",gap:8}}>
            <button onClick={onReset} style={{flex:1,padding:"13px",background:L.fill,border:"none",borderRadius:12,fontSize:15,fontWeight:500,color:L.text,cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>Retake</button>
            <button onClick={()=>setScanState("edit")} style={{flex:1,padding:"13px",background:"#EDE9FE",border:"none",borderRadius:14,fontSize:13,fontWeight:700,color:L.purple,cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",display:"flex",alignItems:"center",justifyContent:"center",gap:6}}>
              <Ic d={ic.edit} size={13}/> Fix
            </button>
            {result.identified&&<button onClick={()=>{onSave(result);if(showToast)showToast((result.name||"Medicine")+" added ✓","success");}} style={{flex:1.4,padding:"13px",background:L.green,border:"none",borderRadius:14,fontSize:13,fontWeight:700,color:"#fff",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>Add →</button>}
          </div>
        </div>
      )}

      {state==="edit"&&editForm&&(
        <div>
          <p style={{color:L.sub,fontSize:13,margin:"0 0 16px"}}>Pre-filled from scan — correct anything below</p>
          <div style={{display:"flex",flexDirection:"column",gap:12}}>
            {[{k:"name",l:"Medicine Name"},{k:"brand",l:"Brand"},{k:"dose",l:"Dosage"},{k:"form",l:"Form"},{k:"category",l:"Category"},{k:"description",l:"Description"}].map(f=>(
              <LightInp key={f.k} label={f.l} value={editForm[f.k]||""} placeholder={f.l} onChange={e=>setEditForm(p=>({...p,[f.k]:e.target.value}))}/>
            ))}
            <div style={{display:"grid",gridTemplateColumns:"1fr 1fr 1fr",gap:8}}>
              {editForm.isLiquid?(
                <>
                  <LightInp label="Volume (ml)" type="number" value={editForm.volumeAmount||0} onChange={e=>setEditForm(p=>({...p,volumeAmount:parseInt(e.target.value)||0}))}/>
                  <LightInp label="Unit" value={editForm.volumeUnit||"ml"} onChange={e=>setEditForm(p=>({...p,volumeUnit:e.target.value}))}/>
                  <LightInp label="Per dose" value={editForm.dosePerTake||""} placeholder="5ml" onChange={e=>setEditForm(p=>({...p,dosePerTake:e.target.value}))}/>
                </>
              ):(
                <>
                  <LightInp label="Pill Count" type="number" value={editForm.pillCount||30} onChange={e=>setEditForm(p=>({...p,pillCount:parseInt(e.target.value)||30}))}/>
                  <LightInp label="Pack Size" type="number" value={editForm.packSize||30} onChange={e=>setEditForm(p=>({...p,packSize:parseInt(e.target.value)||30}))}/>
                  <LightInp label="Refill At" type="number" value={editForm.refillAlert||7} onChange={e=>setEditForm(p=>({...p,refillAlert:parseInt(e.target.value)||7}))}/>
                </>
              )}
            </div>
          </div>
          <div style={{display:"flex",gap:8,marginTop:20}}>
            <button onClick={()=>setScanState("result")} style={{flex:1,padding:"13px",background:L.fill,border:"none",borderRadius:12,fontSize:15,fontWeight:500,color:L.text,cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>Back</button>
            <button onClick={()=>{setScanResult({...editForm,identified:true});setScanState("result");}} style={{flex:2,padding:"13px",background:L.green,border:"none",borderRadius:14,fontSize:13,fontWeight:700,color:"#fff",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>Save Changes</button>
          </div>
        </div>
      )}
    </div>
  );
}

/* ══════════════════════════════════════════════
   HISTORY TAB
══════════════════════════════════════════════ */
function HistoryTab({meds,history,today,onRelog,showToast}) {
  const days=Object.keys(history).sort().reverse();
  const L=useTheme();
  const allDoses=Object.values(history).flat();
  const adh=allDoses.length?Math.round(allDoses.filter(d=>d.taken).length/allDoses.length*100):0;
  return(
    <div style={{padding:"0 20px"}}>
      <div style={{paddingTop:60,paddingBottom:12}}>
        <h1 style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:28,fontWeight:700,margin:0,color:L.text,letterSpacing:"-0.5px"}}>History</h1>
        <p style={{color:L.sub,fontSize:13,margin:"4px 0 0"}}>Your 14-day medicine log</p>
      </div>
      {allDoses.length>0&&<div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:10,marginBottom:18}}>
        {[{e:"📊",l:"Adherence",v:`${adh}%`,c:adh>=80?L.green:L.amber},{e:"✅",l:"Doses taken",v:allDoses.filter(d=>d.taken).length,c:L.blue},{e:"💊",l:"Medicines",v:meds.length,c:L.purple},{e:"🔥",l:"Perfect days",v:days.filter(k=>{const ds=history[k]||[];return ds.length&&ds.every(d=>d.taken);}).length,c:L.amber}].map((s,i)=>(
          <div key={i} style={{background:L.card,borderRadius:13,padding:"16px 14px",boxShadow:"0 1px 3px rgba(0,0,0,0.06)"}}>
            <span style={{fontSize:22}}>{s.e}</span>
            <p style={{margin:"8px 0 2px",fontSize:22,fontWeight:700,color:s.c,letterSpacing:"-0.5px"}}>{s.v}</p>
            <p style={{margin:0,fontSize:11,color:L.sub,fontWeight:600}}>{s.l}</p>
          </div>
        ))}
      </div>}
      <div style={{background:L.card,borderRadius:14,padding:"18px 16px",marginBottom:18,border:"0.5px solid rgba(60,60,67,0.15)"}}>
        <Lbl>Weekly Adherence</Lbl>
        <div style={{display:"flex",gap:6,alignItems:"flex-end",height:70}}>
          {days.slice(0,7).reverse().map(k=>{const ds=history[k]||[];const rate=ds.length?ds.filter(d=>d.taken).length/ds.length:0;const isT=k===today;const d=new Date(k+"T12:00:00");return(<div key={k} style={{flex:1,display:"flex",flexDirection:"column",alignItems:"center",gap:4}}><div style={{width:"100%",height:60,background:L.border,borderRadius:8,overflow:"hidden",position:"relative"}}><div style={{position:"absolute",bottom:0,width:"100%",height:`${isT?50:rate*100}%`,minHeight:rate>0||isT?5:0,background:isT?"#93C5FD":rate>=0.8?L.green:rate>0?L.amber:L.border,transition:"height 0.5s",borderRadius:8}}/></div><span style={{fontSize:9,fontWeight:700,color:isT?L.blue:L.sub}}>{DAYS7[d.getDay()][0]}</span></div>);})}
        </div>
      </div>
      {meds.length>0&&(
        <div style={{background:L.card,borderRadius:14,padding:"18px 16px",marginBottom:18,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)"}}>
          <Lbl>Course Progress</Lbl>
          {meds.map(m=>{const pct=Math.max(0,Math.min(1,m.count/m.totalCount));const taken=m.totalCount-m.count;const unit=m.isLiquid?(m.volumeUnit||"ml"):"";return(
            <div key={m.id} style={{paddingBottom:14,marginBottom:14,borderBottom:`1px solid ${L.border}`}}>
              <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:8}}>
                <div><p style={{margin:0,fontWeight:700,fontSize:14,color:L.text}}>{m.name} <span style={{fontWeight:400,fontSize:12,color:L.sub}}>{m.dose}</span></p><p style={{margin:"2px 0 0",fontSize:11,color:L.sub}}>{taken}{unit} taken · {m.count}{unit} remaining</p></div>
                <Badge bg={m.count<=m.refillAt?L.redLight:L.greenLight} color={m.count<=m.refillAt?L.red:L.green}>{m.count<=m.refillAt?"Low":"Good"}</Badge>
              </div>
              <div style={{height:8,background:L.border,borderRadius:99,overflow:"hidden"}}><div style={{width:`${(1-pct)*100}%`,height:"100%",background:m.color,borderRadius:99,transition:"width 0.4s"}}/></div>
            </div>
          );})}
        </div>
      )}
      {allDoses.length===0&&days.length===0&&(
        <div style={{textAlign:"center",padding:"60px 20px",background:L.card,borderRadius:16,marginTop:8}}>
          <span style={{fontSize:52,display:"block",marginBottom:14}}>📋</span>
          <p style={{fontWeight:700,fontSize:17,color:L.text,margin:"0 0 6px"}}>No history yet</p>
          <p style={{color:L.sub,fontSize:14,margin:0,lineHeight:1.5}}>Your dose history will appear here as you log medicines.</p>
        </div>
      )}
      {days.slice(0,14).map(k=>{
        const ds=history[k]||[];const d=new Date(k+"T12:00:00");const isT=k===today;const rate=ds.length?ds.filter(x=>x.taken).length/ds.length:null;
        return(
          <div key={k} style={{marginBottom:16}}>
            <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",marginBottom:8}}>
              <span style={{fontWeight:700,fontSize:14,color:isT?L.blue:L.text}}>{isT?"Today":d.toLocaleDateString("en-US",{weekday:"short",month:"short",day:"numeric"})}</span>
              {rate!==null&&<Badge bg={rate>=0.8?L.greenLight:rate>0?"#FEF3C7":L.redLight} color={rate>=0.8?L.green:rate>0?L.amber:L.red}>{Math.round(rate*100)}%</Badge>}
            </div>
            {isT&&ds.length===0?<p style={{color:L.sub,fontSize:13}}>Log appears as you take doses today.</p>:ds.length===0?<p style={{color:L.sub,fontSize:13}}>No doses logged</p>:(
              ds.map((entry,i)=>{const med=meds.find(m=>m.id===entry.medId);return(
                <div key={i} style={{background:L.card,borderRadius:14,padding:"11px 14px",marginBottom:6,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)",display:"flex",alignItems:"center",gap:10}}>
                  <div style={{width:8,height:8,borderRadius:99,flexShrink:0,background:entry.taken?L.green:L.red}}/>
                  <div style={{flex:1}}><p style={{margin:0,fontSize:13,fontWeight:600,color:L.text}}>{med?`${med.name} ${med.dose}`:"Unknown"}</p><p style={{margin:"1px 0 0",fontSize:11,color:L.sub}}>{entry.label} · {entry.time} · {entry.taken?"✓ Taken":"✗ Missed"}</p></div>
                  {!entry.taken&&<button onClick={()=>onRelog(entry)} style={{display:"flex",alignItems:"center",gap:4,background:L.greenLight,border:"none",borderRadius:99,padding:"5px 10px",fontSize:11,fontWeight:700,color:L.green,cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}><Ic d={ic.redo} size={11}/> Log</button>}
                </div>
              );})
            )}
          </div>
        );
      })}
    </div>
  );
}

/* ══════════════════════════════════════════════
   ALARMS TAB — Cal AI Design Language
══════════════════════════════════════════════ */
function AlarmTimeInput({value, onChange, label}) {
  const L=useTheme();
  return(
    <div style={{display:"flex",flexDirection:"column",gap:4,flex:1}}>
      <p style={{margin:0,fontSize:10,fontWeight:700,letterSpacing:"0.08em",textTransform:"uppercase",color:L.sub}}>{label}</p>
      <input
        type="number"
        value={value}
        onChange={onChange}
        style={{background:L.fill,border:"none",borderRadius:12,padding:"14px 12px",fontSize:20,fontWeight:800,color:L.text,fontFamily:"'Figtree',-apple-system,sans-serif",textAlign:"center",outline:"none",width:"100%"}}
      />
    </div>
  );
}

const QUICK_TIMES=[
  {label:"Morning",h:8,m:0,emoji:"🌅"},
  {label:"Afternoon",h:13,m:0,emoji:"☀️"},
  {label:"Evening",h:18,m:0,emoji:"🌆"},
  {label:"Night",h:21,m:0,emoji:"🌙"},
];

function AddAlarmSheet({med,onAdd,onClose}) {
  const L=useTheme();
  const [ns,setNs]=useState({h:8,m:0,label:"Morning",days:[1,2,3,4,5,6,0],withFood:false});
  const ff="'Figtree',-apple-system,sans-serif";
  return(
    <div style={{position:"fixed",inset:0,zIndex:300,display:"flex",flexDirection:"column",justifyContent:"flex-end"}} onClick={onClose}>
      <div style={{background:"rgba(0,0,0,0.4)",position:"absolute",inset:0}}/>
      <div onClick={e=>e.stopPropagation()} className="ios-sheet" style={{background:L.card,borderRadius:"24px 24px 0 0",padding:"0 0 40px",position:"relative",zIndex:1,maxHeight:"90vh",overflowY:"auto"}}>
        {/* Handle */}
        <div style={{display:"flex",justifyContent:"center",paddingTop:12,paddingBottom:4}}>
          <div style={{width:36,height:4,borderRadius:99,background:L.border}}/>
        </div>
        {/* Header */}
        <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",padding:"12px 20px 16px"}}>
          <div>
            <p style={{margin:0,fontWeight:800,fontSize:20,color:L.text,fontFamily:ff,letterSpacing:"-0.4px"}}>Add Reminder</p>
            <div style={{display:"flex",alignItems:"center",gap:6,marginTop:4}}>
              <div style={{width:8,height:8,borderRadius:99,background:med.color}}/>
              <p style={{margin:0,fontSize:13,color:L.sub,fontFamily:ff}}>{med.name}</p>
            </div>
          </div>
          <button onClick={onClose} style={{width:32,height:32,borderRadius:99,background:L.fill,border:"none",cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center"}}>
            <Ic d={ic.x} size={14} c={L.sub}/>
          </button>
        </div>

        <div style={{padding:"0 20px"}}>
          {/* Quick time presets — Cal AI style pill row */}
          <p style={{margin:"0 0 10px",fontSize:11,fontWeight:700,letterSpacing:"0.08em",textTransform:"uppercase",color:L.sub,fontFamily:ff}}>Quick Select</p>
          <div style={{display:"flex",gap:8,marginBottom:20,overflowX:"auto",paddingBottom:2}}>
            {QUICK_TIMES.map(qt=>{
              const active=ns.h===qt.h&&ns.m===qt.m&&ns.label===qt.label;
              return(
                <button key={qt.label} onClick={()=>setNs(p=>({...p,h:qt.h,m:qt.m,label:qt.label}))}
                  style={{flexShrink:0,padding:"8px 16px",borderRadius:99,background:active?"#111":L.fill,border:"none",cursor:"pointer",display:"flex",alignItems:"center",gap:6,fontFamily:ff,transition:"all 0.15s"}}>
                  <span style={{fontSize:14}}>{qt.emoji}</span>
                  <span style={{fontSize:13,fontWeight:700,color:active?"#fff":L.text}}>{qt.label}</span>
                </button>
              );
            })}
          </div>

          {/* Time pickers */}
          <p style={{margin:"0 0 10px",fontSize:11,fontWeight:700,letterSpacing:"0.08em",textTransform:"uppercase",color:L.sub,fontFamily:ff}}>Time</p>
          <div style={{display:"flex",alignItems:"center",gap:8,marginBottom:20}}>
            <AlarmTimeInput label="Hour" value={String(ns.h).padStart(2,"0")} onChange={e=>setNs(p=>({...p,h:Math.min(23,Math.max(0,parseInt(e.target.value)||0))}))}/>
            <span style={{fontSize:28,fontWeight:800,color:L.sub,marginTop:8}}>:</span>
            <AlarmTimeInput label="Min" value={String(ns.m).padStart(2,"0")} onChange={e=>setNs(p=>({...p,m:Math.min(59,Math.max(0,parseInt(e.target.value)||0))}))}/>
            <div style={{flex:1,display:"flex",flexDirection:"column",gap:4}}>
              <p style={{margin:0,fontSize:10,fontWeight:700,letterSpacing:"0.08em",textTransform:"uppercase",color:L.sub}}>Label</p>
              <input value={ns.label} onChange={e=>setNs(p=>({...p,label:e.target.value}))} placeholder="Label"
                style={{background:L.fill,border:"none",borderRadius:12,padding:"14px 12px",fontSize:14,fontWeight:700,color:L.text,fontFamily:ff,outline:"none",width:"100%"}}/>
            </div>
          </div>

          {/* Day picker — Cal AI week strip style */}
          <p style={{margin:"0 0 10px",fontSize:11,fontWeight:700,letterSpacing:"0.08em",textTransform:"uppercase",color:L.sub,fontFamily:ff}}>Repeat</p>
          <div style={{display:"flex",gap:6,marginBottom:20}}>
            {DAYS7_SHORT.map((d,i)=>{
              const sel=ns.days.includes(i);
              return(
                <button key={i} onClick={()=>setNs(p=>({...p,days:p.days.includes(i)?p.days.filter(x=>x!==i):[...p.days,i]}))}
                  style={{flex:1,aspectRatio:"1",borderRadius:"50%",border:`2px solid ${sel?"#111":L.border}`,background:sel?"#111":"transparent",cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center",fontFamily:ff,fontSize:11,fontWeight:700,color:sel?"#fff":L.sub,transition:"all 0.15s"}}>
                  {d}
                </button>
              );
            })}
          </div>

          {/* With food toggle */}
          <div onClick={()=>setNs(p=>({...p,withFood:!p.withFood}))}
            style={{display:"flex",alignItems:"center",gap:12,background:L.fill,borderRadius:14,padding:"14px 16px",marginBottom:24,cursor:"pointer"}}>
            <span style={{fontSize:20}}>🍽️</span>
            <span style={{flex:1,fontSize:14,fontWeight:600,color:L.text,fontFamily:ff}}>Take with food</span>
            {/* Cal AI style toggle — black when on */}
            <div style={{width:44,height:26,borderRadius:99,background:ns.withFood?"#111":"rgba(120,120,128,0.3)",position:"relative",transition:"background 0.2s",flexShrink:0}}>
              <div style={{position:"absolute",top:3,left:ns.withFood?"auto":3,right:ns.withFood?3:"auto",width:20,height:20,borderRadius:99,background:"#fff",transition:"all 0.22s cubic-bezier(0.34,1.56,0.64,1)",boxShadow:"0 1px 4px rgba(0,0,0,0.25)"}}/>
            </div>
          </div>

          {/* Preview */}
          <div style={{background:L.fill,borderRadius:16,padding:"14px 16px",marginBottom:20,display:"flex",alignItems:"center",gap:12}}>
            <div style={{width:40,height:40,borderRadius:12,background:"#111",display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}>
              <Ic d={ic.bell} size={18} c="#fff" w={1.8}/>
            </div>
            <div style={{flex:1}}>
              <p style={{margin:0,fontWeight:800,fontSize:17,color:L.text,fontFamily:ff,letterSpacing:"-0.3px"}}>{fmt(ns.h,ns.m)}</p>
              <p style={{margin:"2px 0 0",fontSize:12,color:L.sub,fontFamily:ff}}>{ns.label} · {ns.days.length===7?"Every day":ns.days.length===0?"No days":ns.days.map(i=>DAYS7[i]).join(", ")}{ns.withFood?" · 🍽️ With food":""}</p>
            </div>
          </div>

          {/* CTA */}
          <button onClick={()=>onAdd(ns)}
            style={{width:"100%",padding:"16px",background:"#111",border:"none",borderRadius:16,fontSize:16,fontWeight:800,color:"#fff",cursor:"pointer",fontFamily:ff,letterSpacing:"-0.2px",display:"flex",alignItems:"center",justifyContent:"center",gap:8}}>
            <Ic d={ic.bell} size={16} c="#fff" w={2.5}/> Set Reminder
          </button>
        </div>
      </div>
    </div>
  );
}

function AlarmsTab({meds,onUpdate,showToast,setTab}) {
  const [adding,setAdding]=useState(null);
  const L=useTheme();
  const ff="'Figtree',-apple-system,sans-serif";
  function addSched(medId,ns){
    const med=meds.find(m=>m.id===medId);
    if(!med)return;
    onUpdate(medId,{schedule:[...med.schedule,{time:{h:ns.h,m:ns.m},label:ns.label,days:ns.days,withFood:ns.withFood,enabled:true}]});
    setAdding(null);
    if(showToast)showToast("⏰ Reminder set for "+fmt(ns.h,ns.m));
  }
  function toggleSched(medId,idx){
    const med=meds.find(m=>m.id===medId);
    const s=med.schedule[idx];
    onUpdate(medId,{schedule:med.schedule.map((sch,i)=>i===idx?{...sch,enabled:!sch.enabled}:sch)});
    if(showToast)showToast(s.enabled?"Reminder paused":"Reminder resumed");
  }
  function removeSched(medId,idx){
    const med=meds.find(m=>m.id===medId);
    onUpdate(medId,{schedule:med.schedule.filter((_,i)=>i!==idx)});
    if(showToast)showToast("Reminder removed");
  }
  const total=meds.reduce((a,m)=>a+m.schedule.filter(s=>s.enabled).length,0);
  const allAlarms=meds.flatMap(m=>m.schedule.map((s,idx)=>({...s,med:m,idx}))).filter(s=>s.enabled).sort((a,b)=>(a.time?.h||a.h)*60+(a.time?.m||a.m)-((b.time?.h||b.h)*60+(b.time?.m||b.m)));

  return(
    <div style={{padding:"0 20px",paddingBottom:20}}>
      {/* Cal AI style header */}
      <div style={{paddingTop:54,paddingBottom:16}}>
        <div style={{display:"flex",justifyContent:"space-between",alignItems:"flex-start"}}>
          <div>
            <p style={{margin:0,fontFamily:ff,fontSize:28,fontWeight:800,color:L.text,letterSpacing:"-0.8px"}}>Reminders</p>
            <p style={{margin:"4px 0 0",fontSize:13,color:L.sub,fontWeight:500}}>
              {total>0?`${total} active reminder${total!==1?"s":""}`:meds.length>0?"No reminders set yet":"Add medicines to set reminders"}
            </p>
          </div>
          {/* summary pill */}
          {total>0&&(
            <div style={{display:"flex",alignItems:"center",gap:5,background:"#111",padding:"7px 12px",borderRadius:99}}>
              <Ic d={ic.bell} size={13} c="#fff" w={2}/>
              <span style={{fontWeight:800,fontSize:13,color:"#fff",fontFamily:ff}}>{total}</span>
            </div>
          )}
        </div>
      </div>

      {/* Empty state */}
      {meds.length===0?(
        <div className="ios-spring" style={{background:L.card,borderRadius:24,padding:"40px 24px",textAlign:"center",boxShadow:"0 1px 4px rgba(0,0,0,0.06)"}}>
          <div style={{width:72,height:72,borderRadius:22,background:"#111",display:"flex",alignItems:"center",justifyContent:"center",margin:"0 auto 16px"}}>
            <Ic d={ic.bell} size={32} c="#fff" w={1.8}/>
          </div>
          <p style={{fontWeight:800,fontSize:20,color:L.text,margin:"0 0 8px",fontFamily:ff,letterSpacing:"-0.5px"}}>No reminders yet</p>
          <p style={{color:L.sub,fontSize:14,margin:"0 0 24px",lineHeight:1.6}}>Scan a medicine first, then come back to set your daily reminders.</p>
          <button onClick={()=>setTab&&setTab("scan")}
            style={{padding:"14px 28px",background:"#111",border:"none",borderRadius:14,fontSize:15,fontWeight:800,color:"#fff",cursor:"pointer",fontFamily:ff,letterSpacing:"-0.2px"}}>
            Scan a Medicine
          </button>
        </div>
      ):(
        <>
          {/* Upcoming alarms — timeline view (if any) */}
          {allAlarms.length>0&&(
            <div style={{marginBottom:24}}>
              <p style={{fontFamily:ff,fontSize:18,fontWeight:800,color:L.text,margin:"0 0 12px",letterSpacing:"-0.3px"}}>Today's Schedule</p>
              <div style={{display:"flex",flexDirection:"column",gap:8}}>
                {allAlarms.map((s,i)=>(
                  <div key={i} style={{background:L.card,borderRadius:18,padding:"14px 16px",display:"flex",alignItems:"center",gap:14,boxShadow:"0 1px 4px rgba(0,0,0,0.05)",border:`1px solid ${L.border}`}}>
                    {/* Colored icon */}
                    <div style={{width:44,height:44,borderRadius:14,background:`${s.med.color}18`,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}>
                      <Ic d={ic.bell} size={18} c={s.med.color} w={1.8}/>
                    </div>
                    <div style={{flex:1,minWidth:0}}>
                      <div style={{display:"flex",alignItems:"baseline",gap:8}}>
                        <span style={{fontSize:20,fontWeight:800,color:L.text,letterSpacing:"-0.5px",fontFamily:ff}}>{fmt(s.time?.h??s.h,s.time?.m??s.m)}</span>
                        <span style={{fontSize:12,fontWeight:600,color:L.sub}}>{s.label}</span>
                      </div>
                      <div style={{display:"flex",alignItems:"center",gap:6,marginTop:3}}>
                        <div style={{width:6,height:6,borderRadius:99,background:s.med.color,flexShrink:0}}/>
                        <span style={{fontSize:12,color:L.sub,fontWeight:500,overflow:"hidden",textOverflow:"ellipsis",whiteSpace:"nowrap"}}>{s.med.name}</span>
                        {s.withFood&&<span style={{fontSize:10,color:L.sub}}>· 🍽️</span>}
                      </div>
                      {/* Days strip */}
                      <div style={{display:"flex",gap:3,marginTop:6}}>
                        {DAYS7_SHORT.map((d,di)=>(
                          <span key={di} style={{width:20,height:20,borderRadius:"50%",fontSize:8,fontWeight:700,display:"flex",alignItems:"center",justifyContent:"center",background:s.days.includes(di)?"#111":"transparent",color:s.days.includes(di)?"#fff":L.sub,border:`1.5px solid ${s.days.includes(di)?"#111":L.border}`}}>{d}</span>
                        ))}
                      </div>
                    </div>
                    {/* Cal AI black toggle */}
                    <div onClick={()=>toggleSched(s.med.id,s.idx)} style={{width:44,height:26,borderRadius:99,background:s.enabled?"#111":"rgba(120,120,128,0.3)",position:"relative",cursor:"pointer",transition:"background 0.2s",flexShrink:0}}>
                      <div style={{position:"absolute",top:3,left:s.enabled?"auto":3,right:s.enabled?3:"auto",width:20,height:20,borderRadius:99,background:"#fff",transition:"all 0.22s cubic-bezier(0.34,1.56,0.64,1)",boxShadow:"0 1px 4px rgba(0,0,0,0.25)"}}/>
                    </div>
                    <button onClick={()=>removeSched(s.med.id,s.idx)} style={{background:"none",border:"none",cursor:"pointer",padding:4,color:L.sub}}>
                      <Ic d={ic.x} size={15} c={L.sub}/>
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Per-medicine "Add Reminder" cards */}
          <p style={{fontFamily:ff,fontSize:18,fontWeight:800,color:L.text,margin:"0 0 12px",letterSpacing:"-0.3px"}}>Medicines</p>
          <div style={{display:"flex",flexDirection:"column",gap:10}}>
            {meds.map(med=>{
              const count=med.schedule.filter(s=>s.enabled).length;
              return(
                <div key={med.id} style={{background:L.card,borderRadius:18,padding:"14px 16px",boxShadow:"0 1px 4px rgba(0,0,0,0.05)",border:`1px solid ${L.border}`}}>
                  <div style={{display:"flex",alignItems:"center",gap:12}}>
                    {/* Med icon */}
                    <div style={{width:44,height:44,borderRadius:14,background:`${med.color}18`,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}>
                      <span style={{fontSize:20}}>{med.isLiquid?"🧴":"💊"}</span>
                    </div>
                    <div style={{flex:1,minWidth:0}}>
                      <p style={{margin:0,fontWeight:800,fontSize:15,color:L.text,fontFamily:ff,overflow:"hidden",textOverflow:"ellipsis",whiteSpace:"nowrap"}}>{med.name}</p>
                      <p style={{margin:"2px 0 0",fontSize:12,color:L.sub}}>{med.dose}{count>0?` · ${count} reminder${count!==1?"s":""}`:" · No reminders"}</p>
                    </div>
                    <button onClick={()=>setAdding(med.id)}
                      style={{width:32,height:32,borderRadius:99,background:"#111",border:"none",cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}>
                      <Ic d={ic.plus} size={14} c="#fff" w={2.5}/>
                    </button>
                  </div>
                  {/* Existing alarms for this med */}
                  {med.schedule.length>0&&(
                    <div style={{marginTop:12,display:"flex",flexDirection:"column",gap:6}}>
                      {med.schedule.map((s,idx)=>(
                        <div key={idx} style={{display:"flex",alignItems:"center",gap:10,padding:"10px 12px",background:L.fill,borderRadius:12,opacity:s.enabled?1:0.5}}>
                          <span style={{fontSize:15,fontWeight:800,color:L.text,fontFamily:ff,letterSpacing:"-0.3px",minWidth:70}}>{fmt(s.time?.h??s.h,s.time?.m??s.m)}</span>
                          <span style={{fontSize:11,fontWeight:600,color:L.sub,flex:1}}>{s.label}{s.withFood?" · 🍽️":""}</span>
                          <div onClick={()=>toggleSched(med.id,idx)} style={{width:38,height:22,borderRadius:99,background:s.enabled?"#111":"rgba(120,120,128,0.3)",position:"relative",cursor:"pointer",transition:"background 0.2s",flexShrink:0}}>
                            <div style={{position:"absolute",top:2.5,left:s.enabled?"auto":2.5,right:s.enabled?2.5:"auto",width:17,height:17,borderRadius:99,background:"#fff",transition:"all 0.22s cubic-bezier(0.34,1.56,0.64,1)",boxShadow:"0 1px 3px rgba(0,0,0,0.25)"}}/>
                          </div>
                          <button onClick={()=>removeSched(med.id,idx)} style={{background:"none",border:"none",cursor:"pointer",padding:2,color:L.sub}}>
                            <Ic d={ic.x} size={13} c={L.sub}/>
                          </button>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </>
      )}

      {/* Add alarm bottom sheet */}
      {adding&&(
        <AddAlarmSheet
          med={meds.find(m=>m.id===adding)||meds[0]}
          onAdd={ns=>addSched(adding,ns)}
          onClose={()=>setAdding(null)}
        />
      )}
    </div>
  );
}

/* ══════════════════════════════════════════════
   MED DETAIL
══════════════════════════════════════════════ */
function MedDetail({med,onBack,onUpdate,onDelete,onEdit}) {
  const pct=Math.max(0,Math.min(1,med.count/med.totalCount));
  const L=useTheme();
  const taken=med.totalCount-med.count;
  const isLow=med.count<=med.refillAt;
  const unit=med.isLiquid?(med.volumeUnit||"ml"):"";
  return(
    <div style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",background:L.bg,minHeight:"100vh",maxWidth:430,margin:"0 auto",paddingBottom:40}}>
      <style>{GLOBAL_CSS}</style>
      <div style={{padding:"0 20px 100px"}}>
        <div style={{paddingTop:56,display:"flex",alignItems:"center",gap:12,marginBottom:20}}>
          <button onClick={onBack} style={{background:"transparent",border:"none",borderRadius:10,height:36,display:"flex",alignItems:"center",justifyContent:"center",cursor:"pointer",paddingLeft:0,paddingRight:8,color:L.text}}><Ic d={ic.back} size={16}/></button>
          <h1 style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:22,fontWeight:700,margin:0,color:L.text,letterSpacing:"-0.3px"}}>{med.name}</h1>
          {med.isLiquid&&<Badge bg="#FFF7ED" color="#C2410C">Liquid</Badge>}
        </div>
        <div style={{background:L.card,borderRadius:16,padding:20,marginBottom:14,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)",display:"flex",alignItems:"center",gap:20}}>
          <Ring pct={pct} size={110} sw={9} color={isLow?L.red:med.color} label={med.count+(med.isLiquid?unit:"")} sub={med.isLiquid?"remaining":"pills left"}/>
          <div style={{flex:1}}>
            <p style={{margin:"0 0 4px",fontWeight:700,fontSize:18,color:L.text,letterSpacing:"-0.5px"}}>{med.count}{unit}<span style={{fontSize:13,fontWeight:400,color:L.sub}}> / {med.totalCount}{unit}</span></p>
            <Badge bg={isLow?L.redLight:L.greenLight} color={isLow?L.red:L.green}>{isLow?"Refill Soon":"Stocked"}</Badge>
            <p style={{margin:"8px 0 0",fontSize:12,color:L.sub}}>{taken}{unit} taken · {Math.round((1-pct)*100)}% done</p>
            <div style={{display:"flex",alignItems:"center",gap:10,marginTop:12}}>
              <button onClick={()=>onUpdate(med.id,{count:Math.max(0,med.count-1)})} style={{width:36,height:36,borderRadius:99,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)",background:L.bg,cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center"}}><Ic d={ic.minus} size={15} c={L.text}/></button>
              <span style={{fontSize:12,fontWeight:600,color:L.sub}}>adjust</span>
              <button onClick={()=>onUpdate(med.id,{count:med.count+1})} style={{width:36,height:36,borderRadius:99,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)",background:L.bg,cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center"}}><Ic d={ic.plus} size={15} c={L.text}/></button>
            </div>
          </div>
        </div>
        <div style={{background:L.card,borderRadius:14,padding:18,marginBottom:12,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)"}}>
          <Lbl>Details</Lbl>
          <div style={{display:"flex",flexDirection:"column",gap:10}}>
            <IRow label="Brand" value={med.brand||"—"}/><IRow label="Dosage" value={med.dose||"—"}/><IRow label="Category" value={med.category||"—"}/>
            {med.form&&<IRow label="Form" value={med.form}/>}
            {med.isLiquid&&med.dosePerTake&&<IRow label="Per dose" value={med.dosePerTake}/>}
            {med.notes&&<IRow label="Notes" value={med.notes}/>}
          </div>
        </div>
        <div style={{background:L.card,borderRadius:14,padding:18,marginBottom:12,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)"}}>
          <Lbl>Schedule</Lbl>
          {med.schedule.length===0?<p style={{color:L.sub,fontSize:13,margin:0}}>No reminders set. Go to Alarms to add.</p>:
          med.schedule.map((s,i)=>(
            <div key={i} style={{display:"flex",alignItems:"center",gap:10,padding:"9px 0",borderBottom:i<med.schedule.length-1?`1px solid ${L.border}`:"none"}}>
              <span style={{fontSize:17,fontWeight:700,color:L.text,fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>{fmt(s.time?.h??s.h,s.time?.m??s.m)}</span>
              <span style={{color:L.sub,fontSize:12}}>{s.label}</span>
              {s.withFood&&<Badge bg={L.greenLight} color={L.green}>Food</Badge>}
              {!s.enabled&&<Badge bg={L.bg} color={L.sub}>Off</Badge>}
            </div>
          ))}
        </div>
        <div style={{display:"flex",gap:10}}>
          <button onClick={()=>onEdit(med)} style={{flex:1,padding:"13px",background:L.fill,border:"none",borderRadius:12,fontSize:15,fontWeight:500,color:L.text,cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center",gap:6,fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}><Ic d={ic.edit} size={14}/> Edit</button>
          <button onClick={()=>setConfirmDelete(true)} style={{flex:1,padding:"13px",background:L.redLight,border:"none",borderRadius:12,fontSize:15,fontWeight:500,color:L.red,cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center",gap:6,fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}><Ic d={ic.trash} size={14}/> Remove</button>
        </div>
      </div>
    </div>
  );
}

/* ══════════════════════════════════════════════
   EDIT MED
══════════════════════════════════════════════ */
function EditMed({med,onSave,onBack,showToast}) {
  const [f,setF]=useState({name:med.name,brand:med.brand||"",dose:med.dose||"",category:med.category||"",notes:med.notes||"",form:med.form||"tablet",count:med.count,totalCount:med.totalCount,refillAt:med.refillAt,isLiquid:med.isLiquid||false,volumeUnit:med.volumeUnit||"ml",dosePerTake:med.dosePerTake||""});
  const L=useTheme();
  return(
    <div style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",background:L.bg,minHeight:"100vh",maxWidth:430,margin:"0 auto"}}>
      <style>{GLOBAL_CSS}</style>
      <div style={{padding:"0 20px 100px"}}>
        <div style={{paddingTop:60,display:"flex",alignItems:"center",gap:12,marginBottom:20}}>
          <button onClick={onBack} style={{background:"transparent",border:"none",borderRadius:10,height:36,display:"flex",alignItems:"center",justifyContent:"center",cursor:"pointer",paddingLeft:0,paddingRight:8,color:L.text}}><Ic d={ic.back} size={16}/></button>
          <h1 style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:22,fontWeight:700,margin:0,color:L.text,letterSpacing:"-0.3px"}}>Edit Medicine</h1>
        </div>
        <div style={{display:"flex",flexDirection:"column",gap:14}}>
          <LightInp label="Medicine Name" value={f.name} onChange={e=>setF(p=>({...p,name:e.target.value}))}/>
          <LightInp label="Brand Name" value={f.brand} onChange={e=>setF(p=>({...p,brand:e.target.value}))} placeholder="Optional"/>
          <div style={{display:"grid",gridTemplateColumns:"1fr 1fr",gap:10}}>
            <LightInp label="Dosage" value={f.dose} onChange={e=>setF(p=>({...p,dose:e.target.value}))} placeholder="500mg"/>
            <LightInp label="Form" value={f.form} onChange={e=>setF(p=>({...p,form:e.target.value}))} placeholder="tablet"/>
          </div>
          <LightInp label="Category" value={f.category} onChange={e=>setF(p=>({...p,category:e.target.value}))}/>
          {f.isLiquid?(
            <div style={{display:"grid",gridTemplateColumns:"1fr 1fr 1fr",gap:10}}>
              <LightInp label="Volume left" type="number" value={f.count} onChange={e=>setF(p=>({...p,count:parseInt(e.target.value)||0}))}/>
              <LightInp label="Total vol." type="number" value={f.totalCount} onChange={e=>setF(p=>({...p,totalCount:parseInt(e.target.value)||0}))}/>
              <LightInp label="Unit" value={f.volumeUnit} onChange={e=>setF(p=>({...p,volumeUnit:e.target.value}))}/>
            </div>
          ):(
            <div style={{display:"grid",gridTemplateColumns:"1fr 1fr 1fr",gap:10}}>
              <LightInp label="Count left" type="number" value={f.count} onChange={e=>setF(p=>({...p,count:parseInt(e.target.value)||0}))}/>
              <LightInp label="Pack size" type="number" value={f.totalCount} onChange={e=>setF(p=>({...p,totalCount:parseInt(e.target.value)||0}))}/>
              <LightInp label="Alert at" type="number" value={f.refillAt} onChange={e=>setF(p=>({...p,refillAt:parseInt(e.target.value)||0}))}/>
            </div>
          )}
          {f.isLiquid&&<LightInp label="Dose per take" value={f.dosePerTake} placeholder="e.g. 5ml" onChange={e=>setF(p=>({...p,dosePerTake:e.target.value}))}/>}
          <div><label style={{fontSize:11,fontWeight:700,letterSpacing:"0.07em",textTransform:"uppercase",color:L.sub,display:"block",marginBottom:5}}>Notes</label><textarea value={f.notes} onChange={e=>setF(p=>({...p,notes:e.target.value}))} style={{width:"100%",padding:"12px 14px",background:L.bg,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)",borderRadius:12,fontSize:14,color:L.text,outline:"none",resize:"none",height:80,fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}/></div>
        </div>
        {!f.name.trim()&&<p style={{color:L.red,fontSize:12,margin:"0 0 8px",fontWeight:600}}>⚠ Medicine name is required</p>}
        <button onClick={()=>{if(!f.name.trim())return;onSave(f);}} style={{width:"100%",marginTop:20,padding:"16px",background:L.blue,border:"none",borderRadius:14,fontSize:17,fontWeight:600,color:"#fff",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>Save Changes</button>
      </div>
    </div>
  );
}

/* ══════════════════════════════════════════════
   CAREGIVER ALERT BANNER (in-app simulation)
══════════════════════════════════════════════ */
/* ══════════════════════════════════════════════
   CAREGIVER ALERT BANNER
══════════════════════════════════════════════ */
function CaregiverAlertBanner({alert,onDismiss,onView}) {
  const [progress,setProgress]=useState(100);
  const L=useTheme();
  useEffect(()=>{const t=setTimeout(onDismiss,9000);return()=>clearTimeout(t);},[]);
  useEffect(()=>{const s=Date.now();const id=setInterval(()=>setProgress(Math.max(0,100-(Date.now()-s)/90)),80);return()=>clearInterval(id);},[]);
  return(
    <div style={{position:"fixed",top:12,left:"50%",transform:"translateX(-50%)",width:"calc(100% - 32px)",maxWidth:398,zIndex:3000,animation:"notifSlide 0.45s cubic-bezier(0.34,1.56,0.64,1) forwards"}}>
      <div style={{background:"#1C1917",borderRadius:14,overflow:"hidden",boxShadow:"0 20px 60px rgba(0,0,0,0.6)",border:"1px solid rgba(239,68,68,0.4)"}}>
        <div style={{height:3,background:"rgba(239,68,68,0.15)"}}>
          <div style={{height:"100%",width:`${progress}%`,background:"linear-gradient(90deg,#EF4444,#F97316)",transition:"width 0.08s linear",borderRadius:99}}/>
        </div>
        <div style={{padding:"14px 16px"}}>
          <div style={{display:"flex",alignItems:"center",gap:10,marginBottom:10}}>
            <div style={{width:36,height:36,borderRadius:11,background:"rgba(239,68,68,0.2)",border:"1px solid rgba(239,68,68,0.4)",display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0,animation:"pulseDot 1.5s ease-in-out infinite"}}>
              <Ic d={ic.alertTri} size={17} c="#EF4444"/>
            </div>
            <div style={{flex:1}}>
              <p style={{margin:0,fontWeight:700,fontSize:13,color:"#FEF2F2"}}>⚠️ Escalation: Caregiver Alerted</p>
              <p style={{margin:"1px 0 0",fontSize:11,color:"#9CA3AF"}}>Notified: {alert.caregivers?.map(c=>c.name).join(", ")}</p>
            </div>
            <button onClick={onDismiss} style={{background:"none",border:"none",color:"#6B7280",cursor:"pointer",padding:4,flexShrink:0}}><Ic d={ic.x} size={15} c="#6B7280"/></button>
          </div>
          <div style={{background:"rgba(239,68,68,0.1)",borderRadius:14,padding:"11px 13px",marginBottom:11,border:"1px solid rgba(239,68,68,0.2)"}}>
            <p style={{margin:"0 0 8px",fontSize:12,color:"#9CA3AF",fontWeight:600}}>Escalation path:</p>
            <div style={{display:"flex",alignItems:"center",gap:4,flexWrap:"wrap"}}>
              {["Reminder","Snoozed","Missed","Alert sent"].map((s,i,arr)=>(
                <React.Fragment key={s}>
                  <span style={{fontSize:10,fontWeight:700,padding:"3px 8px",borderRadius:99,background:i===arr.length-1?"rgba(239,68,68,0.3)":"rgba(255,255,255,0.06)",color:i===arr.length-1?"#FCA5A5":"#9CA3AF"}}>{s}</span>
                  {i<arr.length-1&&<span style={{color:"#4B5563",fontSize:10}}>→</span>}
                </React.Fragment>
              ))}
            </div>
            <p style={{margin:"8px 0 0",fontSize:13,color:"#FCA5A5",lineHeight:1.5}}>
              ⚠️ Missed <strong style={{color:"#FECACA"}}>{alert.medName}</strong> at {alert.time} — please check on them 🙏
            </p>
          </div>
          <div style={{display:"flex",gap:8}}>
            <button onClick={onDismiss} style={{flex:1,padding:"10px",background:"rgba(255,255,255,0.06)",border:"1px solid rgba(255,255,255,0.1)",borderRadius:10,fontSize:12,fontWeight:700,color:"#9CA3AF",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>Dismiss</button>
            <button onClick={onView} style={{flex:2,padding:"10px",background:"#EF4444",border:"none",borderRadius:10,fontSize:12,fontWeight:700,color:"#fff",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",display:"flex",alignItems:"center",justifyContent:"center",gap:6}}>
              <Ic d={ic.users} size={13} c="#fff"/> View Family Hub
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ── QR Code component (uses goqr.me free API) ── */
function QRCode({value, size=200}) {
  const url=`https://api.qrserver.com/v1/create-qr-code/?size=${size}x${size}&data=${encodeURIComponent(value)}&bgcolor=FFFFFF&color=000000&qzone=1&margin=0&format=png`;
  return(
    <img src={url} alt="QR Code" width={size} height={size}
      style={{borderRadius:10,display:"block"}}
      onError={e=>{e.target.style.display="none";}}
    />
  );
}

/* ── Escalation Timeline ── */
function EscalationTimeline({steps,activeStep}) {
  const L=useTheme();
  const STEPS=[
    {key:"reminder",label:"Reminder sent",desc:"User notified at dose time",icon:"🔔",color:L.blue},
    {key:"snooze",label:"Snoozed / No response",desc:"User didn't confirm dose",icon:"😴",color:L.amber},
    {key:"missed",label:"Dose missed",desc:"30 min passed, not taken",icon:"❌",color:"#F97316"},
    {key:"caregiver_alert",label:"Caregiver alerted",desc:"Alert sent to all caregivers",icon:"⚠️",color:L.red},
  ];
  const active=activeStep||steps?.length||0;
  return(
    <div style={{position:"relative"}}>
      <div style={{position:"absolute",left:19,top:24,bottom:24,width:2,background:L.border,borderRadius:99}}/>
      {STEPS.map((s,i)=>{
        const done=i<active, cur=i===active-1;
        return(
          <div key={s.key} style={{display:"flex",gap:14,alignItems:"flex-start",paddingBottom:i<STEPS.length-1?16:0,position:"relative",zIndex:1}}>
            <div style={{width:38,height:38,borderRadius:99,background:done?s.color:L.border,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0,border:`2px solid ${done?s.color:L.border}`,transition:"all 0.3s",boxShadow:cur?`0 0 0 4px ${s.color}25`:"none"}}>
              <span style={{fontSize:done?15:13,opacity:done?1:0.4}}>{done?s.icon:"·"}</span>
            </div>
            <div style={{flex:1,paddingTop:4}}>
              <p style={{margin:0,fontWeight:700,fontSize:13,color:done?L.text:L.sub}}>{s.label}</p>
              <p style={{margin:"1px 0 0",fontSize:11,color:L.sub}}>{s.desc}</p>
            </div>
            {cur&&<span style={{fontSize:9,fontWeight:700,padding:"2px 7px",borderRadius:99,background:`${s.color}15`,color:s.color,textTransform:"uppercase",letterSpacing:"0.06em",marginTop:6,flexShrink:0}}>Now</span>}
          </div>
        );
      })}
    </div>
  );
}

/* ══════════════════════════════════════════════
   CAREGIVER DASHBOARD
   (Full view of patient status from caregiver POV)
══════════════════════════════════════════════ */
function CaregiverDashboard({cg, profile, meds, doses, takenToday, history, today, lowMeds, missedAlerts, onBack}) {
  const allDoses7=Object.values(history).flat();
  const L=useTheme();
  const adh7=allDoses7.length?Math.round(allDoses7.filter(d=>d.taken).length/allDoses7.length*100):0;
  const todayDoses=doses;
  const cgAlerts=missedAlerts.filter(a=>a.caregivers?.some(c=>c.id===cg.id));

  // Build today's dose status list
  const doseStatus=todayDoses.map(d=>{
    const taken=takenToday[d.key];
    const schedMins=d.sched.time.h*60+d.sched.time.m;
    const nowM=nowMins();
    const overdue=!taken&&nowM>schedMins+5;
    const upcoming=!taken&&nowM<=schedMins+5;
    return {d, taken, overdue, upcoming};
  });
  const takenCount=doseStatus.filter(x=>x.taken).length;
  const missedCount=doseStatus.filter(x=>x.overdue).length;
  const upcomingCount=doseStatus.filter(x=>x.upcoming).length;

  return(
    <div style={{background:L.bg,minHeight:"100vh",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>
      <style>{GLOBAL_CSS}</style>
      {/* Header */}
      <div style={{padding:"0 20px",paddingTop:56}}>
        <div style={{display:"flex",alignItems:"center",gap:12,marginBottom:4}}>
          <button onClick={onBack} style={{background:"transparent",border:"none",borderRadius:10,height:36,display:"flex",alignItems:"center",justifyContent:"center",cursor:"pointer",paddingLeft:0,paddingRight:8,flexShrink:0}}>
            <Ic d={ic.back} size={16} c={L.text}/>
          </button>
          <div style={{flex:1}}>
            <p style={{margin:0,fontSize:11,fontWeight:700,letterSpacing:"0.07em",textTransform:"uppercase",color:L.green}}>Caregiver Dashboard</p>
            <h1 style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:22,fontWeight:700,margin:0,color:L.text}}>{cg.name}</h1>
          </div>
          <div style={{width:46,height:46,borderRadius:14,background:`${cg.color}18`,border:`2px solid ${cg.color}30`,display:"flex",alignItems:"center",justifyContent:"center",fontSize:24}}>
            {cg.avatar}
          </div>
        </div>

        {/* Patient identity card */}
        <div style={{background:"linear-gradient(135deg,#1E1E2A,#12121A)",borderRadius:14,padding:"18px 20px",margin:"18px 0 16px",border:"1px solid rgba(163,230,53,0.15)"}}>
          <div style={{display:"flex",alignItems:"center",gap:14,marginBottom:14}}>
            <div style={{width:52,height:52,borderRadius:16,background:"rgba(163,230,53,0.12)",display:"flex",alignItems:"center",justifyContent:"center",fontSize:28}}>👴</div>
            <div>
              <p style={{margin:0,fontWeight:700,fontSize:18,color:"#fff",letterSpacing:"-0.3px",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>{profile?.name||"Your patient"}</p>
              <p style={{margin:"2px 0 0",fontSize:14,color:"rgba(235,235,245,0.55)"}}>Monitoring since {cg.addedAt||"today"}</p>
            </div>
            <div style={{marginLeft:"auto",textAlign:"right"}}>
              <p style={{margin:0,fontSize:28,fontWeight:700,color:adh7>=80?"#A3E635":adh7>=60?"#F59E0B":"#EF4444",letterSpacing:"-1px",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>{adh7}%</p>
              <p style={{margin:0,fontSize:10,fontWeight:700,color:"#8080A0",textTransform:"uppercase",letterSpacing:"0.06em"}}>7-day adherence</p>
            </div>
          </div>
          {/* 7-day mini bar chart */}
          <div style={{display:"flex",gap:4,alignItems:"flex-end",height:32}}>
            {Array.from({length:7}).map((_,i)=>{
              const d=new Date();d.setDate(d.getDate()-(6-i));
              const k=d.toISOString().slice(0,10);
              const ds=history[k]||[];
              const rate=ds.length?ds.filter(x=>x.taken).length/ds.length:0;
              const isT=k===today;
              return(
                <div key={i} style={{flex:1,display:"flex",flexDirection:"column",alignItems:"center",gap:2}}>
                  <div style={{width:"100%",height:24,background:"rgba(255,255,255,0.06)",borderRadius:4,overflow:"hidden",position:"relative"}}>
                    <div style={{position:"absolute",bottom:0,width:"100%",height:`${isT?50:rate*100}%`,background:isT?"#93C5FD":rate>=0.8?"#A3E635":rate>0?"#F59E0B":"rgba(239,68,68,0.4)",borderRadius:4,transition:"height 0.5s"}}/>
                  </div>
                  <span style={{fontSize:7,color:"#4B5563",fontWeight:700}}>{["S","M","T","W","T","F","S"][d.getDay()]}</span>
                </div>
              );
            })}
          </div>
        </div>

        {/* Today stat pills */}
        <div style={{display:"grid",gridTemplateColumns:"1fr 1fr 1fr",gap:8,marginBottom:20}}>
          {[{e:"✅",v:takenCount,l:"Taken",c:L.green,bg:L.greenLight},{e:"❌",v:missedCount,l:"Missed",c:L.red,bg:L.redLight},{e:"⏰",v:upcomingCount,l:"Upcoming",c:L.blue,bg:L.blueLight}].map((s,i)=>(
            <div key={i} style={{background:L.card,borderRadius:16,padding:"14px 10px",border:"1px solid "+(missedCount>0&&i===1?L.red+"40":L.border),textAlign:"center"}}>
              <span style={{fontSize:20}}>{s.e}</span>
              <p style={{margin:"6px 0 2px",fontSize:24,fontWeight:700,color:s.c,letterSpacing:"-1px"}}>{s.v}</p>
              <p style={{margin:0,fontSize:10,fontWeight:700,color:L.sub,textTransform:"uppercase",letterSpacing:"0.04em"}}>{s.l}</p>
            </div>
          ))}
        </div>

        {/* Today's dose list */}
        <div style={{marginBottom:20}}>
          <p style={{margin:"0 0 10px",fontSize:11,fontWeight:700,letterSpacing:"0.07em",textTransform:"uppercase",color:L.sub}}>Today's Medications</p>
          {doseStatus.length===0?(
            <div style={{background:L.card,borderRadius:16,padding:"20px",boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)",textAlign:"center"}}>
              <p style={{color:L.sub,fontSize:13,margin:0}}>No medications scheduled for today.</p>
            </div>
          ):(
            <div style={{display:"flex",flexDirection:"column",gap:8}}>
              {doseStatus.map(({d,taken,overdue,upcoming},i)=>{
                const icon=taken?"✅":overdue?"❌":"⏰";
                const statusColor=taken?L.green:overdue?L.red:L.blue;
                const statusLabel=taken?"Taken":overdue?"Missed":"Upcoming";
                return(
                  <div key={i} style={{background:L.card,borderRadius:16,padding:"14px 16px",border:"1.5px solid "+(overdue?L.red+"35":taken?L.green+"25":L.border),display:"flex",alignItems:"center",gap:12}}>
                    <div style={{width:40,height:40,borderRadius:12,background:taken?L.greenLight:overdue?L.redLight:L.blueLight,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0,fontSize:20}}>
                      {icon}
                    </div>
                    <div style={{flex:1,minWidth:0}}>
                      <p style={{margin:0,fontWeight:700,fontSize:14,color:L.text}}>{d.med.name}</p>
                      <p style={{margin:"2px 0 0",fontSize:12,color:L.sub}}>{d.sched.label} · {fmt(d.sched.time.h,d.sched.time.m)} · {d.med.dose}</p>
                    </div>
                    <span style={{fontSize:10,fontWeight:700,padding:"3px 9px",borderRadius:99,background:taken?L.greenLight:overdue?L.redLight:L.blueLight,color:statusColor,textTransform:"uppercase",letterSpacing:"0.04em",flexShrink:0}}>
                      {statusLabel}
                    </span>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Refill alerts */}
        {lowMeds.length>0&&(
          <div style={{marginBottom:20}}>
            <p style={{margin:"0 0 10px",fontSize:11,fontWeight:700,letterSpacing:"0.07em",textTransform:"uppercase",color:L.sub}}>Refill Alerts</p>
            <div style={{background:L.redLight,borderRadius:13,padding:"14px 16px",border:"1px solid #FCA5A5"}}>
              <div style={{display:"flex",gap:10,alignItems:"flex-start"}}>
                <span style={{fontSize:22}}>⚠️</span>
                <div>
                  <p style={{margin:"0 0 4px",fontWeight:700,fontSize:13,color:L.red}}>Low Stock — Refill Needed</p>
                  {lowMeds.map(m=>(
                    <p key={m.id} style={{margin:"2px 0 0",fontSize:12,color:L.text}}>
                      <strong>{m.name}</strong> — only <strong style={{color:L.red}}>{m.count}</strong> {m.isLiquid?(m.volumeUnit||"ml"):"pills"} left
                    </p>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Escalation timeline for latest missed alert */}
        {cgAlerts.length>0&&(
          <div style={{marginBottom:20}}>
            <p style={{margin:"0 0 12px",fontSize:11,fontWeight:700,letterSpacing:"0.07em",textTransform:"uppercase",color:L.sub}}>Latest Escalation</p>
            <div style={{background:L.card,borderRadius:13,padding:"18px 16px",boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)"}}>
              <div style={{display:"flex",alignItems:"center",gap:10,marginBottom:16,paddingBottom:14,borderBottom:`1px solid ${L.border}`}}>
                <div style={{width:36,height:36,borderRadius:11,background:L.redLight,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0}}>
                  <Ic d={ic.alertTri} size={17} c={L.red}/>
                </div>
                <div style={{flex:1}}>
                  <p style={{margin:0,fontWeight:700,fontSize:14,color:L.text}}>{cgAlerts[0].medName}</p>
                  <p style={{margin:0,fontSize:12,color:L.sub}}>Missed {cgAlerts[0].doseLabel} at {cgAlerts[0].time} · {cgAlerts[0].timestamp}</p>
                </div>
              </div>
              <EscalationTimeline steps={cgAlerts[0].escalation} activeStep={4}/>
            </div>
          </div>
        )}

        {/* All alerts from this caregiver */}
        {cgAlerts.length>0&&(
          <div style={{marginBottom:28}}>
            <p style={{margin:"0 0 10px",fontSize:11,fontWeight:700,letterSpacing:"0.07em",textTransform:"uppercase",color:L.sub}}>Alert History ({cgAlerts.length})</p>
            <div style={{display:"flex",flexDirection:"column",gap:8}}>
              {cgAlerts.slice(0,5).map((a,i)=>(
                <div key={i} style={{background:L.card,borderRadius:14,padding:"12px 14px",boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)",display:"flex",alignItems:"center",gap:10}}>
                  <div style={{width:8,height:8,borderRadius:99,background:L.red,flexShrink:0}}/>
                  <div style={{flex:1}}>
                    <p style={{margin:0,fontWeight:700,fontSize:13,color:L.text}}>{a.medName}</p>
                    <p style={{margin:0,fontSize:11,color:L.sub}}>Missed {a.doseLabel} at {a.time}</p>
                  </div>
                  <span style={{fontSize:11,color:L.sub}}>{a.timestamp}</span>
                </div>
              ))}
            </div>
          </div>
        )}

        {cgAlerts.length===0&&(
          <div style={{background:"#F0FDF4",borderRadius:13,padding:"18px",border:"1px solid #BBF7D0",textAlign:"center",marginBottom:28}}>
            <span style={{fontSize:32}}>✅</span>
            <p style={{margin:"8px 0 4px",fontWeight:700,fontSize:15,color:L.green}}>No alerts needed!</p>
            <p style={{margin:0,fontSize:13,color:L.sub}}>All doses have been taken consistently.</p>
          </div>
        )}
      </div>
    </div>
  );
}

/* ══════════════════════════════════════════════
   FAMILY HUB
══════════════════════════════════════════════ */
function FamilyTab({profile,meds,doses,takenToday,history,today,lowMeds,caregivers,setCaregivers,missedAlerts,setMissedAlerts,onSimulateMiss,showToast}) {
  const [view,setView]=useState("hub");
  const L=useTheme();
  const [addStep,setAddStep]=useState(1);
  const [newCg,setNewCg]=useState({name:"",relation:"Daughter",contact:"",avatar:"👩",alertDelay:30,methods:["push","sms"]});
  const [dashCg,setDashCg]=useState(null);
  const [showAlertDetail,setShowAlertDetail]=useState(null);
  const [copiedId,setCopiedId]=useState(null);
  const [simulating,setSimulating]=useState(false);
  const [expandedId,setExpandedId]=useState(null);
  const [demoStep,setDemoStep]=useState(1);
  const [scanSimState,setScanSimState]=useState("idle");
  const [joinCodeModal,setJoinCodeModal]=useState(false);
  const [joinCodeInput,setJoinCodeInput]=useState("");
  const [joinCodeError,setJoinCodeError]=useState("");
  const [joinCodeSuccess,setJoinCodeSuccess]=useState(null);
  const [joinTab,setJoinTab]=useState("qr");            // "qr" | "code"
  const [joinQRScanState,setJoinQRScanState]=useState("idle"); // idle | scanning | done

  const AVATARS=["👨","👩","👴","👵","👦","👧","🧑","👨‍⚕️","👩‍⚕️","🧓","🧑‍🦱","🧑‍🦳"];
  const RELATIONS=["Spouse","Parent","Son","Daughter","Sibling","Friend","Doctor","Caregiver"];

  const activeCount=caregivers.filter(c=>c.status==="active").length;
  const pendingCount=caregivers.filter(c=>c.status==="pending").length;
  const unseenCount=missedAlerts.filter(a=>!a.seen).length;

  useEffect(()=>{const t=setTimeout(()=>setMissedAlerts(p=>p.map(a=>({...a,seen:true}))),1200);return()=>clearTimeout(t);},[]);

  function genInviteCode(id){return`MT-${Math.abs(id).toString(16).toUpperCase().slice(-6)}`;}
  function genInviteUrl(id){return`https://medtrack.app/join/${genInviteCode(id)}`;}

  function submitAdd(){
    if(!newCg.name.trim()) return;
    const colors=["#10B981","#3B82F6","#8B5CF6","#F59E0B","#EF4444","#14B8A6","#EC4899"];
    const newId=Date.now();
    if(showToast)showToast(newCg.name+" added as caregiver","success");
    setCaregivers(p=>[...p,{id:newId,name:newCg.name,relation:newCg.relation,contact:newCg.contact,avatar:newCg.avatar,status:"pending",color:colors[p.length%colors.length],alertDelay:newCg.alertDelay,methods:newCg.methods,addedAt:new Date().toLocaleDateString()}]);
    setScanSimState("idle");
    setAddStep(2);
  }
  function removeCaregiver(id){setCaregivers(p=>p.filter(c=>c.id!==id));if(showToast)showToast("Caregiver removed","warning");}
  function activateCaregiver(id){setCaregivers(p=>p.map(c=>c.id===id?{...c,status:"active"}:c));if(showToast)showToast("Caregiver activated ✓","success");}
  function copyInvite(url){
    navigator.clipboard?.writeText(url).catch(()=>{});
    setCopiedId(url);setTimeout(()=>setCopiedId(null),2500);
  }
  function simulateScan(cgId){
    setScanSimState("scanning");
    setTimeout(()=>{
      activateCaregiver(cgId);
      setScanSimState("done");
      setTimeout(()=>setAddStep(3),700);
    },2000);
  }
  function joinViaCode(){
    const code=joinCodeInput.trim().toUpperCase().replace(/^MT-/,"");
    const match=caregivers.find(c=>{
      const cCode=Math.abs(c.id).toString(16).toUpperCase().slice(-6);
      return cCode===code && c.status==="pending";
    });
    if(!match){
      setJoinCodeError("Code not found or already active. Check and try again.");
      return;
    }
    activateCaregiver(match.id);
    setJoinCodeSuccess(match);
    setJoinCodeError("");
    setTimeout(()=>{setJoinCodeModal(false);setJoinCodeInput("");setJoinCodeSuccess(null);},2800);
  }
  function joinViaQR(cgId){
    setJoinQRScanState("scanning");
    setTimeout(()=>{
      activateCaregiver(cgId);
      const cg=caregivers.find(c=>c.id===cgId);
      setJoinQRScanState("done");
      if(cg) setJoinCodeSuccess(cg);
      setTimeout(()=>{setJoinCodeModal(false);setJoinCodeSuccess(null);setJoinQRScanState("idle");},2200);
    },2000);
  }
  function simulateMiss(){
    setSimulating(true);
    setTimeout(()=>{if(onSimulateMiss)onSimulateMiss();setSimulating(false);},1800);
  }

  // ── Caregiver Dashboard
  if(view==="dashboard"&&dashCg){
    return(
      <CaregiverDashboard
        cg={dashCg} profile={profile} meds={meds} doses={doses}
        takenToday={takenToday} history={history} today={today}
        lowMeds={lowMeds} missedAlerts={missedAlerts}
        onBack={()=>{setView("hub");setDashCg(null);}}
      />
    );
  }

  // ── Add Caregiver flow
  if(view==="add"){
    const lastCg=caregivers[caregivers.length-1];
    const inviteUrl=lastCg?genInviteUrl(lastCg.id):"https://medtrack.app/join/PREVIEW";
    return(
      <div style={{padding:"0 20px 60px",paddingTop:56,background:L.bg,minHeight:"100vh"}}>
        {/* Back + Title */}
        <div style={{display:"flex",alignItems:"center",gap:12,marginBottom:24}}>
          <button onClick={()=>{setView("hub");setAddStep(1);}} style={{background:"transparent",border:"none",borderRadius:10,height:36,display:"flex",alignItems:"center",justifyContent:"center",cursor:"pointer",paddingLeft:0,paddingRight:8,flexShrink:0}}>
            <Ic d={ic.back} size={16} c={L.text}/>
          </button>
          <div>
            <h1 style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:22,fontWeight:700,margin:0,color:L.text}}>
              {addStep===1?"Add Caregiver":addStep===2?"Share QR Code":"🎉 Caregiver Active!"}
            </h1>
            <p style={{margin:0,fontSize:12,color:L.sub}}>Step {addStep} of 3</p>
          </div>
        </div>
        {/* Progress */}
        <div style={{display:"flex",gap:6,marginBottom:28}}>
          {[1,2,3].map(n=><div key={n} style={{height:4,flex:1,borderRadius:99,background:addStep>=n?L.green:L.border,transition:"background 0.3s"}}/>)}
        </div>

        {/* Step 1 — Info */}
        {addStep===1&&(
          <div>
            {/* Avatar */}
            <p style={{margin:"0 0 8px",fontSize:11,fontWeight:700,letterSpacing:"0.07em",textTransform:"uppercase",color:L.sub}}>Choose avatar</p>
            <div style={{display:"flex",gap:7,flexWrap:"wrap",marginBottom:20}}>
              {AVATARS.map(a=>(
                <button key={a} onClick={()=>setNewCg(p=>({...p,avatar:a}))}
                  style={{width:44,height:44,borderRadius:13,background:newCg.avatar===a?L.greenLight:L.bg,border:`2px solid ${newCg.avatar===a?L.green:L.border}`,fontSize:22,cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center",transition:"all 0.15s"}}>
                  {a}
                </button>
              ))}
            </div>
            {/* Name */}
            <p style={{margin:"0 0 6px",fontSize:11,fontWeight:700,letterSpacing:"0.07em",textTransform:"uppercase",color:L.sub}}>Full name *</p>
            <input value={newCg.name} onChange={e=>setNewCg(p=>({...p,name:e.target.value}))} placeholder="e.g. Sarah Johnson"
              style={{width:"100%",padding:"14px",background:L.card,border:`1.5px solid ${newCg.name?L.green:L.border}`,borderRadius:13,fontSize:15,color:L.text,outline:"none",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",boxSizing:"border-box",marginBottom:14,transition:"border-color 0.2s"}}/>
            {/* Relationship */}
            <p style={{margin:"0 0 8px",fontSize:11,fontWeight:700,letterSpacing:"0.07em",textTransform:"uppercase",color:L.sub}}>Relationship</p>
            <div style={{display:"flex",gap:6,flexWrap:"wrap",marginBottom:16}}>
              {RELATIONS.map(r=>(
                <button key={r} onClick={()=>setNewCg(p=>({...p,relation:r}))}
                  style={{padding:"7px 13px",background:newCg.relation===r?L.green:L.card,border:`1px solid ${newCg.relation===r?L.green:L.border}`,borderRadius:99,fontSize:12,fontWeight:600,color:newCg.relation===r?"#fff":L.sub,cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",transition:"all 0.15s"}}>
                  {r}
                </button>
              ))}
            </div>
            {/* Phone */}
            <p style={{margin:"0 0 6px",fontSize:11,fontWeight:700,letterSpacing:"0.07em",textTransform:"uppercase",color:L.sub}}>Phone (optional — for SMS backup)</p>
            <input value={newCg.contact} onChange={e=>setNewCg(p=>({...p,contact:e.target.value}))} placeholder="+880 1XXX-XXXXXX"
              style={{width:"100%",padding:"14px",background:L.card,border:`1.5px solid ${newCg.contact?L.green:L.border}`,borderRadius:13,fontSize:15,color:L.text,outline:"none",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",boxSizing:"border-box",marginBottom:16,transition:"border-color 0.2s"}}/>
            {/* Alert delay */}
            <p style={{margin:"0 0 8px",fontSize:11,fontWeight:700,letterSpacing:"0.07em",textTransform:"uppercase",color:L.sub}}>Alert after missed dose by</p>
            <div style={{display:"flex",gap:6,marginBottom:28}}>
              {[{v:0,l:"Now"},{v:15,l:"15 min"},{v:30,l:"30 min"},{v:60,l:"1 hour"}].map(opt=>(
                <button key={opt.v} onClick={()=>setNewCg(p=>({...p,alertDelay:opt.v}))}
                  style={{flex:1,padding:"10px 4px",background:newCg.alertDelay===opt.v?L.green:L.card,border:`1px solid ${newCg.alertDelay===opt.v?L.green:L.border}`,borderRadius:11,fontSize:11,fontWeight:700,color:newCg.alertDelay===opt.v?"#fff":L.sub,cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",textAlign:"center",transition:"all 0.15s"}}>
                  {opt.l}
                </button>
              ))}
            </div>
            <button onClick={submitAdd} disabled={!newCg.name.trim()}
              style={{width:"100%",padding:"17px",background:newCg.name.trim()?L.green:L.border,border:"none",borderRadius:16,fontSize:15,fontWeight:700,color:newCg.name.trim()?"#fff":L.sub,cursor:newCg.name.trim()?"pointer":"default",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",transition:"all 0.2s"}}>
              Generate QR Code →
            </button>
          </div>
        )}

        {/* Step 2 — QR Code */}
        {addStep===2&&lastCg&&(
          <div style={{textAlign:"center"}}>
            <div style={{display:"flex",alignItems:"center",gap:14,background:L.card,borderRadius:14,padding:"16px 18px",marginBottom:20,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)",textAlign:"left"}}>
              <div style={{width:50,height:50,borderRadius:15,background:L.greenLight,display:"flex",alignItems:"center",justifyContent:"center",fontSize:26,flexShrink:0}}>{lastCg.avatar}</div>
              <div>
                <p style={{margin:0,fontWeight:700,fontSize:16,color:L.text}}>{lastCg.name}</p>
                <p style={{margin:"2px 0 0",fontSize:12,color:L.sub}}>{lastCg.relation}{lastCg.contact&&` · ${lastCg.contact}`}</p>
              </div>
              <span style={{marginLeft:"auto",fontSize:10,fontWeight:700,padding:"3px 10px",borderRadius:99,background:"#FEF3C7",color:L.amber,textTransform:"uppercase",letterSpacing:"0.05em"}}>⏳ Pending</span>
            </div>

            {/* QR Code block */}
            <div style={{background:L.card,borderRadius:16,padding:24,marginBottom:16,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)",position:"relative",overflow:"hidden"}}>
              {scanSimState==="scanning"&&(
                <div style={{position:"absolute",inset:0,background:"rgba(255,255,255,0.95)",borderRadius:16,display:"flex",flexDirection:"column",alignItems:"center",justifyContent:"center",gap:14,zIndex:10}}>
                  <div style={{width:60,height:60,border:`4px solid ${L.green}`,borderTopColor:"transparent",borderRadius:"50%",animation:"spin 0.9s linear infinite"}}/>
                  <p style={{margin:0,fontWeight:700,fontSize:15,color:L.text}}>Scanning QR code…</p>
                  <p style={{margin:0,fontSize:12,color:L.sub}}>Verifying invite code</p>
                </div>
              )}
              <p style={{margin:"0 0 18px",fontSize:13,fontWeight:700,color:L.text}}>Show this QR code to <strong>{lastCg.name}</strong></p>
              <div style={{display:"flex",justifyContent:"center",marginBottom:18}}>
                <div style={{padding:16,background:"#fff",borderRadius:13,boxShadow:"0 4px 20px rgba(0,0,0,0.08)",position:"relative"}}>
                  <QRCode value={inviteUrl} size={180}/>
                  {/* scan line animation */}
                  {scanSimState==="idle"&&(
                    <div style={{position:"absolute",left:0,right:0,height:2,background:"rgba(16,185,129,0.5)",animation:"scanLine 2s linear infinite",pointerEvents:"none"}}/>
                  )}
                </div>
              </div>
              <div style={{background:L.bg,borderRadius:13,padding:"10px 14px",marginBottom:4}}>
                <p style={{margin:0,fontSize:10,fontWeight:700,color:L.sub,letterSpacing:"0.06em",textTransform:"uppercase",marginBottom:3}}>Invite Code</p>
                <p style={{margin:0,fontSize:16,fontWeight:700,color:L.text,letterSpacing:"0.1em"}}>{genInviteCode(lastCg.id)}</p>
              </div>
            </div>

            {/* What happens after scan */}
            <div style={{background:L.bg,borderRadius:13,padding:"14px 16px",marginBottom:20,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)",textAlign:"left"}}>
              <p style={{margin:"0 0 10px",fontSize:11,fontWeight:700,letterSpacing:"0.07em",textTransform:"uppercase",color:L.sub}}>How it works:</p>
              {[["📱","They open MedTrackAI","Tap 'Join as Caregiver' → scan QR or enter code"],["✅","Instant activation","Status changes to Active automatically"],["🔔","Alerts start immediately","They get notified if you miss a dose"]].map(([e,t,d],i)=>(
                <div key={i} style={{display:"flex",gap:10,paddingBottom:i<2?10:0,marginBottom:i<2?10:0,borderBottom:i<2?`1px solid ${L.border}`:"none"}}>
                  <span style={{fontSize:18,minWidth:24}}>{e}</span>
                  <div><p style={{margin:0,fontSize:13,fontWeight:700,color:L.text}}>{t}</p><p style={{margin:0,fontSize:12,color:L.sub}}>{d}</p></div>
                </div>
              ))}
            </div>

            {/* Action buttons */}
            <button onClick={()=>copyInvite(inviteUrl)}
              style={{width:"100%",padding:"13px",background:copiedId===inviteUrl?L.greenLight:L.card,border:`1px solid ${copiedId===inviteUrl?L.green:L.border}`,borderRadius:14,fontSize:13,fontWeight:700,color:copiedId===inviteUrl?L.green:L.text,cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",marginBottom:10,display:"flex",alignItems:"center",justifyContent:"center",gap:8,transition:"all 0.2s"}}>
              <Ic d={ic.send} size={14} c={copiedId===inviteUrl?L.green:L.text}/> {copiedId===inviteUrl?"✓ Link Copied!":"Copy Invite Link"}
            </button>

            {/* Simulate scan button — the real-life trigger */}
            <button onClick={()=>simulateScan(lastCg.id)} disabled={scanSimState!=="idle"}
              style={{width:"100%",padding:"16px",background:scanSimState==="idle"?L.green:L.greenLight,border:"none",borderRadius:16,fontSize:15,fontWeight:700,color:scanSimState==="idle"?"#fff":L.green,cursor:scanSimState==="idle"?"pointer":"default",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",display:"flex",alignItems:"center",justifyContent:"center",gap:10,transition:"all 0.3s"}}>
              {scanSimState==="idle"&&<><Ic d={ic.camera} size={17} c="#fff"/>Simulate: Caregiver Scanned QR ✓</>}
              {scanSimState==="scanning"&&<><span style={{animation:"spin 0.9s linear infinite",display:"inline-block"}}>⟳</span> Verifying…</>}
              {scanSimState==="done"&&<>✅ Activated!</>}
            </button>
            <p style={{fontSize:11,color:L.sub,marginTop:8,textAlign:"center"}}>In real life, {lastCg.name} scans this with their phone and is instantly added.</p>
          </div>
        )}

        {/* Step 3 — Caregiver Active Confirmation */}
        {addStep===3&&lastCg&&(
          <div style={{textAlign:"center",animation:"celebPop 0.5s cubic-bezier(0.34,1.56,0.64,1) forwards"}}>
            <div style={{width:88,height:88,background:"#F0FDF4",borderRadius:28,display:"flex",alignItems:"center",justifyContent:"center",fontSize:44,margin:"0 auto 20px",border:"2px solid #BBF7D0"}}>✅</div>
            <h2 style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:26,fontWeight:700,margin:"0 0 8px",color:L.text}}>Caregiver Active!</h2>
            <p style={{fontSize:15,color:L.sub,margin:"0 0 24px",lineHeight:1.5}}><strong style={{color:L.text}}>{lastCg.name}</strong> scanned the QR code and joined your care circle.</p>

            {/* Active caregiver pill */}
            <div style={{display:"flex",alignItems:"center",gap:16,background:"#F0FDF4",borderRadius:14,padding:"16px 18px",marginBottom:24,border:"2px solid #BBF7D0",textAlign:"left"}}>
              <div style={{width:52,height:52,borderRadius:15,background:L.greenLight,display:"flex",alignItems:"center",justifyContent:"center",fontSize:28,flexShrink:0}}>{lastCg.avatar}</div>
              <div style={{flex:1}}>
                <p style={{margin:0,fontWeight:700,fontSize:16,color:L.text}}>{lastCg.name}</p>
                <p style={{margin:"2px 0 0",fontSize:12,color:L.sub}}>{lastCg.relation}{lastCg.contact&&` · ${lastCg.contact}`}</p>
              </div>
              <span style={{fontSize:10,fontWeight:700,padding:"4px 12px",borderRadius:99,background:L.greenLight,color:L.green,textTransform:"uppercase",letterSpacing:"0.05em"}}>● Active</span>
            </div>

            {/* What they can do */}
            <div style={{background:L.bg,borderRadius:13,padding:"16px",marginBottom:24,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)",textAlign:"left"}}>
              <p style={{margin:"0 0 12px",fontSize:11,fontWeight:700,letterSpacing:"0.07em",textTransform:"uppercase",color:L.sub}}>They can now:</p>
              {[["📊","See your daily adherence","Live dashboard with today's doses"],["⚠️","Get missed-dose alerts","Notified after "+lastCg.alertDelay+" min if you miss a dose"],["📋","View your medicine list","All your medications at a glance"]].map(([e,t,d],i)=>(
                <div key={i} style={{display:"flex",gap:10,paddingBottom:i<2?10:0,marginBottom:i<2?10:0,borderBottom:i<2?`1px solid ${L.border}`:"none"}}>
                  <span style={{fontSize:18,minWidth:24}}>{e}</span>
                  <div><p style={{margin:0,fontSize:13,fontWeight:700,color:L.text}}>{t}</p><p style={{margin:0,fontSize:12,color:L.sub}}>{d}</p></div>
                </div>
              ))}
            </div>

            <button onClick={()=>{setView("hub");setAddStep(1);setScanSimState("idle");setNewCg({name:"",relation:"Daughter",contact:"",avatar:"👩",alertDelay:30,methods:["push","sms"]});}}
              style={{width:"100%",padding:"16px",background:L.blue,border:"none",borderRadius:14,fontSize:17,fontWeight:600,color:"#fff",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>
              Back to Family Hub →
            </button>
          </div>
        )}
      </div>
    );
  }

  // ── Escalation demo view
  if(view==="escalation-demo"){
    const steps=[
      {s:1,title:"Dose time arrives",detail:`Scheduled dose at 8:00 PM`,action:"Reminder sent to user"},
      {s:2,title:"User snoozed",detail:"User tapped 'Snooze 10 min'",action:"Waiting…"},
      {s:3,title:"Snooze expired, no action",detail:"Still not confirmed after 30 min",action:"Marking as missed"},
      {s:4,title:"Caregivers alerted",detail:"Alert sent to all active caregivers",action:"⚠️ Alert delivered"},
    ];
    return(
      <div style={{padding:"0 20px 60px",paddingTop:56,background:L.bg,minHeight:"100vh"}}>
        <div style={{display:"flex",alignItems:"center",gap:12,marginBottom:24}}>
          <button onClick={()=>setView("hub")} style={{background:"transparent",border:"none",borderRadius:10,height:36,display:"flex",alignItems:"center",justifyContent:"center",cursor:"pointer",paddingLeft:0,paddingRight:8}}><Ic d={ic.back} size={16} c={L.text}/></button>
          <div>
            <h1 style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:22,fontWeight:700,margin:0,color:L.text}}>Escalation Logic</h1>
            <p style={{margin:0,fontSize:12,color:L.sub}}>How missed doses trigger caregiver alerts</p>
          </div>
        </div>
        <EscalationTimeline steps={null} activeStep={demoStep}/>
        <div style={{display:"flex",gap:10,marginTop:28}}>
          <button onClick={()=>setDemoStep(s=>Math.max(1,s-1))} disabled={demoStep<=1}
            style={{flex:1,padding:"14px",background:demoStep<=1?L.border:L.card,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)",borderRadius:14,fontSize:13,fontWeight:700,color:demoStep<=1?L.sub:L.text,cursor:demoStep<=1?"default":"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>
            ← Back
          </button>
          <button onClick={()=>setDemoStep(s=>Math.min(4,s+1))} disabled={demoStep>=4}
            style={{flex:2,padding:"14px",background:demoStep>=4?L.border:L.green,border:"none",borderRadius:14,fontSize:13,fontWeight:700,color:demoStep>=4?L.sub:"#fff",cursor:demoStep>=4?"default":"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>
            {demoStep>=4?"Full flow shown ✓":"Next step →"}
          </button>
        </div>
        {demoStep===4&&(
          <div style={{marginTop:16,background:L.redLight,borderRadius:13,padding:"16px 18px",border:"1px solid #FCA5A5"}}>
            <p style={{margin:"0 0 6px",fontWeight:700,fontSize:14,color:L.red}}>⚠️ Alert message sent:</p>
            <p style={{margin:0,fontSize:13,color:L.text,lineHeight:1.5}}>"{profile?.name||"Your family member"} missed their <strong>8:00 PM blood pressure medicine</strong>. Please check on them. 🙏"</p>
          </div>
        )}
        {/* Alert delay config */}
        <div style={{marginTop:20,background:L.card,borderRadius:13,padding:"16px 18px",boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)"}}>
          <p style={{margin:"0 0 4px",fontWeight:700,fontSize:14,color:L.text}}>⏱️ Default alert delay: 30 minutes</p>
          <p style={{margin:0,fontSize:12,color:L.sub}}>Configurable per caregiver (0 min → 1 hour)</p>
        </div>
      </div>
    );
  }

  // ── Main Hub
  return(
    <div style={{padding:"0 20px"}}>
      {/* Header */}
      <div style={{paddingTop:56,paddingBottom:16}}>
        <div style={{display:"flex",alignItems:"flex-start",justifyContent:"space-between",marginBottom:4}}>
          <div>
            <h1 style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:34,fontWeight:700,margin:0,color:L.text,letterSpacing:"-0.5px"}}>Family</h1>
            <p style={{color:L.sub,fontSize:13,margin:"4px 0 0"}}>
              {activeCount>0?`${activeCount} caregiver${activeCount>1?"s":""} monitoring you`:"Add a caregiver to get started"}
              {pendingCount>0&&` · ${pendingCount} pending QR`}
            </p>
          </div>
          <div style={{display:"flex",gap:8}}>
            <button onClick={()=>{setJoinCodeModal(true);setJoinCodeInput("");setJoinCodeError("");setJoinTab("qr");setJoinQRScanState("idle");}}
              style={{display:"flex",alignItems:"center",gap:5,background:L.blue+"15",border:"none",borderRadius:10,padding:"9px 14px",fontSize:15,fontWeight:500,color:L.blue,cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>
              <Ic d={ic.camera} size={14} c={L.purple}/> Join
            </button>
            <button onClick={()=>{setView("add");setAddStep(1);}}
              style={{display:"flex",alignItems:"center",gap:6,background:L.blue,border:"none",borderRadius:10,padding:"9px 16px",fontSize:15,fontWeight:500,color:"#fff",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>
              <Ic d={ic.plus} size={14} c="#fff"/> Add
            </button>
          </div>
        </div>
        {unseenCount>0&&(
          <div style={{display:"flex",alignItems:"center",gap:6,background:L.redLight,borderRadius:10,padding:"6px 12px",border:"1px solid #FCA5A5",marginTop:8}}>
            <div style={{width:6,height:6,borderRadius:99,background:L.red}}/>
            <span style={{fontSize:12,fontWeight:700,color:L.red}}>{unseenCount} new missed-dose alert{unseenCount>1?"s":""}</span>
          </div>
        )}
      </div>

      {/* Join as Caregiver Modal — QR Scan + Code tabs */}
      {joinCodeModal&&(
        <div style={{position:"fixed",inset:0,background:"rgba(0,0,0,0.4)",zIndex:600,display:"flex",alignItems:"flex-end",justifyContent:"center",backdropFilter:"blur(28px) saturate(180%)",WebkitBackdropFilter:"blur(28px) saturate(180%)"}} onClick={()=>{setJoinCodeModal(false);setJoinQRScanState("idle");setJoinCodeSuccess(null);}}>
          <div style={{background:L.card,borderRadius:"20px 20px 0 0",padding:"28px 24px 52px",width:"100%",maxWidth:430,animation:"slideInUp 0.35s cubic-bezier(0.34,1.56,0.64,1) forwards",maxHeight:"90vh",overflowY:"auto"}} onClick={e=>e.stopPropagation()}>
            {joinCodeSuccess?(
              <div style={{textAlign:"center",animation:"celebPop 0.4s cubic-bezier(0.34,1.56,0.64,1) forwards",padding:"12px 0"}}>
                <div style={{width:80,height:80,background:"#F0FDF4",borderRadius:16,display:"flex",alignItems:"center",justifyContent:"center",fontSize:40,margin:"0 auto 16px",border:"2px solid #BBF7D0"}}>✅</div>
                <h2 style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:24,fontWeight:700,margin:"0 0 8px",color:L.text,letterSpacing:"-0.5px"}}>{joinCodeSuccess.name} is Active!</h2>
                <p style={{color:L.sub,fontSize:14,margin:"0 0 20px",lineHeight:1.5}}>Joined your care circle successfully.</p>
                <div style={{display:"flex",alignItems:"center",gap:14,background:"#F0FDF4",borderRadius:13,padding:"14px 16px",border:"2px solid #BBF7D0",textAlign:"left"}}>
                  <span style={{fontSize:28}}>{joinCodeSuccess.avatar}</span>
                  <div style={{flex:1}}>
                    <p style={{margin:0,fontWeight:700,fontSize:15,color:L.text}}>{joinCodeSuccess.name}</p>
                    <p style={{margin:0,fontSize:12,color:L.sub}}>{joinCodeSuccess.relation}</p>
                  </div>
                  <span style={{fontSize:10,fontWeight:700,padding:"4px 12px",borderRadius:99,background:"#DCFCE7",color:L.green,textTransform:"uppercase",letterSpacing:"0.05em"}}>● Active</span>
                </div>
              </div>
            ):(
              <>
                <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:20}}>
                  <div>
                    <h2 style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:22,fontWeight:700,margin:"0 0 2px",color:L.text,letterSpacing:"-0.3px"}}>Join as Caregiver</h2>
                    <p style={{margin:0,fontSize:12,color:L.sub}}>Scan a unique QR code or enter invite code</p>
                  </div>
                  <button onClick={()=>{setJoinCodeModal(false);setJoinQRScanState("idle");}} style={{background:L.bg,border:"none",borderRadius:10,width:34,height:34,cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center"}}><Ic d={ic.x} size={15} c={L.sub}/></button>
                </div>
                <div style={{display:"flex",gap:4,background:L.bg,borderRadius:14,padding:4,marginBottom:22}}>
                  {[{id:"qr",label:"📷  Scan QR"},{id:"code",label:"🔑  Enter Code"}].map(t=>(
                    <button key={t.id} onClick={()=>{setJoinTab(t.id);setJoinCodeError("");setJoinQRScanState("idle");}}
                      style={{flex:1,padding:"11px",background:joinTab===t.id?L.card:"transparent",border:"none",borderRadius:10,fontSize:13,fontWeight:700,color:joinTab===t.id?L.text:L.sub,cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",transition:"all 0.2s",boxShadow:joinTab===t.id?"0 2px 8px rgba(0,0,0,0.09)":"none"}}>
                      {t.label}
                    </button>
                  ))}
                </div>
                {joinTab==="qr"&&(
                  <div>
                    {pendingCount===0?(
                      <div style={{textAlign:"center",padding:"28px 0"}}>
                        <span style={{fontSize:44}}>📋</span>
                        <p style={{fontWeight:700,fontSize:15,color:L.text,margin:"12px 0 6px"}}>No pending caregivers</p>
                        <p style={{fontSize:13,color:L.sub,margin:0,lineHeight:1.5}}>Add a caregiver first — each gets a unique, auto-generated QR code.</p>
                      </div>
                    ):(
                      <>
                        <p style={{fontSize:12,color:L.sub,margin:"0 0 14px",lineHeight:1.5}}>Each caregiver has a <strong style={{color:L.text}}>unique auto-generated QR code</strong>. Tap below to simulate scanning.</p>
                        <div style={{display:"flex",flexDirection:"column",gap:14}}>
                          {caregivers.filter(c=>c.status==="pending").map(cg=>{
                            const invUrl=genInviteUrl(cg.id);
                            const invCode=genInviteCode(cg.id);
                            return(
                              <div key={cg.id} style={{background:L.bg,borderRadius:14,padding:"18px",border:`2px solid ${joinQRScanState==="done"?L.green:L.border}`,position:"relative",overflow:"hidden"}}>
                                {joinQRScanState==="scanning"&&(
                                  <div style={{position:"absolute",inset:0,background:"rgba(255,255,255,0.93)",borderRadius:13,display:"flex",flexDirection:"column",alignItems:"center",justifyContent:"center",gap:12,zIndex:10}}>
                                    <div style={{width:52,height:52,border:`3px solid ${L.green}`,borderTopColor:"transparent",borderRadius:"50%",animation:"spin 0.8s linear infinite"}}/>
                                    <p style={{margin:0,fontWeight:700,fontSize:15,color:L.text}}>Reading QR code…</p>
                                    <p style={{margin:0,fontSize:12,color:L.sub}}>Verifying {cg.name}'s unique invite</p>
                                  </div>
                                )}
                                <div style={{display:"flex",alignItems:"center",gap:10,marginBottom:14}}>
                                  <div style={{width:42,height:42,borderRadius:12,background:L.greenLight,display:"flex",alignItems:"center",justifyContent:"center",fontSize:20,flexShrink:0}}>{cg.avatar}</div>
                                  <div style={{flex:1}}>
                                    <p style={{margin:0,fontWeight:700,fontSize:14,color:L.text}}>{cg.name}</p>
                                    <p style={{margin:0,fontSize:11,color:L.sub}}>{cg.relation}</p>
                                  </div>
                                  <span style={{fontSize:9,fontWeight:700,padding:"3px 9px",borderRadius:99,background:"#FEF3C7",color:L.amber,textTransform:"uppercase",letterSpacing:"0.05em"}}>⏳ Pending</span>
                                </div>
                                <div style={{display:"flex",gap:14,alignItems:"flex-start",marginBottom:14}}>
                                  <div style={{flexShrink:0,position:"relative"}}>
                                    <div style={{padding:10,background:"#fff",borderRadius:14,boxShadow:"0 2px 14px rgba(0,0,0,0.1)",border:`1.5px solid ${L.border}`}}>
                                      <QRCode value={invUrl} size={110}/>
                                    </div>
                                    <div style={{position:"absolute",top:-3,left:-3,width:14,height:14,border:`2.5px solid ${L.green}`,borderRight:"none",borderBottom:"none",borderRadius:"3px 0 0 0"}}/>
                                    <div style={{position:"absolute",top:-3,right:-3,width:14,height:14,border:`2.5px solid ${L.green}`,borderLeft:"none",borderBottom:"none",borderRadius:"0 3px 0 0"}}/>
                                    <div style={{position:"absolute",bottom:-3,left:-3,width:14,height:14,border:`2.5px solid ${L.green}`,borderRight:"none",borderTop:"none",borderRadius:"0 0 0 3px"}}/>
                                    <div style={{position:"absolute",bottom:-3,right:-3,width:14,height:14,border:`2.5px solid ${L.green}`,borderLeft:"none",borderTop:"none",borderRadius:"0 0 3px 0"}}/>
                                    {joinQRScanState==="idle"&&<div style={{position:"absolute",left:10,right:10,height:2,background:"rgba(16,185,129,0.5)",animation:"scanLine 2s linear infinite",pointerEvents:"none",borderRadius:99}}/>}
                                  </div>
                                  <div style={{flex:1}}>
                                    <p style={{margin:"0 0 3px",fontSize:10,fontWeight:700,color:L.sub,textTransform:"uppercase",letterSpacing:"0.07em"}}>Unique Code</p>
                                    <p style={{margin:"0 0 6px",fontSize:17,fontWeight:700,color:L.text,letterSpacing:"0.1em",fontFamily:"monospace"}}>{invCode}</p>
                                    <p style={{margin:"0 0 10px",fontSize:11,color:L.sub,lineHeight:1.4}}>Auto-generated & unique to {cg.name}</p>
                                    <button onClick={()=>copyInvite(invUrl)} style={{padding:"6px 11px",background:copiedId===invUrl?"#DCFCE7":L.card,border:`1px solid ${copiedId===invUrl?L.green:L.border}`,borderRadius:9,fontSize:11,fontWeight:700,color:copiedId===invUrl?L.green:L.sub,cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",transition:"all 0.2s"}}>
                                      {copiedId===invUrl?"✓ Copied":"📋 Copy Link"}
                                    </button>
                                  </div>
                                </div>
                                <button onClick={()=>joinViaQR(cg.id)} disabled={joinQRScanState!=="idle"}
                                  style={{width:"100%",padding:"14px",background:joinQRScanState==="idle"?L.green:L.greenLight,border:"none",borderRadius:14,fontSize:14,fontWeight:700,color:joinQRScanState==="idle"?"#fff":L.green,cursor:joinQRScanState==="idle"?"pointer":"default",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",display:"flex",alignItems:"center",justifyContent:"center",gap:8,transition:"all 0.3s"}}>
                                  {joinQRScanState==="idle"&&<><Ic d={ic.camera} size={16} c="#fff"/> Simulate: Caregiver Scans This QR</>}
                                  {joinQRScanState==="scanning"&&<><span style={{animation:"spin 0.9s linear infinite",display:"inline-block"}}>⟳</span> Scanning…</>}
                                  {joinQRScanState==="done"&&<>✅ Activated!</>}
                                </button>
                              </div>
                            );
                          })}
                        </div>
                      </>
                    )}
                  </div>
                )}
                {joinTab==="code"&&(
                  <div>
                    <div style={{background:L.bg,borderRadius:14,padding:"12px 14px",marginBottom:16,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)"}}>
                      <p style={{margin:0,fontSize:13,color:"rgba(60,60,67,0.6)",lineHeight:1.5}}>📱 Caregiver taps <strong style={{color:L.purple}}>"Join as Caregiver"</strong> in their app and types the MT-XXXXXX code you shared.</p>
                    </div>
                    <input value={joinCodeInput} onChange={e=>{setJoinCodeInput(e.target.value.toUpperCase());setJoinCodeError("");}} placeholder="MT-A1B2C3"
                      style={{width:"100%",padding:"16px 14px",background:L.bg,border:`1.5px solid ${joinCodeError?L.red:joinCodeInput?L.purple:L.border}`,borderRadius:14,fontSize:18,color:L.text,outline:"none",fontFamily:"monospace",letterSpacing:"0.12em",fontWeight:700,boxSizing:"border-box",marginBottom:10,transition:"border-color 0.2s",textTransform:"uppercase",textAlign:"center"}}/>
                    {joinCodeError&&<p style={{color:L.red,fontSize:12,margin:"-2px 0 10px",fontWeight:600}}>⚠️ {joinCodeError}</p>}
                    {pendingCount>0&&(
                      <div style={{marginBottom:16}}>
                        <p style={{fontSize:11,fontWeight:700,color:L.sub,textTransform:"uppercase",letterSpacing:"0.07em",margin:"0 0 8px"}}>Tap to autofill code</p>
                        {caregivers.filter(c=>c.status==="pending").map(c=>(
                          <div key={c.id} onClick={()=>setJoinCodeInput(genInviteCode(c.id))}
                            style={{display:"flex",alignItems:"center",gap:12,background:joinCodeInput===genInviteCode(c.id)?L.purpleLight:L.bg,borderRadius:12,padding:"12px 14px",border:`1.5px solid ${joinCodeInput===genInviteCode(c.id)?L.purple:L.border}`,cursor:"pointer",marginBottom:6,transition:"all 0.15s"}}>
                            <span style={{fontSize:22}}>{c.avatar}</span>
                            <div style={{flex:1}}>
                              <p style={{margin:0,fontWeight:700,fontSize:13,color:L.text}}>{c.name}</p>
                              <p style={{margin:0,fontSize:12,color:L.purple,fontWeight:700,fontFamily:"monospace",letterSpacing:"0.07em"}}>{genInviteCode(c.id)}</p>
                            </div>
                            <span style={{fontSize:10,color:L.sub,fontWeight:600}}>autofill →</span>
                          </div>
                        ))}
                      </div>
                    )}
                    <button onClick={joinViaCode} disabled={!joinCodeInput.trim()}
                      style={{width:"100%",padding:"16px",background:joinCodeInput.trim()?L.purple:"#DDD6FE",border:"none",borderRadius:16,fontSize:15,fontWeight:700,color:"#fff",cursor:joinCodeInput.trim()?"pointer":"default",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",transition:"all 0.2s"}}>
                      Activate Caregiver ✓
                    </button>
                  </div>
                )}
              </>
            )}
          </div>
        </div>
      )}

      {/* Empty state */}
      {caregivers.length===0&&(
        <div style={{background:"linear-gradient(135deg,#EDE9FE,#DBEAFE)",borderRadius:16,padding:"24px 20px",marginBottom:20,border:"1px solid #C4B5FD",textAlign:"center"}}>
          <div style={{fontSize:52,marginBottom:14}}>👨‍👩‍👧</div>
          <h2 style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:20,fontWeight:700,color:"#1E1B4B",margin:"0 0 8px"}}>Caregiver Alerts</h2>
          <p style={{color:"#4338CA",fontSize:14,lineHeight:1.6,margin:"0 0 20px"}}>Add a family member. They'll get a QR code invite — scan once and they monitor your doses automatically.</p>
          <div style={{display:"flex",flexDirection:"column",gap:8,textAlign:"left",marginBottom:20}}>
            {[["📋","Fill in their details","Name, relationship & phone"],["📱","They scan a QR code","No app download required to accept"],["⚠️","Miss a dose?","They get an alert with full escalation context"]].map(([e,t,d],i)=>(
              <div key={i} style={{display:"flex",alignItems:"center",gap:12,background:"rgba(255,255,255,0.7)",borderRadius:13,padding:"12px 14px"}}>
                <span style={{fontSize:22,minWidth:28}}>{e}</span>
                <div><p style={{margin:0,fontWeight:700,fontSize:13,color:"#1E1B4B"}}>{t}</p><p style={{margin:0,fontSize:12,color:"#6366F1"}}>{d}</p></div>
              </div>
            ))}
          </div>
          <button onClick={()=>{setView("add");setAddStep(1);}} style={{width:"100%",padding:"15px",background:"#4F46E5",border:"none",borderRadius:14,fontSize:15,fontWeight:700,color:"#fff",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif"}}>
            Add First Caregiver →
          </button>
        </div>
      )}

      {/* Stats */}
      {caregivers.length>0&&(
        <div style={{display:"grid",gridTemplateColumns:"1fr 1fr 1fr",gap:10,marginBottom:20}}>
          {[{e:"👥",v:activeCount,l:"Active",c:L.green,bg:L.greenLight},{e:"⏳",v:pendingCount,l:"Pending",c:L.amber,bg:"#FEF3C7"},{e:"⚠️",v:missedAlerts.length,l:"Alerts",c:L.red,bg:L.redLight}].map((s,i)=>(
            <div key={i} style={{background:L.card,borderRadius:16,padding:"14px 10px",boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)",textAlign:"center"}}>
              <span style={{fontSize:20}}>{s.e}</span>
              <p style={{margin:"6px 0 2px",fontSize:22,fontWeight:700,color:s.c,letterSpacing:"-0.5px"}}>{s.v}</p>
              <p style={{margin:0,fontSize:10,fontWeight:700,color:L.sub,textTransform:"uppercase",letterSpacing:"0.04em"}}>{s.l}</p>
            </div>
          ))}
        </div>
      )}

      {/* Caregivers */}
      {caregivers.length>0&&(
        <section style={{marginBottom:24}}>
          <Lbl>Caregivers</Lbl>
          <div style={{display:"flex",flexDirection:"column",gap:10}}>
            {caregivers.map(cg=>(
              <CaregiverCard key={cg.id} cg={cg} meds={meds} copiedId={copiedId}
                inviteUrl={genInviteUrl(cg.id)} inviteCode={genInviteCode(cg.id)}
                expanded={expandedId===cg.id} onExpand={()=>setExpandedId(expandedId===cg.id?null:cg.id)}
                onCopy={()=>copyInvite(genInviteUrl(cg.id))}
                onActivate={()=>activateCaregiver(cg.id)}
                onRemove={()=>removeCaregiver(cg.id)}
                onDashboard={()=>{setDashCg(cg);setView("dashboard");}}/>
            ))}
          </div>
        </section>
      )}

      {/* Escalation info card */}
      <section style={{marginBottom:20}}>
        <div style={{background:L.card,borderRadius:14,padding:"16px 18px",boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)"}}>
          <div style={{display:"flex",alignItems:"center",gap:10,marginBottom:14}}>
            <div style={{width:36,height:36,borderRadius:10,background:"#FEF3C7",display:"flex",alignItems:"center",justifyContent:"center"}}>
              <Ic d={ic.clock} size={17} c={L.amber}/>
            </div>
            <div style={{flex:1}}>
              <p style={{margin:0,fontWeight:700,fontSize:14,color:L.text}}>Escalation Logic</p>
              <p style={{margin:0,fontSize:12,color:L.sub}}>Reminder → Snooze → Missed → Alert</p>
            </div>
            <button onClick={()=>setView("escalation-demo")}
              style={{fontSize:12,fontWeight:700,color:L.blue,background:L.blueLight,border:"none",borderRadius:99,padding:"6px 12px",cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",flexShrink:0}}>
              See demo
            </button>
          </div>
          {/* Mini escalation timeline */}
          <div style={{display:"flex",alignItems:"center",gap:0}}>
            {[{icon:"🔔",label:"Remind",color:L.blue},{icon:"😴",label:"Snooze",color:L.amber},{icon:"❌",label:"Missed",color:"#F97316"},{icon:"⚠️",label:"Alert",color:L.red}].map((s,i,arr)=>(
              <React.Fragment key={i}>
                <div style={{display:"flex",flexDirection:"column",alignItems:"center",gap:4,flex:1}}>
                  <div style={{width:36,height:36,borderRadius:99,background:`${s.color}15`,border:`2px solid ${s.color}30`,display:"flex",alignItems:"center",justifyContent:"center",fontSize:16}}>
                    {s.icon}
                  </div>
                  <span style={{fontSize:9,fontWeight:700,color:s.color,textTransform:"uppercase",letterSpacing:"0.04em"}}>{s.label}</span>
                </div>
                {i<arr.length-1&&<div style={{width:16,height:2,background:L.border,flexShrink:0,marginBottom:14}}/>}
              </React.Fragment>
            ))}
          </div>
        </div>
      </section>

      {/* Simulate / test */}
      {activeCount>0&&(
        <section style={{marginBottom:20}}>
          <div style={{background:L.card,borderRadius:13,padding:"16px 18px",boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)"}}>
            <div style={{display:"flex",alignItems:"center",gap:10,marginBottom:12}}>
              <div style={{width:34,height:34,borderRadius:10,background:"#EDE9FE",display:"flex",alignItems:"center",justifyContent:"center"}}>
                <Ic d={ic.sparkle} size={15} c={L.purple}/>
              </div>
              <div>
                <p style={{margin:0,fontWeight:700,fontSize:14,color:L.text}}>Test the alert system</p>
                <p style={{margin:0,fontSize:12,color:L.sub}}>Simulate a missed dose to preview the full escalation</p>
              </div>
            </div>
            <button onClick={simulateMiss} disabled={simulating}
              style={{width:"100%",padding:"12px",background:simulating?"#F0FDF4":"#EDE9FE",border:"none",borderRadius:12,fontSize:13,fontWeight:700,color:simulating?L.green:L.purple,cursor:simulating?"default":"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",display:"flex",alignItems:"center",justifyContent:"center",gap:8,transition:"all 0.3s"}}>
              {simulating?<><span style={{display:"inline-block",animation:"spin 1s linear infinite"}}>⚡</span> Sending escalation...</>:<><Ic d={ic.bell} size={14} c={L.purple}/> Simulate Missed Dose</>}
            </button>
          </div>
        </section>
      )}

      {/* Alert log */}
      {missedAlerts.length>0&&(
        <section style={{marginBottom:28}}>
          <div style={{display:"flex",alignItems:"center",justifyContent:"space-between",marginBottom:10}}>
            <Lbl>Alert Log</Lbl>
          </div>
          <div style={{display:"flex",flexDirection:"column",gap:8}}>
            {missedAlerts.map(alert=>(
              <div key={alert.id} onClick={()=>setShowAlertDetail(alert)}
                style={{background:L.card,borderRadius:16,padding:"13px 16px",border:"1.5px solid "+(!alert.seen?L.red+"50":L.border),display:"flex",alignItems:"flex-start",gap:12,cursor:"pointer",transition:"all 0.15s",position:"relative"}}>
                {!alert.seen&&<div style={{position:"absolute",top:13,right:14,width:7,height:7,borderRadius:99,background:L.red}}/>}
                <div style={{width:38,height:38,borderRadius:11,background:L.redLight,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0,marginTop:1}}>
                  <Ic d={ic.alertTri} size={17} c={L.red}/>
                </div>
                <div style={{flex:1,minWidth:0}}>
                  <p style={{margin:"0 0 2px",fontWeight:700,fontSize:14,color:L.text}}>{alert.medName}</p>
                  <p style={{margin:0,fontSize:12,color:L.sub}}>Missed {alert.doseLabel} at {alert.time} · {alert.caregivers?.length||1} notified</p>
                  <p style={{margin:"3px 0 0",fontSize:11,color:L.sub}}>{alert.timestamp}</p>
                </div>
                <Ic d={ic.back} size={14} c={L.sub} style={{transform:"rotate(180deg)",marginTop:4,flexShrink:0}}/>
              </div>
            ))}
          </div>
        </section>
      )}

      {missedAlerts.length===0&&activeCount>0&&(
        <div style={{background:"#F0FDF4",borderRadius:14,padding:"20px",border:"1px solid #BBF7D0",textAlign:"center",marginBottom:28}}>
          <span style={{fontSize:32}}>✅</span>
          <p style={{margin:"8px 0 4px",fontWeight:700,fontSize:15,color:L.green}}>No alerts sent!</p>
          <p style={{margin:0,fontSize:13,color:L.sub}}>All doses taken on time. Keep it up!</p>
        </div>
      )}

      {showAlertDetail&&(
        <AlertDetailModal alert={showAlertDetail} caregivers={caregivers} profile={profile} onClose={()=>setShowAlertDetail(null)}/>
      )}
    </div>
  );
}

/* ── Caregiver Card ── */
function CaregiverCard({cg,meds,copiedId,inviteUrl,inviteCode,expanded,onExpand,onCopy,onActivate,onRemove,onDashboard}) {
  const isActive=cg.status==="active", isPending=cg.status==="pending";
  const L=useTheme();
  return(
    <div style={{background:L.card,borderRadius:14,border:`1.5px solid ${isActive?L.green+"45":L.border}`,overflow:"hidden",boxShadow:isActive?"0 2px 12px rgba(16,185,129,0.07)":"none"}}>
      {/* Header */}
      <div style={{padding:"16px 16px 14px",display:"flex",alignItems:"center",gap:12,cursor:"pointer"}} onClick={onExpand}>
        <div style={{width:50,height:50,borderRadius:16,background:`${cg.color}15`,border:`2px solid ${cg.color}25`,display:"flex",alignItems:"center",justifyContent:"center",flexShrink:0,fontSize:26}}>
          {cg.avatar}
        </div>
        <div style={{flex:1,minWidth:0}}>
          <div style={{display:"flex",alignItems:"center",gap:7,flexWrap:"wrap"}}>
            <p style={{margin:0,fontWeight:700,fontSize:15,color:L.text}}>{cg.name}</p>
            <span style={{fontSize:9,fontWeight:700,padding:"2px 8px",borderRadius:99,letterSpacing:"0.04em",background:isActive?L.greenLight:isPending?"#FEF3C7":L.bg,color:isActive?L.green:isPending?L.amber:L.sub,textTransform:"uppercase"}}>
              {isActive?"Active":isPending?"Awaiting":"Inactive"}
            </span>
          </div>
          <p style={{margin:"2px 0 0",fontSize:12,color:L.sub}}>{cg.relation}{cg.contact&&` · ${cg.contact}`}</p>
        </div>
        <div style={{color:L.sub,fontSize:18,transform:expanded?"rotate(90deg)":"none",transition:"transform 0.2s",flexShrink:0}}>›</div>
      </div>

      {/* Expanded */}
      {expanded&&(
        <div style={{padding:"0 16px 16px",borderTop:`1px solid ${L.border}`}}>
          {/* QR Code for pending */}
          {isPending&&(
            <>
              <p style={{margin:"14px 0 10px",fontSize:11,fontWeight:700,letterSpacing:"0.07em",textTransform:"uppercase",color:L.sub}}>Invite — show QR to {cg.name}</p>
              <div style={{display:"flex",gap:14,alignItems:"flex-start",marginBottom:14}}>
                <div style={{background:"#fff",padding:10,borderRadius:14,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)",flexShrink:0}}>
                  <QRCode value={inviteUrl} size={100}/>
                </div>
                <div style={{flex:1}}>
                  <p style={{margin:"0 0 4px",fontSize:11,fontWeight:700,color:L.sub,textTransform:"uppercase",letterSpacing:"0.06em"}}>Code</p>
                  <p style={{margin:"0 0 8px",fontSize:17,fontWeight:700,color:L.text,letterSpacing:"0.1em"}}>{inviteCode}</p>
                  <p style={{margin:0,fontSize:11,color:L.sub,lineHeight:1.4}}>{cg.name} opens MedTrackAI and scans this to join</p>
                </div>
              </div>
            </>
          )}

          {/* Active: monitoring list */}
          {isActive&&meds.length>0&&(
            <>
              <p style={{margin:"14px 0 8px",fontSize:11,fontWeight:700,letterSpacing:"0.07em",textTransform:"uppercase",color:L.sub}}>Monitoring</p>
              <div style={{display:"flex",gap:6,flexWrap:"wrap",marginBottom:14}}>
                {meds.map(m=>(
                  <span key={m.id} style={{padding:"5px 10px",background:L.greenLight,borderRadius:99,fontSize:11,fontWeight:700,color:L.green}}>{m.name}</span>
                ))}
              </div>
            </>
          )}

          {/* Actions */}
          <div style={{display:"flex",gap:8,flexWrap:"wrap"}}>
            {isActive&&(
              <button onClick={onDashboard}
                style={{flex:2,padding:"10px",background:L.blue+"15",border:"none",borderRadius:11,fontSize:13,fontWeight:500,color:L.blue,cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",display:"flex",alignItems:"center",justifyContent:"center",gap:5}}>
                <Ic d={ic.chart} size={13} c={L.green}/> View Dashboard
              </button>
            )}
            {isPending&&(
              <>
                <button onClick={onCopy} style={{flex:1,padding:"10px",background:copiedId===inviteUrl?"#F0FDF4":L.bg,border:`1px solid ${copiedId===inviteUrl?L.green:L.border}`,borderRadius:11,fontSize:12,fontWeight:700,color:copiedId===inviteUrl?L.green:L.sub,cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",display:"flex",alignItems:"center",justifyContent:"center",gap:4}}>
                  {copiedId===inviteUrl?"✓ Copied":"📋 Resend Link"}
                </button>
                <div style={{flex:2,padding:"10px 12px",background:"#FEF3C7",border:"1px solid #FCD34D",borderRadius:11,fontSize:11,fontWeight:700,color:"#92400E",display:"flex",alignItems:"center",justifyContent:"center",gap:5}}>
                  ⏳ Awaiting QR scan
                </div>
              </>
            )}
            <button onClick={onRemove} style={{padding:"10px 13px",background:L.redLight,border:"none",borderRadius:11,fontSize:13,fontWeight:500,color:L.red,cursor:"pointer",fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",display:"flex",alignItems:"center",justifyContent:"center"}}>
              <Ic d={ic.trash} size={13} c={L.red}/>
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

/* ── Alert Detail Modal ── */
function AlertDetailModal({alert,caregivers,profile,onClose}) {
  const L=useTheme();
  return(
    <div style={{position:"fixed",inset:0,background:"rgba(0,0,0,0.4)",zIndex:600,display:"flex",alignItems:"flex-end",justifyContent:"center",backdropFilter:"blur(24px) saturate(160%)",WebkitBackdropFilter:"blur(24px) saturate(160%)"}}>
      <div style={{background:L.card,borderRadius:"20px 20px 0 0",padding:"24px 24px 48px",width:"100%",maxWidth:430,animation:"slideInUp 0.35s cubic-bezier(0.34,1.56,0.64,1) forwards",maxHeight:"85vh",overflowY:"auto"}}>
        <div style={{display:"flex",justifyContent:"space-between",alignItems:"center",marginBottom:20}}>
          <h2 style={{fontFamily:"'Figtree',-apple-system,'Helvetica Neue',sans-serif",fontSize:20,fontWeight:700,margin:0,color:L.text,letterSpacing:"-0.3px"}}>Alert Detail</h2>
          <button onClick={onClose} style={{background:L.bg,border:"none",borderRadius:10,width:34,height:34,cursor:"pointer",display:"flex",alignItems:"center",justifyContent:"center"}}><Ic d={ic.x} size={15} c={L.sub}/></button>
        </div>
        <div style={{background:L.redLight,borderRadius:13,padding:"14px 16px",marginBottom:16,border:"1px solid #FCA5A5"}}>
          <div style={{display:"flex",alignItems:"center",gap:10}}>
            <span style={{fontSize:26}}>⚠️</span>
            <div>
              <p style={{margin:0,fontWeight:700,fontSize:16,color:L.red}}>{alert.medName}</p>
              <p style={{margin:"2px 0 0",fontSize:13,color:L.sub}}>Missed {alert.doseLabel} at {alert.time}</p>
            </div>
          </div>
        </div>
        {/* Escalation */}
        <p style={{margin:"0 0 12px",fontSize:11,fontWeight:700,letterSpacing:"0.07em",textTransform:"uppercase",color:L.sub}}>Escalation path</p>
        <div style={{marginBottom:20}}>
          <EscalationTimeline steps={alert.escalation} activeStep={4}/>
        </div>
        {/* Who was notified */}
        <p style={{margin:"0 0 10px",fontSize:11,fontWeight:700,letterSpacing:"0.07em",textTransform:"uppercase",color:L.sub}}>Caregivers notified</p>
        {(alert.caregivers||[]).map((cg,i)=>(
          <div key={i} style={{display:"flex",alignItems:"center",gap:12,background:L.bg,borderRadius:14,padding:"12px 14px",marginBottom:8,boxShadow:"inset 0 -0.5px 0 rgba(60,60,67,0.2)"}}>
            <span style={{fontSize:22}}>{cg.avatar}</span>
            <div style={{flex:1}}><p style={{margin:0,fontWeight:700,fontSize:14,color:L.text}}>{cg.name}</p><p style={{margin:0,fontSize:12,color:L.sub}}>{cg.contact||cg.relation}</p></div>
            <span style={{fontSize:11,fontWeight:700,color:L.green,background:L.greenLight,padding:"3px 10px",borderRadius:99}}>✓ Sent</span>
          </div>
        ))}
        {/* Message */}
        <p style={{margin:"14px 0 10px",fontSize:11,fontWeight:700,letterSpacing:"0.07em",textTransform:"uppercase",color:L.sub}}>Message sent</p>
        <div style={{background:"#1C1917",borderRadius:16,padding:"14px 16px"}}>
          <p style={{margin:0,fontSize:14,color:"#FEF2F2",lineHeight:1.7}}>
            ⚠️ <strong style={{color:"#fff"}}>{profile?.name||"Your family member"}</strong> missed their <strong style={{color:"#FCA5A5"}}>{alert.doseLabel} dose of {alert.medName}</strong> at {alert.time}.<br/>
            Please check on them. 🙏
          </p>
        </div>
        <p style={{textAlign:"center",color:L.sub,fontSize:12,margin:"10px 0 0"}}>{alert.timestamp}</p>
      </div>
    </div>
  );
}
