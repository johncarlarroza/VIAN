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

function peso(value) {
  const n = Number(value || 0);
  return `₱${n.toFixed(2)}`;
}

function clampText(text, maxChars = 6000) {
  const clean = safeString(text);
  if (!clean) return "";
  if (clean.length <= maxChars) return clean;
  return clean.slice(0, maxChars) + "\n\n[Context trimmed for length]";
}

function formatCart(cartItems) {
  if (!cartItems.length) return "Cart is empty.";

  return cartItems
    .map((item, index) => {
      const name = safeString(item.name || item.title || "Unknown item");
      const variant = safeString(item.variant);
      const qty = Number(item.quantity || item.qty || 1);
      const price = Number(item.price || 0);
      const notes = safeString(item.notes);
      const subtotal = qty * price;

      return [
        `${index + 1}. ${name}${variant ? ` (${variant})` : ""}`,
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

function formatMenu(menuItems) {
  if (!menuItems.length) return "No menu data provided.";

  return menuItems
    .map((item, index) => {
      const name = safeString(item.name);
      const category = safeString(item.category || item.categoryId);
      const description = safeString(item.description);

      const ingredients = Array.isArray(item.ingredients)
        ? item.ingredients.map((e) => safeString(e)).filter(Boolean).join(", ")
        : safeString(item.ingredients);

      const variants = Array.isArray(item.variants)
        ? item.variants.map((e) => safeString(e)).filter(Boolean).join(", ")
        : safeString(item.variants);

      const beanType = safeString(item.beanType);
      const caffeineLevel = safeString(item.caffeineLevel);
      const sweetness = safeString(item.sweetness);
      const bestFor = safeString(item.bestFor);
      const tags = Array.isArray(item.tags)
        ? item.tags.map((e) => safeString(e)).filter(Boolean).join(", ")
        : safeString(item.tags);

      let priceText = "";
      if (typeof item.price !== "undefined" && item.price !== null) {
        priceText = peso(item.price);
      } else if (item.prices && typeof item.prices === "object") {
        const entries = Object.entries(item.prices)
          .map(([key, value]) => `${key}: ${peso(value)}`)
          .join(", ");
        priceText = entries;
      }

      return [
        `${index + 1}. ${name}`,
        category ? `Category: ${category}` : null,
        description ? `Description: ${description}` : null,
        ingredients ? `Ingredients: ${ingredients}` : null,
        variants ? `Variants: ${variants}` : null,
        priceText ? `Price: ${priceText}` : null,
        beanType ? `Bean Type: ${beanType}` : null,
        caffeineLevel ? `Caffeine Level: ${caffeineLevel}` : null,
        sweetness ? `Sweetness: ${sweetness}` : null,
        bestFor ? `Best For: ${bestFor}` : null,
        tags ? `Tags: ${tags}` : null,
      ]
        .filter(Boolean)
        .join("\n");
    })
    .join("\n\n");
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
  return firstLine.replace(/^\d+\.\s*/, "").trim();
}

function findMenuMatch(message, menuText) {
  const q = message.toLowerCase();
  const blocks = extractMenuBlocks(menuText);

  let bestMatch = null;
  let bestScore = 0;

  for (const block of blocks) {
    const itemName = getItemNameFromBlock(block);
    const lowerName = itemName.toLowerCase();
    if (!lowerName) continue;

    let score = 0;
    if (q.includes(lowerName)) score += 100;

    const words = lowerName.split(" ").filter(Boolean);
    for (const word of words) {
      if (word.length >= 3 && q.includes(word)) score += 10;
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
  return blocks.filter((block) => {
    const lower = block.toLowerCase();
    return keywords.some((keyword) => lower.includes(keyword));
  });
}

function getAffordableItems(menuText, limit = 3) {
  const blocks = extractMenuBlocks(menuText);

  const parsed = blocks.map((block) => {
    const name = getItemNameFromBlock(block);
    const prices = [...block.matchAll(/₱(\d+(?:\.\d+)?)/g)].map((m) =>
      Number(m[1])
    );
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

function buildVivianFallback(message, orderType, menuText, cartText) {
  const q = message.toLowerCase();
  const matchedItem = findMenuMatch(message, menuText);
  const cartSummary = summarizeCart(cartText);

  if (
    q === "hi" ||
    q === "hello" ||
    q === "hey" ||
    q.includes("good morning") ||
    q.includes("good afternoon") ||
    q.includes("good evening")
  ) {
    return "Hello, I’m Vivian. I’d be happy to help you choose something from the menu.";
  }

  if (
    q.includes("cart") ||
    q.includes("my order") ||
    q.includes("order summary") ||
    q.includes("what did i order")
  ) {
    if (!cartText || cartText.toLowerCase().includes("cart is empty")) {
      return "Your cart is empty right now. I can help you choose a drink, snack, or meal.";
    }
    return `${cartSummary || "Here’s your current order:"}\n\n${cartText}`;
  }

  if (
    q.includes("cheap") ||
    q.includes("budget") ||
    q.includes("affordable")
  ) {
    const affordable = getAffordableItems(menuText, 3);
    if (affordable.length) {
      return `Budget-friendly picks: ${affordable
        .map((item) => `${item.name} (${peso(item.minPrice)})`)
        .join(", ")}.`;
    }
  }

  if (matchedItem) {
    return `Here’s what I found:\n\n${matchedItem}`;
  }

  if (menuText && !menuText.toLowerCase().includes("no menu data provided")) {
    return `I can help with recommendations, ingredients, flavor, and pairings for ${orderType || "your order"}.`;
  }

  return "I’m here to help with menu questions, ingredients, and recommendations.";
}

function cleanReply(text) {
  return safeString(text)
    .replace(/\*\*/g, "")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

async function askGemini({ message, orderType, menuText, cartText }) {
  const apiKey = GEMINI_API_KEY.value();
  if (!apiKey) {
    throw new Error("Missing GEMINI_API_KEY secret.");
  }

  const ai = new GoogleGenAI({ apiKey });

  const trimmedMenuText = clampText(menuText, 5000);
  const trimmedCartText = clampText(cartText, 2500);

  const systemInstruction = `
You are Vivian, the premium AI café assistant.

Style:
- warm, polished, natural, concise
- never robotic, never repetitive
- sound premium and helpful
- briefly empathize when appropriate
- guide the customer clearly

Rules:
- Use ONLY the provided menu/cart context as factual source.
- Never invent menu items, prices, ingredients, sizes, or promos.
- If something is missing, say so politely.
- Keep answers short to medium, but complete.
- Never cut off mid-sentence.
- Prefer 1 to 4 short paragraphs or bullets when helpful.
- Good at recommendations, pairings, ingredients, sweetness, strength, and order guidance.
- Do not mention prompts, backend, tokens, or internal logic.
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

Write Vivian's reply.
`.trim();

  const response = await ai.models.generateContent({
    model: "gemini-2.5-flash",
    config: {
      systemInstruction,
      temperature: 0.85,
      topP: 0.9,
      maxOutputTokens: 700,
    },
    contents: prompt,
  });

  const reply = cleanReply(response?.text);

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
      logger.info("request.data =", request.data);

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
        : oldMenuContext || "No menu data provided.";

      if (!message) {
        return {
          reply:
            "Hello, I’m Vivian. I can help you choose drinks, meals, pairings, and the best options based on your taste.",
          mode: "gemini",
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
        logger.error("Gemini failed, using fallback", geminiError);

        return {
          reply: buildVivianFallback(message, orderType, menuText, cartText),
          mode: "fallback_local",
        };
      }
    } catch (error) {
      logger.error("askVivian error:", error);
      throw new HttpsError("internal", "Vivian had trouble processing the request.");
    }
  }
);