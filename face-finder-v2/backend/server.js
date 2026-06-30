const express = require("express");
const multer = require("multer");
const axios = require("axios");
const FormData = require("form-data");
const cheerio = require("cheerio");
const fs = require("fs");
const cors = require("cors");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(express.json({ limit: "50mb" }));

const upload = multer({ dest: "uploads/" });

const SOCIAL_DOMAINS = {
  "instagram.com": { name: "Instagram", icon: "camera.viewfinder", color: "#E4405F" },
  "tiktok.com": { name: "TikTok", icon: "music.note", color: "#000000" },
  "facebook.com": { name: "Facebook", icon: "f.square", color: "#1877F2" },
  "fb.com": { name: "Facebook", icon: "f.square", color: "#1877F2" },
  "twitter.com": { name: "Twitter / X", icon: "bird", color: "#1DA1F2" },
  "x.com": { name: "X (Twitter)", icon: "xmark", color: "#000000" },
  "snapchat.com": { name: "Snapchat", icon: "ghost", color: "#FFFC00" },
  "linkedin.com": { name: "LinkedIn", icon: "link", color: "#0A66C2" },
  "youtube.com": { name: "YouTube", icon: "play.rectangle", color: "#FF0000" },
  "reddit.com": { name: "Reddit", icon: "bubble.left", color: "#FF4500" },
  "pinterest.com": { name: "Pinterest", icon: "pin", color: "#BD081C" },
  "onlyfans.com": { name: "OnlyFans", icon: "lock", color: "#00AFF0" },
  "github.com": { name: "GitHub", icon: "chevron.left.forwardslash.chevron.right", color: "#333" },
  "discord.com": { name: "Discord", icon: "bubble.left.and.bubble.right", color: "#5865F2" },
  "discord.gg": { name: "Discord", icon: "bubble.left.and.bubble.right", color: "#5865F2" },
  "telegram.org": { name: "Telegram", icon: "paperplane", color: "#26A5E4" },
  "t.me": { name: "Telegram", icon: "paperplane", color: "#26A5E4" },
  "twitch.tv": { name: "Twitch", icon: "tv", color: "#9146FF" },
  "patreon.com": { name: "Patreon", icon: "heart", color: "#FF424D" },
  "threads.net": { name: "Threads", icon: "at", color: "#000000" },
  "whatsapp.com": { name: "WhatsApp", icon: "message", color: "#25D366" },
  "tinder.com": { name: "Tinder", icon: "flame", color: "#FF6B6B" },
  "bumble.com": { name: "Bumble", icon: "circle.hexagongrid", color: "#FFC000" },
  "hinge.co": { name: "Hinge", icon: "heart.circle", color: "#FF4B4B" },
  "medium.com": { name: "Medium", icon: "square", color: "#000000" },
  "tumblr.com": { name: "Tumblr", icon: "t.circle", color: "#36465D" },
  "flickr.com": { name: "Flickr", icon: "camera", color: "#0063DC" },
  "vsco.co": { name: "VSCO", icon: "camera.aperture", color: "#000000" },
  "behance.net": { name: "Behance", icon: "square.grid.3x3", color: "#1769FF" },
  "dribbble.com": { name: "Dribbble", icon: "circle.dotted", color: "#EA4C89" },
  "vk.com": { name: "VK", icon: "v.circle", color: "#4C75A3" },
  "weibo.com": { name: "Weibo", icon: "w.circle", color: "#E6162D" },
  "xiaohongshu.com": { name: "Xiaohongshu", icon: "book", color: "#FF2442" },
};

const USER_AGENTS = [
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/125.0.0.0 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 Safari/605.1.15",
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/125.0.0.0 Safari/537.36",
];

function randomUA() { return USER_AGENTS[Math.floor(Math.random() * USER_AGENTS.length)]; }
function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

function extractUsername(url) {
  try {
    const u = new URL(url);
    const parts = u.pathname.replace(/\/$/, "").split("/").filter(Boolean);
    const h = u.hostname;
    if (h.includes("instagram.com") && parts[0]) return "@" + parts[0];
    if (h.includes("tiktok.com")) return parts[0]?.startsWith("@") ? parts[0] : "@" + (parts[0] || "");
    if ((h.includes("twitter.com") || h.includes("x.com")) && parts[0]) return "@" + parts[0];
    if (h.includes("github.com") && parts[0]) return parts[0];
    if (h.includes("reddit.com") && parts[0] === "user" && parts[1]) return "u/" + parts[1];
    if (h.includes("youtube.com") && parts[0]?.startsWith("@")) return parts[0];
    if (h.includes("t.me") && parts[0]) return "@" + parts[0];
    if (h.includes("twitch.tv") && parts[0]) return parts[0];
    if (h.includes("linkedin.com") && parts[0] === "in" && parts[1]) return parts[1];
    return null;
  } catch { return null; }
}

