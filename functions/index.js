const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const { GoogleGenAI } = require("@google/genai");

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");

function safeString(value) {
  return (value ?? "").toString().trim();
}

function safeList(value) {
  return Array.isArray(value) ? value : [];
}

function toNumber(value, fallback = 0) {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}

function peso(value) {
  return `₱${toNumber(value).toFixed(2)}`;
}

function cleanReply(text) {
  return safeString(text)
    .replace(/\*\*/g, "")
    .replace(/[ \t]+\n/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

function clampText(text, maxChars = 12000) {
  const clean = safeString(text);
  if (!clean) return "";
  if (clean.length <= maxChars) return clean;
  return `${clean.slice(0, maxChars)}\n\n[Context trimmed for length]`;
}

function normalizeKeyword(text) {
  return safeString(text).toLowerCase();
}

function uniqueStrings(values) {
  return [...new Set(values.map((e) => safeString(e)).filter(Boolean))];
}

function titleCaseWords(text) {
  return safeString(text)
    .split(/[\s_]+/)
    .filter(Boolean)
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(" ");
}

function normalizeVariantLabel(label) {
  const v = safeString(label);
  if (!v) return "";

  const lower = v.toLowerCase();

  const map = {
    hot: "Hot",
    regular: "Regular",
    large: "Large",
    slice: "Slice",
    withdrink: "With Drink",
    withoutdrink: "Without Drink",
    "iced12": "Iced 12oz",
    "iced16": "Iced 16oz",
    "iced22": "Iced 22oz",
  };

  return map[lower] || titleCaseWords(v);
}

function normalizeProduct(item) {
  const name = safeString(item.name || item.title || item.productName);
  const description = safeString(item.description);

  const categoryRaw = safeString(item.categoryId || item.category || item.type);
  const category = categoryRaw.toLowerCase();

  const availableVariants = safeList(item.availableVariants || item.variants).map((e) =>
    safeString(e)
  );

  const rawPrices =
    item.prices && typeof item.prices === "object" ? item.prices : {};
  const prices = {};
  for (const [key, value] of Object.entries(rawPrices)) {
    prices[safeString(key)] = toNumber(value, 0);
  }

  const tags = safeList(item.tags).map((e) => safeString(e).toLowerCase());
  const ingredients = safeList(item.ingredients).map((e) => safeString(e));

  const isAvailable =
    typeof item.isAvailable === "boolean" ? item.isAvailable : true;

  const isBestSeller =
    typeof item.isBestSeller === "boolean"
      ? item.isBestSeller
      : tags.some((t) => t.includes("bestseller") || t.includes("best seller"));

  const sortOrder = toNumber(item.sortOrder, 9999);

  return {
    id: safeString(item.id),
    name,
    description,
    category,
    imageUrl: safeString(item.imageUrl),
    prices,
    availableVariants,
    hasVariants:
      typeof item.hasVariants === "boolean"
        ? item.hasVariants
        : availableVariants.length > 1,
    isAvailable,
    isBestSeller,
    stockQty: toNumber(item.stockQty, 999),
    displayType: safeString(item.displayType),
    sortOrder,
    tags,
    ingredients,
    beanType: safeString(item.beanType),
    caffeineLevel: safeString(item.caffeineLevel),
    sweetness: safeString(item.sweetness),
    bestFor: safeString(item.bestFor),
  };
}

function formatCart(cartItems) {
  if (!cartItems.length) return "Cart is empty.";

  return cartItems
    .map((item, index) => {
      const name = safeString(item.name || item.title || item.productName || "Unknown item");
      const variant = safeString(item.variant);
      const qty = toNumber(item.quantity || item.qty || 1, 1);
      const price = toNumber(item.price ?? item.unitPrice ?? 0, 0);
      const subtotal = toNumber(item.subtotal ?? qty * price, qty * price);
      const notes = safeString(item.notes || item.note);

      return [
        `${index + 1}. ${name}${variant ? ` (${normalizeVariantLabel(variant)})` : ""}`,
        `Quantity: ${qty}`,
        `Price: ${peso(price)}`,
        `Subtotal: ${peso(subtotal)}`,
        notes ? `Notes: ${notes}` : null,
      ]
        .filter(Boolean)
        .join(" | ");
    })
    .join("\n");
}

function formatPriceText(prices) {
  const entries = Object.entries(prices || {})
    .filter(([_, value]) => Number.isFinite(Number(value)))
    .map(([key, value]) => `${normalizeVariantLabel(key)}: ${peso(value)}`);

  return entries.join(", ");
}

function formatMenu(menuItems) {
  if (!menuItems.length) return "No menu data provided.";

  return menuItems
    .filter((item) => item.isAvailable !== false)
    .sort((a, b) => toNumber(a.sortOrder, 9999) - toNumber(b.sortOrder, 9999))
    .map((rawItem, index) => {
      const item = normalizeProduct(rawItem);

      const variantsText = uniqueStrings(item.availableVariants.map(normalizeVariantLabel)).join(", ");
      const priceText = formatPriceText(item.prices);
      const tagsText = uniqueStrings(item.tags).join(", ");
      const ingredientsText = uniqueStrings(item.ingredients).join(", ");

      return [
        `${index + 1}. ${item.name}`,
        item.category ? `Category: ${item.category}` : null,
        item.description ? `Description: ${item.description}` : null,
        ingredientsText ? `Ingredients: ${ingredientsText}` : null,
        variantsText ? `Variants: ${variantsText}` : null,
        priceText ? `Price: ${priceText}` : null,
        item.beanType ? `Bean Type: ${item.beanType}` : null,
        item.caffeineLevel ? `Caffeine Level: ${item.caffeineLevel}` : null,
        item.sweetness ? `Sweetness: ${item.sweetness}` : null,
        item.bestFor ? `Best For: ${item.bestFor}` : null,
        tagsText ? `Tags: ${tagsText}` : null,
        `Best Seller: ${item.isBestSeller ? "Yes" : "No"}`,
      ]
        .filter(Boolean)
        .join("\n");
    })
    .join("\n\n");
}

function normalizeLegacyMenuContext(text) {
  const clean = safeString(text);
  if (!clean) return "";

  const blocks = clean
    .split(/\n{2,}/)
    .map((b) => b.trim())
    .filter(Boolean);

  if (!blocks.length) return clean;

  const normalizedBlocks = blocks.map((block, index) => {
    const firstSegment = block.split("|")[0]?.trim() || block;
    const firstLine = firstSegment.split("\n")[0].trim();
    const name = firstLine
      .replace(/^[\-\d.\s]+/, "")
      .replace(/\s*\|\s*.*$/, "")
      .trim();

    const lower = block.toLowerCase();

    const category = (block.match(/category:\s*([^|,\n]+)/i)?.[1] || "").trim();
    const description = (block.match(/description:\s*([^|]+?)(?=\s+\w+:|$)/i)?.[1] || "").trim();
    const variants = (block.match(/variants:\s*([^|]+?)(?=\s+\w+:|$)/i)?.[1] || "").trim();
    const prices = (block.match(/prices:\s*([^|]+?)(?=\s+\w+:|$)/i)?.[1] || "").trim();
    const tags = (block.match(/tags:\s*([^|]+?)(?=\s+\w+:|$)/i)?.[1] || "").trim();

    return [
      `${index + 1}. ${name || `Item ${index + 1}`}`,
      category ? `Category: ${category}` : null,
      description ? `Description: ${description}` : null,
      variants ? `Variants: ${variants}` : null,
      prices ? `Price: ${prices}` : null,
      tags ? `Tags: ${tags}` : null,
      lower.includes("bestseller: true") || lower.includes("best seller: yes")
        ? `Best Seller: Yes`
        : null,
    ]
      .filter(Boolean)
      .join("\n");
  });

  return normalizedBlocks.join("\n\n");
}

function extractMenuBlocks(menuText) {
  if (!menuText || menuText.toLowerCase().includes("no menu data provided")) {
    return [];
  }

  return menuText
    .split("\n\n")
    .map((block) => block.trim())
    .filter(Boolean);
}

function getItemNameFromBlock(block) {
  const firstLine = block.split("\n")[0] || "";
  return firstLine
    .replace(/^\d+\.\s*/, "")
    .replace(/^-+\s*/, "")
    .replace(/\s*\|.*$/, "")
    .trim();
}

function getFieldFromBlock(block, fieldName) {
  const lines = block.split("\n");
  const prefix = `${fieldName.toLowerCase()}:`;
  const line = lines.find((l) => l.toLowerCase().startsWith(prefix));
  if (!line) return "";
  return line.slice(prefix.length).trim();
}

function parsePriceValues(block) {
  return [...block.matchAll(/₱(\d+(?:\.\d+)?)/g)].map((m) => Number(m[1]));
}

function dedupeBlocksByName(blocks) {
  const seen = new Set();
  const result = [];

  for (const block of blocks) {
    const name = getItemNameFromBlock(block).toLowerCase();
    if (!name || seen.has(name)) continue;
    seen.add(name);
    result.push(block);
  }

  return result;
}

function findMenuMatch(message, menuText) {
  const q = normalizeKeyword(message);
  const blocks = extractMenuBlocks(menuText);

  let bestMatch = null;
  let bestScore = 0;

  for (const block of blocks) {
    const itemName = getItemNameFromBlock(block);
    const lowerName = itemName.toLowerCase();
    if (!lowerName) continue;

    let score = 0;

    if (q.includes(lowerName)) score += 100;

    const words = lowerName.split(/\s+/).filter(Boolean);
    for (const word of words) {
      if (word.length >= 3 && q.includes(word)) score += 10;
    }

    const tags = getFieldFromBlock(block, "Tags").toLowerCase();
    for (const part of tags.split(",").map((s) => s.trim()).filter(Boolean)) {
      if (part.length >= 3 && q.includes(part)) score += 5;
    }

    if (score > bestScore) {
      bestScore = score;
      bestMatch = block;
    }
  }

  return bestScore >= 10 ? bestMatch : null;
}

function findItemsByKeyword(menuText, keywords) {
  const blocks = extractMenuBlocks(menuText);
  const normalizedKeywords = keywords.map((k) => normalizeKeyword(k));

  return dedupeBlocksByName(
    blocks.filter((block) => {
      const lower = block.toLowerCase();
      return normalizedKeywords.some((keyword) => lower.includes(keyword));
    })
  );
}

function getBestSellerItems(menuText, limit = 4) {
  return dedupeBlocksByName(
    extractMenuBlocks(menuText).filter((block) => {
      const lower = block.toLowerCase();
      return (
        lower.includes("best seller: yes") ||
        lower.includes("bestseller: true") ||
        lower.includes("tags:") && lower.includes("bestseller")
      );
    })
  ).slice(0, limit);
}

function getAffordableItems(menuText, limit = 3) {
  const blocks = extractMenuBlocks(menuText);

  const parsed = dedupeBlocksByName(blocks).map((block) => {
    const name = getItemNameFromBlock(block);
    const prices = parsePriceValues(block);
    const minPrice = prices.length ? Math.min(...prices) : Number.MAX_SAFE_INTEGER;
    return { name, minPrice };
  });

  return parsed
    .filter((item) => item.minPrice !== Number.MAX_SAFE_INTEGER)
    .sort((a, b) => a.minPrice - b.minPrice)
    .slice(0, limit);
}

function summarizeCart(cartText) {
  if (!cartText || cartText.toLowerCase().includes("cart is empty")) return null;
  const lines = cartText.split("\n").filter(Boolean);
  if (!lines.length) return null;
  return `You currently have ${lines.length} item${lines.length > 1 ? "s" : ""} in your cart.`;
}

function inferPreferenceKeywords(message) {
  const q = normalizeKeyword(message);

  return {
    wantsCoffee:
      q.includes("coffee") ||
      q.includes("latte") ||
      q.includes("americano") ||
      q.includes("espresso") ||
      q.includes("cappuccino") ||
      q.includes("mocha") ||
      q.includes("macchiato"),
    wantsDessert:
      q.includes("dessert") ||
      q.includes("cake") ||
      q.includes("sweet") ||
      q.includes("brownie") ||
      q.includes("cookie") ||
      q.includes("pastry"),
    wantsMeal:
      q.includes("meal") ||
      q.includes("food") ||
      q.includes("rice") ||
      q.includes("burger") ||
      q.includes("pasta") ||
      q.includes("chicken") ||
      q.includes("snack"),
    wantsBudget:
      q.includes("cheap") ||
      q.includes("budget") ||
      q.includes("affordable") ||
      q.includes("low price"),
    wantsStrong:
      q.includes("strong") ||
      q.includes("bold") ||
      q.includes("intense"),
    wantsSweet:
      q.includes("sweet") ||
      q.includes("creamy") ||
      q.includes("chocolate"),
    wantsCold:
      q.includes("iced") ||
      q.includes("cold") ||
      q.includes("refreshing"),
    wantsHot:
      q.includes("hot") ||
      q.includes("warm"),
    wantsBest:
      q.includes("best") ||
      q.includes("best seller") ||
      q.includes("popular") ||
      q.includes("top"),
  };
}

function buildPairingSuggestion(menuText, message) {
  const prefs = inferPreferenceKeywords(message);

  const dessertItems = findItemsByKeyword(menuText, [
    "dessert",
    "cake",
    "brownie",
    "cookie",
    "sweet",
    "pastry",
  ]);

  const coffeeItems = findItemsByKeyword(menuText, [
    "coffee",
    "latte",
    "americano",
    "espresso",
    "cappuccino",
    "mocha",
    "macchiato",
  ]);

  const dessertName = dessertItems.length ? getItemNameFromBlock(dessertItems[0]) : "";
  const coffeeName = coffeeItems.length ? getItemNameFromBlock(coffeeItems[0]) : "";

  if (prefs.wantsCoffee && dessertName && coffeeName) {
    return `A nice pairing would be ${coffeeName} with ${dessertName}.`;
  }

  if (prefs.wantsDessert && dessertName && coffeeName) {
    return `A nice pairing would be ${dessertName} with ${coffeeName}.`;
  }

  return "";
}

function namesFromBlocks(blocks, limit = 4) {
  return dedupeBlocksByName(blocks)
    .slice(0, limit)
    .map((block) => getItemNameFromBlock(block))
    .filter(Boolean);
}

function buildVivianFallback(message, orderType, menuText, cartText) {
  const q = normalizeKeyword(message);
  const prefs = inferPreferenceKeywords(message);
  const matchedItem = findMenuMatch(message, menuText);
  const cartSummary = summarizeCart(cartText);

  const coffeeItems = findItemsByKeyword(menuText, [
    "coffee",
    "espresso",
    "latte",
    "americano",
    "cappuccino",
    "mocha",
    "macchiato",
  ]);

  const dessertItems = findItemsByKeyword(menuText, [
    "cake",
    "dessert",
    "cookie",
    "brownie",
    "pastry",
    "sweet",
    "cheesecake",
    "ube",
  ]);

  const mealItems = findItemsByKeyword(menuText, [
    "rice",
    "meal",
    "pasta",
    "katsu",
    "burger",
    "spaghetti",
    "chicken",
    "sandwich",
  ]);

  const bestSellers = getBestSellerItems(menuText, 4);
  const pairingSuggestion = buildPairingSuggestion(menuText, message);

  if (
    q === "hi" ||
    q === "hello" ||
    q === "hey" ||
    q.includes("good morning") ||
    q.includes("good afternoon") ||
    q.includes("good evening")
  ) {
    return "Hello, I’m Vivian. I’d be happy to help you choose a drink, meal, dessert, or a nice pairing.";
  }

  if (
    q.includes("cart") ||
    q.includes("my order") ||
    q.includes("order summary") ||
    q.includes("what did i order")
  ) {
    if (!cartText || cartText.toLowerCase().includes("cart is empty")) {
      return "Your cart is empty right now. I can suggest a coffee, dessert, snack, or a filling meal if you’d like.";
    }
    return `${cartSummary || "Here’s your current order:"}\n\n${cartText}`;
  }

  if (prefs.wantsBudget) {
    const affordable = getAffordableItems(menuText, 3);
    if (affordable.length) {
      return `Budget-friendly picks include ${affordable
        .map((item) => `${item.name} (${peso(item.minPrice)})`)
        .join(", ")}.`;
    }
  }

  if (prefs.wantsBest && bestSellers.length) {
    const picks = namesFromBlocks(bestSellers, 4);
    return `Our standout picks include ${picks.join(", ")}${pairingSuggestion ? `. ${pairingSuggestion}` : "."}`;
  }

  if (prefs.wantsCoffee) {
    const picks = namesFromBlocks(coffeeItems, 3);
    if (picks.length) {
      let tone = `If you're looking for coffee, I’d recommend ${picks.join(", ")}.`;
      if (prefs.wantsStrong) tone += " If you want something bolder, I can narrow it down further.";
      if (prefs.wantsSweet) tone += " If you prefer something smoother or sweeter, I can suggest a creamier option.";
      if (pairingSuggestion) tone += ` ${pairingSuggestion}`;
      return tone.trim();
    }
    return "I can help you choose the best drink on the menu. Tell me whether you want something strong, sweet, creamy, hot, or iced.";
  }

  if (prefs.wantsDessert) {
    const picks = namesFromBlocks(dessertItems, 3);
    if (picks.length) {
      let tone = `For something sweet, you might enjoy ${picks.join(", ")}.`;
      if (pairingSuggestion) tone += ` ${pairingSuggestion}`;
      return tone.trim();
    }
  }

  if (prefs.wantsMeal) {
    const picks = namesFromBlocks(mealItems, 3);
    if (picks.length) {
      return `If you're looking for something filling, I’d suggest ${picks.join(", ")}. I can also pair one with a drink for you.`;
    }
  }

  if (
    q.includes("recommend") ||
    q.includes("suggest") ||
    q.includes("what should i order")
  ) {
    const picks = uniqueStrings([
      ...namesFromBlocks(bestSellers, 4),
      ...namesFromBlocks(coffeeItems, 4),
      ...namesFromBlocks(mealItems, 4),
      ...namesFromBlocks(dessertItems, 4),
    ]).slice(0, 4);

    if (picks.length) {
      return `A good starting set would be ${picks.join(", ")}. I can narrow it down for sweet, strong, budget-friendly, or filling options.`;
    }
  }

  if (matchedItem) {
    const name = getItemNameFromBlock(matchedItem);
    const description = getFieldFromBlock(matchedItem, "Description");
    const price = getFieldFromBlock(matchedItem, "Price");
    const variants = getFieldFromBlock(matchedItem, "Variants");

    const parts = [
      name ? `${name}` : "",
      description ? description : "",
      price ? `Price: ${price}` : "",
      variants ? `Available in ${variants}` : "",
    ].filter(Boolean);

    if (parts.length) {
      return parts.join(". ") + ".";
    }
  }

  if (menuText && !menuText.toLowerCase().includes("no menu data provided")) {
    return `I can help with recommendations, ingredients, flavor guidance, pairings, and smart suggestions for your ${orderType || "order"}.`;
  }

  return "I’m here to help with menu questions, recommendations, drinks, desserts, and your cart.";
}

async function askGemini({ message, orderType, menuText, cartText }) {
  const apiKey = GEMINI_API_KEY.value();
  if (!apiKey) {
    throw new Error("Missing GEMINI_API_KEY secret.");
  }

  const ai = new GoogleGenAI({ apiKey });

  const trimmedMenuText = clampText(menuText, 10000);
  const trimmedCartText = clampText(cartText, 3500);

  const systemInstruction = `
You are Vivian, the premium AI café assistant for VIAN Café.

IDENTITY:
- You are Vivian.
- You are warm, polished, natural, and helpful.
- You sound like a smart café assistant, not a robot.
- You are conversational, concise to medium-length, and complete.
- You always finish your replies clearly.

CORE BEHAVIOR:
- Help guests choose drinks, meals, snacks, and desserts.
- Recommend items based on taste, mood, budget, cravings, sweetness, strength, and pairings.
- Explain flavors simply and attractively.
- Give specific menu-based suggestions whenever possible.

FACTUAL RULES:
- Use ONLY the provided menu and cart context as your factual source.
- Never invent menu items, prices, ingredients, promos, sizes, or availability.
- Never output raw menu context, raw field dumps, pipe-delimited text, or internal formatting.
- When recommending items, mention only clean product names and useful details.
- If something is not present in the menu context, say so politely and offer the closest helpful suggestion.
- If coffee exists in the menu context, never say the café has no coffee.
- If there is a direct product match, answer with that item first.
- Prefer best sellers when the user asks for the best or popular options.
- Respect the cart context when suggesting add-ons or pairings.
- Do not repeat the same product twice in one recommendation list.

STYLE RULES:
- Sound premium, human, and smooth.
- Avoid robotic phrases and repetitive sentence patterns.
- Avoid mentioning prompts, policies, backend, tokens, internal logic, or context formatting.
- Usually reply in 1 to 3 short paragraphs.
- Use bullets only when they make the answer clearer.
- End with a helpful next step when appropriate.

SALES / SERVICE BEHAVIOR:
- Be helpful, not pushy.
- Lightly upsell only when natural.
- Suggest pairings when it improves the answer.
- If the customer asks for the best, give a confident shortlist and why.

OUTPUT QUALITY:
- Every answer must feel complete.
- Never cut off mid-thought.
- Never return empty text.
`.trim();

  const prompt = `
CUSTOMER MESSAGE:
${message}

ORDER TYPE:
${orderType || "dine_in"}

MENU CONTEXT:
${trimmedMenuText || "No menu data provided."}

CART CONTEXT:
${trimmedCartText || "Cart is empty."}

Write Vivian's reply now.
`.trim();

  let assembled = "";
  let currentPrompt = prompt;

  for (let attempt = 0; attempt < 2; attempt++) {
    const response = await ai.models.generateContent({
      model: "gemini-2.5-flash",
      config: {
        systemInstruction,
        temperature: 0.65,
        topP: 0.9,
        maxOutputTokens: 1000,
      },
      contents: currentPrompt,
    });

    const text = cleanReply(response?.text || "");
    if (text) {
      assembled = assembled ? `${assembled}\n\n${text}` : text;
    }

    const lower = assembled.toLowerCase();
    const seemsCutOff =
      assembled.length > 0 &&
      !/[.!?]"?$/.test(assembled) &&
      !lower.endsWith("thank you") &&
      !lower.endsWith("thanks");

    if (!seemsCutOff) break;

    currentPrompt = `
The previous reply appears unfinished. Continue and finish it naturally.
Do not restart from the beginning.
Do not repeat earlier lines unless needed for continuity.

Original customer message:
${message}

Reply so far:
${assembled}
`.trim();
  }

  const reply = cleanReply(assembled);

  if (!reply) {
    throw new Error("Gemini returned an empty reply.");
  }

  return reply;
}

exports.askVivian = onCall(
  {
    region: "us-central1",
    cors: true,
    timeoutSeconds: 60,
    memory: "512MiB",
    secrets: [GEMINI_API_KEY],
  },
  async (request) => {
    try {
      logger.info("============== VIVIAN START ==============");
      logger.info("request.data", { data: request.data });

      const data = request.data || {};
      const message = safeString(data.message);
      const orderType = safeString(data.orderType || "dine_in");

      const cartItems = safeList(data.cartItems);
      const menuItems = safeList(data.menuItems);

      const oldMenuContext = safeString(data.menuContext);
      const oldCartContext = safeString(data.cartContext);

      const cartText = cartItems.length
        ? formatCart(cartItems)
        : oldCartContext || "Cart is empty.";

      const menuText = menuItems.length
        ? formatMenu(menuItems)
        : normalizeLegacyMenuContext(oldMenuContext) || "No menu data provided.";

      if (!message) {
        return {
          reply:
            "Hello, I’m Vivian. I can help you choose drinks, meals, desserts, and pairings based on your taste.",
          mode: "greeting",
        };
      }

      try {
        const reply = await askGemini({
          message,
          orderType,
          menuText,
          cartText,
        });

        return {
          reply,
          mode: "gemini",
        };
      } catch (geminiError) {
        logger.error("Gemini failed, using fallback", {
          error: geminiError?.message || String(geminiError),
        });

        return {
          reply: buildVivianFallback(message, orderType, menuText, cartText),
          mode: "fallback_local",
        };
      }
    } catch (error) {
      logger.error("askVivian error", {
        error: error?.message || String(error),
        stack: error?.stack || "",
      });

      throw new HttpsError(
        "internal",
        "Vivian had trouble processing your request."
      );
    }
  }
);