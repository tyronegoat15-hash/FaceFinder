const express = require("express");
const multer = require("multer");
const axios = require("axios");
const FormData = require("form-data");
const cheerio = require("cheerio");
const fs = require("fs");
const path = require("path");
const cors = require("cors");
const crypto = require("crypto");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(express.json({ limit: "50mb" }));

const upload = multer({ dest: "uploads/" });

const SOCIAL_DOMAINS = {
  "instagram.com": { name: "Instagram", color: "#E4405F" },
  "tiktok.com": { name: "TikTok", color: "#000000" },
  "facebook.com": { name: "Facebook", color: "#1877F2" },
  "fb.com": { name: "Facebook", color: "#1877F2" },
  "twitter.com": { name: "Twitter / X", color: "#1DA1F2" },
  "x.com": { name: "X (Twitter)", color: "#000000" },
  "snapchat.com": { name: "Snapchat", color: "#FFFC00" },
  "linkedin.com": { name: "LinkedIn", color: "#0A66C2" },
  "youtube.com": { name: "YouTube", color: "#FF0000" },
  "youtu.be": { name: "YouTube", color: "#FF0000" },
  "reddit.com": { name: "Reddit", color: "#FF4500" },
  "pinterest.com": { name: "Pinterest", color: "#BD081C" },
  "onlyfans.com": { name: "OnlyFans", color: "#00AFF0" },
  "github.com": { name: "GitHub", color: "#333333" },
  "discord.com": { name: "Discord", color: "#5865F2" },
  "discord.gg": { name: "Discord", color: "#5865F2" },
  "telegram.org": { name: "Telegram", color: "#26A5E4" },
  "t.me": { name: "Telegram", color: "#26A5E4" },
  "twitch.tv": { name: "Twitch", color: "#9146FF" },
  "patreon.com": { name: "Patreon", color: "#FF424D" },
  "threads.net": { name: "Threads", color: "#000000" },
  "tinder.com": { name: "Tinder", color: "#FF6B6B" },
  "bumble.com": { name: "Bumble", color: "#FFC000" },
  "hinge.co": { name: "Hinge", color: "#FF4B4B" },
  "medium.com": { name: "Medium", color: "#000000" },
  "tumblr.com": { name: "Tumblr", color: "#36465D" },
  "flickr.com": { name: "Flickr", color: "#0063DC" },
  "vsco.co": { name: "VSCO", color: "#000000" },
  "behance.net": { name: "Behance", color: "#1769FF" },
  "dribbble.com": { name: "Dribbble", color: "#EA4C89" },
  "vk.com": { name: "VK", color: "#4C75A3" },
  "vkontakte.ru": { name: "VK", color: "#4C75A3" },
  "ok.ru": { name: "Odnoklassniki", color: "#EE8208" },
  "weibo.com": { name: "Weibo", color: "#E6162D" },
  "xiaohongshu.com": { name: "Xiaohongshu", color: "#FF2442" },
  "kuaishou.com": { name: "Kuaishou", color: "#FF6900" },
};

const USER_AGENTS = [
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15",
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
];