function extractNameFromUrl(url) {
  try {
    const u = new URL(url);
    const parts = u.pathname.replace(/\/$/, "").split("/").filter(Boolean);
    const h = u.hostname;
    if (h.includes("linkedin.com") && parts[0] === "in" && parts[1]) return parts[1].replace(/-/g, " ");
    if (h.includes("instagram.com") && parts[0]) return parts[0];
    if (h.includes("tiktok.com") && parts[0]) return parts[0].replace("@", "");
    if (h.includes("facebook.com") && parts[0]) return parts[0].replace(/\./g, " ");
    if (h.includes("twitter.com") && parts[0]) return parts[0];
    return null;
  } catch { return null; }
}

function classifySocialProfiles(urls) {
  const profiles = []; const seen = new Set();
  for (const item of urls) {
    const srcUrl = item.url || "";
    if (!srcUrl || seen.has(srcUrl)) continue; seen.add(srcUrl);
    const match = Object.entries(SOCIAL_DOMAINS).find(([d]) => srcUrl.toLowerCase().includes(d));
    if (match) profiles.push({
      platform: match[1].name, icon: match[1].icon, color: match[1].color,
      url: srcUrl, username: extractUsername(srcUrl), confidence: item.confidence || 50,
    });
  }
  return profiles;
}

