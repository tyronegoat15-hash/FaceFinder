const express = require("express");
const multer = require("multer");
const axios = require("axios");
const FormData = require("form-data");
const cheerio = require("cheerio");
const fs = require("fs");
const path = require("path");
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
  "telegram.org": { name: "Telegram", icon: "paperplane", color: "#26A5E4" },
  "twitch.tv": { name: "Twitch", icon: "tv", color: "#9146FF" },
  "patreon.com": { name: "Patreon", icon: "heart", color: "#FF424D" },
  "threads.net": { name: "Threads", icon: "at", color: "#000000" },
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
};

const USER_AGENTS = [
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/125.0.0.0 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 Safari/605.1.15",
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/125.0.0.0 Safari/537.36",
];

function randomUA() { return USER_AGENTS[Math.floor(Math.random() * USER_AGENTS.length)]; }

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

// === NAME-BASED SOCIAL SEARCH (primary method) ===
async function searchSocialByName(name) {
  if (!name || name.length < 2) return [];
  const results = []; const seen = new Set();
  const socialSites = [
    "instagram.com", "facebook.com", "twitter.com", "tiktok.com", "linkedin.com",
    "youtube.com", "reddit.com", "github.com", "pinterest.com", "twitch.tv",
    "snapchat.com", "onlyfans.com", "patreon.com", "tumblr.com", "flickr.com",
    "medium.com", "behance.net", "dribbble.com", "threads.net", "discord.com",
  ];

  // Search each social site with the name
  const queries = socialSites.map(site => `${name} site:${site}`);
  // Limit to first 5 sites to avoid rate limiting
  const batch = queries.slice(0, 5);

  for (const q of batch) {
    try {
      const encoded = encodeURIComponent(q);
      const res = await axios.get(`https://www.google.com/search?q=${encoded}&hl=en&num=5`, {
        headers: { "User-Agent": randomUA(), "Accept-Language": "en-US,en;q=0.9" },
        timeout: 8000,
      });
      const $ = cheerio.load(res.data);
      $("a[href]").each((_, el) => {
        let href = $(el).attr("href") || "";
        if (href.startsWith("/url?q=")) href = decodeURIComponent(href.replace("/url?q=", "").split("&")[0]);
        if (href.startsWith("http") && !href.includes("google.com") && !seen.has(href)) {
          const matched = Object.keys(SOCIAL_DOMAINS).find(d => href.toLowerCase().includes(d));
          if (matched) {
            seen.add(href);
            const isSocial = socialSites.some(s => href.includes(s));
            results.push({ url: href, confidence: isSocial ? 75 : 50 });
          }
        }
      });
      await new Promise(r => setTimeout(r, 500)); // rate limiting
    } catch {}
  }
  return results;
}

// === GENERATE NAME VARIANTS FROM IMAGE FILENAME ===
function generateNamesFromFile(imagePath) {
  const base = path.basename(imagePath, path.extname(imagePath));
  // Try to split on common separators
  const parts = base.split(/[_\-.\s]+/).filter(Boolean);
  if (parts.length >= 2) {
    // Could be firstname_lastname
    return [parts.join(" "), parts.join(""), parts[0]];
  }
  return [base];
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
    return results;
  } catch (err) { console.error("Google error:", err.message); return []; }
}

// === GOOGLE SEARCH FOR ANY NAME HINTS FROM IMAGE SEARCH ===
async function findNamesFromImageUrls(urls) {
  const names = new Set();
  for (const item of urls.slice(0, 10)) {
    const title = item.url.split("/").pop()?.replace(/[-_]/g, " ") || "";
    if (title.length > 3 && title.length < 40 && !title.match(/^\d+$/)) {
      names.add(title.trim());
    }
  }
  // Search Google for the first URL's page title
  if (urls.length > 0) {
    try {
      const res = await axios.get(urls[0].url, { headers: { "User-Agent": randomUA() }, timeout: 5000 });
      const $ = cheerio.load(res.data);
      const title = $("title").text().trim();
      if (title && title.length > 3 && title.length < 60) {
        // Remove site name from title
        const clean = title.replace(/ - .*$/, "").replace(/ \| .*$/, "").trim();
        if (clean.length > 3) names.add(clean);
      }
    } catch {}
  }
  return [...names];
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

async function searchCriminalRecords(name, existingUrls) {
  if (!name || name.length < 2) return [];
  const results = []; const seen = new Set();

  for (const site of CRIMINAL_SITES) {
    if (existingUrls.some(u => u.toLowerCase().includes(site.domain))) {
      const url = existingUrls.find(u => u.toLowerCase().includes(site.domain));
      if (url && !seen.has(url)) { seen.add(url); results.push({ source: site.name, type: site.type, url, confidence: 60 }); }
    }
  }

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
    // Phase 1: Reverse image search (Yandex + Google)
    const [yandex, google] = await Promise.all([
      searchYandex(imagePath), searchGoogle(imagePath),
    ]);
    let allUrls = [...yandex, ...google];
    const seen = new Set();
    const merged = [];
    for (const item of allUrls) {
      const norm = item.url.replace(/\/$/, "").toLowerCase();
      if (!seen.has(norm)) { seen.add(norm); merged.push(item); }
    }

    // Phase 2: Try to extract names from image search results
    let names = await findNamesFromImageUrls(merged);

    // Phase 3: Search social media by name (primary method for real results)
    let nameBasedMatches = [];
    for (const name of names.slice(0, 3)) {
      const matches = await searchSocialByName(name);
      nameBasedMatches.push(...matches);
    }

    // Merge all results
    for (const item of nameBasedMatches) {
      const norm = item.url.replace(/\/$/, "").toLowerCase();
      if (!seen.has(norm)) { seen.add(norm); merged.push(item); }
    }

    const socialProfiles = classifySocialProfiles(merged);
    const otherUrls = merged.filter(m =>
      !Object.keys(SOCIAL_DOMAINS).some(d => m.url.toLowerCase().includes(d))
    ).slice(0, 40);

    // Extract names for criminal search
    let nameList = [];
    for (const p of socialProfiles) {
      const n = extractNameFromUrl(p.url);
      if (n && !nameList.includes(n.toLowerCase())) nameList.push(n);
    }
    if (nameList.length === 0 && names.length > 0) nameList = names;

    let criminalRecords = [];
    if (nameList.length > 0) {
      const allSourceUrls = merged.map(m => m.url);
      criminalRecords = await searchCriminalRecords(nameList[0], allSourceUrls);
    }

    try { fs.unlinkSync(imagePath); } catch {}

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
    version: "3.0",
    engines: { yandex: true, google: true, nameSearch: true },
    criminalSearch: true,
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`\n  FaceFinder API v3 running on port ${PORT}`);
  console.log(`  Reverse image: Yandex=OK  Google=OK`);
  console.log(`  Name-based social search: ENABLED`);
  console.log(`  Criminal records search: ENABLED\n`);
});