function randomUA() {
  return USER_AGENTS[Math.floor(Math.random() * USER_AGENTS.length)];
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function extractUsername(url) {
  try {
    const u = new URL(url);
    const parts = u.pathname.replace(/\/$/, "").split("/").filter(Boolean);
    const host = u.hostname;

    if (host.includes("instagram.com") && parts[0]) return "@" + parts[0];
    if (host.includes("tiktok.com") && parts[0]?.startsWith("@")) return parts[0];
    if (host.includes("tiktok.com") && parts[0]) return "@" + parts[0];
    if ((host.includes("twitter.com") || host.includes("x.com")) && parts[0]) return "@" + parts[0];
    if (host.includes("github.com") && parts[0]) return parts[0];
    if (host.includes("reddit.com") && parts[0] === "user" && parts[1]) return "u/" + parts[1];
    if (host.includes("youtube.com") && parts[0]?.startsWith("@")) return parts[0];
    if (host.includes("t.me") && parts[0]) return "@" + parts[0];
    if (host.includes("twitch.tv") && parts[0]) return parts[0];
    return null;
  } catch {
    return null;
  }
}

function classifyResults(urls) {
  const profiles = [];
  const seen = new Set();

  for (const item of urls) {
    const srcUrl = item.url || "";
    if (!srcUrl || seen.has(srcUrl)) continue;
    seen.add(srcUrl);

    const match = Object.entries(SOCIAL_DOMAINS).find(([domain]) =>
      srcUrl.toLowerCase().includes(domain)
    );

    if (match) {
      profiles.push({
        platform: match[1].name,
        platformColor: match[1].color,
        url: srcUrl,
        username: extractUsername(srcUrl),
        confidence: item.confidence || 50,
      });
    }
  }

  return profiles;
}

// ====== YANDEX REVERSE IMAGE SEARCH ======
async function searchYandex(imagePath) {
  try {
    const form = new FormData();
    form.append("upfile", fs.createReadStream(imagePath), {
      filename: "photo.jpg",
      contentType: "image/jpeg",
    });
    form.append("rpt", "imageview");

    const uploadRes = await axios.post(
      "https://yandex.com/images/search",
      form,
      {
        headers: {
          "User-Agent": randomUA(),
          Accept: "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
          "Accept-Language": "en-US,en;q=0.9",
          ...form.getHeaders(),
        },
        maxRedirects: 5,
        timeout: 15000,
      }
    );

    const html = uploadRes.data;
    const $ = cheerio.load(html);

    const results = [];
    const urls = new Set();

    $("a, .CbirItem, .serp-item__link, img.serp-item__thumb").each((_, el) => {
      const link = $(el).attr("href") || $(el).attr("data-href") || "";
      if (link && !link.startsWith("/") && !link.startsWith("#") && !urls.has(link)) {
        urls.add(link);
        results.push({ url: link, confidence: 60 });
      }
    });

    // Try to find URLs in script data
    const scripts = $("script").text();
    const urlMatches = scripts.match(/https?:\/\/[^\s"'<>]+/g) || [];
    for (const u of urlMatches) {
      if (!urls.has(u)) {
        urls.add(u);
        results.push({ url: u, confidence: 50 });
      }
    }

    return results;
  } catch (err) {
    console.error("Yandex search error:", err.message);
    return [];
  }
}

// ====== BING VISUAL SEARCH ======
async function searchBing(imagePath) {
  const apiKey = process.env.BING_API_KEY;
  if (!apiKey) return [];

  try {
    const imageBuffer = fs.readFileSync(imagePath);
    const imageBase64 = imageBuffer.toString("base64");

    const res = await axios.post(
      "https://api.bing.microsoft.com/v7.0/images/visualSearch",
      imageBuffer,
      {
        headers: {
          "Ocp-Apim-Subscription-Key": apiKey,
          "Content-Type": "multipart/form-data",
        },
        params: {
          mkt: "en-US",
          safeSearch: "Off",
        },
        timeout: 15000,
      }
    );

    const data = res.data;
    const results = [];

    // Tags contain visually similar images
    for (const tag of data.tags || []) {
      for (const action of tag.actions || []) {
        if (action.actionType === "MoreSizes") {
          for (const size of action.data?.value || []) {
            if (size.hostPageUrl) {
              results.push({ url: size.hostPageUrl, confidence: Math.round((tag.confidence || 0.5) * 100) });
            }
          }
        }
      }
      // Direct pages where image appears
      if (tag.hostPageUrl) {
        results.push({ url: tag.hostPageUrl, confidence: Math.round((tag.confidence || 0.5) * 100) });
      }
    }

    // Visual search suggestions
    const pivotSuggestions = data.pivotSuggestions || [];
    for (const pivot of pivotSuggestions) {
      for (const suggestion of pivot.suggestions || []) {
        if (suggestion.hostPageUrl) {
          results.push({ url: suggestion.hostPageUrl, confidence: 40 });
        }
      }
    }

    return results;
  } catch (err) {
    console.error("Bing search error:", err.message);
    return [];
  }
}

// ====== GOOGLE REVERSE IMAGE SEARCH (direct upload) ======
async function searchGoogle(imagePath) {
  try {
    const form = new FormData();
    form.append("encoded_image", fs.createReadStream(imagePath), {
      filename: "photo.jpg",
      contentType: "image/jpeg",
    });
    form.append("image_content", "");
    form.append("filename", "photo.jpg");
    form.append("sbisrc", "cr_1_5_2");

    // Upload directly to Google reverse image search
    const res = await axios.post(
      "https://www.google.com/searchbyimage/upload",
      form,
      {
        headers: {
          "User-Agent": randomUA(),
          Accept: "text/html,application/xhtml+xml",
          "Accept-Language": "en-US,en;q=0.9",
          ...form.getHeaders(),
        },
        maxRedirects: 0,
        validateStatus: (s) => s < 400 || s === 302,
        timeout: 20000,
      }
    );

    const html = res.data;
    const $ = cheerio.load(html);
    const results = [];
    const urls = new Set();

    // Parse result links from Google search results
    $("a").each((_, el) => {
      let href = $(el).attr("href") || "";
      if (href.startsWith("/url?q=")) {
        href = decodeURIComponent(href.replace("/url?q=", "").split("&")[0]);
      }
      if (href.startsWith("http") && !href.includes("google.com") && !urls.has(href)) {
        urls.add(href);
        results.push({ url: href, confidence: 50 });
      }
    });

    // Also extract from redirect URLs
    if (res.request?.res?.responseUrl) {
      const redirectUrl = res.request.res.responseUrl;
      if (redirectUrl.includes("tbn:")) {
        // Google's image search redirect URL
      }
    }

    // Extract from all script text
    const scriptText = $("script").text();
    const foundUrls = scriptText.match(/"https?:\/\/[^"]+"/g) || [];
    for (const match of foundUrls) {
      const u = match.replace(/"/g, "");
      if (!urls.has(u) && !u.includes("google.com") && !u.includes("gstatic.com")) {
        urls.add(u);
        results.push({ url: u, confidence: 45 });
      }
    }

    return results;
  } catch (err) {
    console.error("Google search error:", err.message);
    return [];
  }
}

// ====== MAIN SEARCH ENDPOINT ======
app.post("/api/search", upload.single("image"), async (req, res) => {
  let imagePath = req.file?.path;

  try {
    if (!imagePath) {
      return res.status(400).json({ error: "No image provided" });
    }

    console.log("Starting search for image:", imagePath);

    // Run all search engines in parallel
    const [yandexResults, bingResults, googleResults] = await Promise.all([
      searchYandex(imagePath),
      searchBing(imagePath),
      searchGoogle(imagePath),
    ]);

    // Clean up temp file
    try { fs.unlinkSync(imagePath); } catch {}
    imagePath = null;

    console.log(`Results: Yandex=${yandexResults.length}, Bing=${bingResults.length}, Google=${googleResults.length}`);

    // Merge & deduplicate all results
    const allUrls = [...yandexResults, ...bingResults, ...googleResults];
    const seen = new Set();
    const merged = [];

    for (const item of allUrls) {
      const normalized = item.url.replace(/\/$/, "").toLowerCase();
      if (!seen.has(normalized)) {
        seen.add(normalized);
        merged.push(item);
      }
    }

    // Classify into social profiles
    const socialProfiles = classifyResults(merged);

    // Other matches (non-social URLs)
    const otherMatches = merged
      .filter((m) => !Object.keys(SOCIAL_DOMAINS).some((d) => m.url.toLowerCase().includes(d)))
      .slice(0, 30);

    res.json({
      success: true,
      totalMatches: merged.length,
      socialProfiles,
      otherMatches,
    });
  } catch (err) {
    console.error("Search error:", err);
    if (imagePath) {
      try { fs.unlinkSync(imagePath); } catch {}
    }
    res.status(500).json({ error: err.message });
  }
});

app.get("/api/health", (req, res) => {
  res.json({
    status: "ok",
    engines: {
      yandex: true,
      bing: !!process.env.BING_API_KEY,
      google: true,
    },
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`\n  Social Finder API running on http://0.0.0.0:${PORT}`);
  console.log(`  Engines: Yandex=✓ Bing=${process.env.BING_API_KEY ? "✓" : "✗ (optional)"} Google=✓`);
  console.log(`  All engines are FREE, no API keys required except Bing (optional)\n`);
});