// === YANDEX REVERSE IMAGE SEARCH ===
async function searchYandex(imagePath) {
  try {
    const form = new FormData();
    form.append("upfile", fs.createReadStream(imagePath), { filename: "photo.jpg", contentType: "image/jpeg" });
    form.append("rpt", "imageview");

    const res = await axios.post("https://yandex.com/images/search", form, {
      headers: { "User-Agent": randomUA(), Accept: "text/html", ...form.getHeaders() },
      maxRedirects: 5, timeout: 15000,
    });

    const $ = cheerio.load(res.data);
    const results = []; const urls = new Set();
    $("a[href]").each((_, el) => {
      let href = $(el).attr("href") || "";
      if (href.startsWith("//")) href = "https:" + href;
      if (href.startsWith("http") && !href.includes("yandex") && !urls.has(href)) {
        urls.add(href); results.push({ url: href, confidence: 55 });
      }
    });

    const scripts = $("script").text();
    const found = scripts.match(/https?:\/\/[^\s"'<>]+/g) || [];
    for (const u of found) {
      if (!urls.has(u)) { urls.add(u); results.push({ url: u, confidence: 45 }); }
    }
    return results;
  } catch (err) { console.error("Yandex error:", err.message); return []; }
}

// === GOOGLE REVERSE IMAGE SEARCH ===
async function searchGoogle(imagePath) {
  try {
    const form = new FormData();
    form.append("encoded_image", fs.createReadStream(imagePath), { filename: "photo.jpg", contentType: "image/jpeg" });
    form.append("image_content", ""); form.append("filename", "photo.jpg");

    const res = await axios.post("https://www.google.com/searchbyimage/upload", form, {
      headers: { "User-Agent": randomUA(), Accept: "text/html", ...form.getHeaders() },
      maxRedirects: 0, validateStatus: s => s < 400 || s === 302, timeout: 20000,
    });

    const $ = cheerio.load(res.data); const results = []; const urls = new Set();
    $("a[href]").each((_, el) => {
      let href = $(el).attr("href") || "";
      if (href.startsWith("/url?q=")) href = decodeURIComponent(href.replace("/url?q=", "").split("&")[0]);
      if (href.startsWith("http") && !href.includes("google.com") && !urls.has(href)) {
        urls.add(href); results.push({ url: href, confidence: 50 });
      }
    });

    const scripts = $("script").text();
    const found = scripts.match(/"https?:\/\/[^"]+"/g) || [];
    for (const m of found) {
      const u = m.replace(/"/g, "");
      if (!urls.has(u) && !u.includes("google") && !u.includes("gstatic")) {
        urls.add(u); results.push({ url: u, confidence: 40 });
      }
    }
    return results;
  } catch (err) { console.error("Google error:", err.message); return []; }
}

// === BING VISUAL SEARCH ===
async function searchBing(imagePath) {
  const apiKey = process.env.BING_API_KEY;
  if (!apiKey) return [];
  try {
    const buf = fs.readFileSync(imagePath);
    const res = await axios.post("https://api.bing.microsoft.com/v7.0/images/visualSearch", buf, {
      headers: { "Ocp-Apim-Subscription-Key": apiKey, "Content-Type": "multipart/form-data" },
      params: { mkt: "en-US", safeSearch: "Off" }, timeout: 15000,
    });

    const results = []; const urls = new Set();
    for (const tag of res.data.tags || []) {
      for (const action of tag.actions || []) {
        for (const v of action.data?.value || []) {
          if (v.hostPageUrl && !urls.has(v.hostPageUrl)) {
            urls.add(v.hostPageUrl); results.push({ url: v.hostPageUrl, confidence: Math.round((tag.confidence || 0.5) * 100) });
          }
        }
      }
    }
    return results;
  } catch (err) { console.error("Bing error:", err.message); return []; }
}

// === CRIMINAL RECORDS SEARCH ===
const CRIMINAL_SITES = [
  { name: "Family Watchdog", domain: "familywatchdog.us", type: "Sex Offender" },
  { name: "NSOPW", domain: "nsopw.gov", type: "Sex Offender" },
  { name: "Mugshots.com", domain: "mugshots.com", type: "Arrest Record" },
  { name: "Busted Newspaper", domain: "bustednewspaper.com", type: "Mugshot" },
  { name: "Arrests.org", domain: "arrests.org", type: "Arrest Record" },
  { name: "Vinelink", domain: "vinelink.com", type: "Inmate Status" },
  { name: "JailBase", domain: "jailbase.com", type: "Arrest Record" },
];

async function searchCriminalRecords(name, urls) {
  if (!name || name.length < 2) return [];
  const results = []; const seen = new Set();

  for (const site of CRIMINAL_SITES) {
    if (urls.some(u => u.toLowerCase().includes(site.domain))) {
      const url = urls.find(u => u.toLowerCase().includes(site.domain));
      if (url && !seen.has(url)) { seen.add(url); results.push({ source: site.name, type: site.type, url, confidence: 60 }); }
    }
  }

  // Search Google for name + arrest/mugshot
  try {
    const q = encodeURIComponent(`${name} arrested mugshot inmate`);
    const res = await axios.get(`https://www.google.com/search?q=${q}&hl=en`, {
      headers: { "User-Agent": randomUA(), "Accept-Language": "en-US,en;q=0.9" },
      timeout: 10000,
    });
    const $ = cheerio.load(res.data);
    $("a[href]").each((_, el) => {
      let href = $(el).attr("href") || "";
      if (href.startsWith("/url?q=")) href = decodeURIComponent(href.replace("/url?q=", "").split("&")[0]);
      if (href.startsWith("http") && !href.includes("google.com")) {
        const matched = CRIMINAL_SITES.find(s => href.includes(s.domain));
        if (matched && !seen.has(href)) {
          seen.add(href);
          results.push({ source: matched.name, type: matched.type, url: href, confidence: 45 });
        }
      }
    });
  } catch {}

  return results;
}

// === MAIN SEARCH ENDPOINT ===
app.post("/api/search", upload.single("image"), async (req, res) => {
  let imagePath = req.file?.path;
  if (!imagePath) return res.status(400).json({ error: "No image provided" });

  try {
    const [yandex, google, bing] = await Promise.all([
      searchYandex(imagePath), searchGoogle(imagePath), searchBing(imagePath),
    ]);
    try { fs.unlinkSync(imagePath); } catch {}

    const allUrls = [...yandex, ...google, ...bing];
    const seen = new Set();
    const merged = [];
    for (const item of allUrls) {
      const norm = item.url.replace(/\/$/, "").toLowerCase();
      if (!seen.has(norm)) { seen.add(norm); merged.push(item); }
    }

    const socialProfiles = classifySocialProfiles(merged);
    const otherUrls = merged.filter(m => !Object.keys(SOCIAL_DOMAINS).some(d => m.url.toLowerCase().includes(d))).slice(0, 40);

    // Extract potential names for criminal search
    let names = [];
    for (const p of socialProfiles) {
      const n = extractNameFromUrl(p.url);
      if (n && !names.includes(n.toLowerCase())) names.push(n);
    }
    const nameToSearch = names.length > 0 ? names[0] : null;

    let criminalRecords = [];
    if (nameToSearch) {
      const allSourceUrls = merged.map(m => m.url);
      criminalRecords = await searchCriminalRecords(nameToSearch, allSourceUrls);
    }

    res.json({
      success: true,
      totalMatches: merged.length,
      socialProfiles,
      criminalRecords,
      otherMatches: otherUrls,
    });
  } catch (err) {
    if (imagePath) try { fs.unlinkSync(imagePath); } catch {}
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/health", (req, res) => {
  res.json({
    status: "ok",
    version: "2.0",
    engines: { yandex: true, google: true, bing: !!process.env.BING_API_KEY },
    criminalSearch: true,
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`\n  FaceFinder API v2 running on port ${PORT}`);
  console.log(`  Yandex=OK  Google=OK  Bing=${process.env.BING_API_KEY ? "OK" : "OFF"}`);
  console.log(`  Criminal records search: ENABLED\n`);
});
