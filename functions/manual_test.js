const { __test } = require("./index");

let pass = 0;
let fail = 0;

function check(id, condition, expected, actual) {
  if (condition) {
    console.log(`✅ ${id} PASS`);
    pass++;
  } else {
    console.log(`❌ ${id} FAIL`);
    console.log(`   Expected: ${expected}`);
    console.log(`   Actual: ${actual}`);
    fail++;
  }
}

const {
  safeString,
  safeList,
  toNumber,
  peso,
  cleanReply,
  clampText,
  normalizeVariantLabel,
  uniqueStrings,
  normalizeProduct,
  formatCart,
  formatMenu,
  normalizeLegacyMenuContext,
  extractMenuBlocks,
  getItemNameFromBlock,
  getFieldFromBlock,
  parsePriceValues,
  dedupeBlocksByName,
  findMenuMatch,
  findItemsByKeyword,
  getBestSellerItems,
  getAffordableItems,
  summarizeCart,
  inferPreferenceKeywords,
  buildPairingSuggestion,
  buildVivianFallback,
} = __test;

const menuItems = [
  {
    id: "1",
    name: "Caffe Latte",
    category: "coffee",
    description: "Smooth espresso with milk.",
    prices: { hot: 120, iced12: 140 },
    availableVariants: ["hot", "iced12"],
    isAvailable: true,
    isBestSeller: true,
    tags: ["coffee", "bestseller"],
    ingredients: ["espresso", "milk"],
    sortOrder: 2,
  },
  {
    id: "2",
    name: "Americano",
    category: "coffee",
    description: "Bold black coffee.",
    prices: { hot: 90 },
    availableVariants: ["hot"],
    isAvailable: true,
    tags: ["coffee"],
    sortOrder: 1,
  },
  {
    id: "3",
    name: "Chocolate Cake",
    category: "dessert",
    description: "Sweet chocolate dessert.",
    prices: { slice: 150 },
    availableVariants: ["slice"],
    isAvailable: true,
    tags: ["dessert", "sweet"],
    sortOrder: 3,
  },
  {
    id: "4",
    name: "Hidden Product",
    category: "coffee",
    prices: { hot: 999 },
    isAvailable: false,
    tags: ["coffee"],
    sortOrder: 4,
  },
];

const menuText = formatMenu(menuItems);
const cartText = formatCart([
  { name: "Caffe Latte", variant: "hot", quantity: 2, price: 120 },
  { name: "Chocolate Cake", variant: "slice", quantity: 1, price: 150 },
]);

console.log("\n========== VIAN VIVIAN AI TERMINAL TEST ==========\n");

// UNIT TESTS
check("UT-01 safeString null", safeString(null) === "", "", safeString(null));
check("UT-02 safeList array", safeList(["a"]).length === 1, "array length 1", safeList(["a"]).length);
check("UT-03 safeList invalid", safeList("abc").length === 0, "empty array", safeList("abc").length);
check("UT-04 toNumber valid", toNumber("99") === 99, 99, toNumber("99"));
check("UT-05 toNumber fallback", toNumber("abc", 5) === 5, 5, toNumber("abc", 5));
check("UT-06 peso", peso(150) === "₱150.00", "₱150.00", peso(150));
check("UT-07 cleanReply", cleanReply("**Hello**") === "Hello", "Hello", cleanReply("**Hello**"));

const longText = "a".repeat(13000);
check(
  "UT-08 clampText",
  clampText(longText, 12000).includes("[Context trimmed for length]"),
  "contains trim notice",
  clampText(longText, 12000).slice(-40)
);

check("UT-09 normalize hot", normalizeVariantLabel("hot") === "Hot", "Hot", normalizeVariantLabel("hot"));
check("UT-10 normalize iced12", normalizeVariantLabel("iced12") === "Iced 12oz", "Iced 12oz", normalizeVariantLabel("iced12"));

check(
  "UT-11 uniqueStrings",
  uniqueStrings(["Latte", "latte", "LATTE"]).length === 3,
  "3 because function is case-sensitive",
  uniqueStrings(["Latte", "latte", "LATTE"]).length
);

const normalized = normalizeProduct({
  name: "Test Product",
  tags: ["best seller"],
  prices: { hot: "100" },
});

check("UT-12 normalizeProduct name", normalized.name === "Test Product", "Test Product", normalized.name);
check("UT-13 normalizeProduct best seller from tag", normalized.isBestSeller === true, true, normalized.isBestSeller);

// FORMAT TESTS
check("FT-01 formatCart includes Latte", cartText.includes("Caffe Latte"), "contains Caffe Latte", cartText);
check("FT-02 formatCart includes subtotal", cartText.includes("Subtotal: ₱240.00"), "Subtotal ₱240.00", cartText);
check("FT-03 formatMenu hides unavailable", !menuText.includes("Hidden Product"), "Hidden Product hidden", menuText);
check("FT-04 formatMenu includes best seller", menuText.includes("Best Seller: Yes"), "Best Seller: Yes", menuText);
check("FT-05 extractMenuBlocks", extractMenuBlocks(menuText).length === 3, 3, extractMenuBlocks(menuText).length);

// PARSING TESTS
const firstBlock = extractMenuBlocks(menuText)[0];
check("PT-01 getItemNameFromBlock", getItemNameFromBlock(firstBlock) === "Americano", "Americano", getItemNameFromBlock(firstBlock));
check("PT-02 getFieldFromBlock Price", getFieldFromBlock(firstBlock, "Price").includes("₱90.00"), "contains ₱90.00", getFieldFromBlock(firstBlock, "Price"));
check("PT-03 parsePriceValues", parsePriceValues(firstBlock)[0] === 90, 90, parsePriceValues(firstBlock)[0]);

const duplicateBlocks = [
  "1. Americano\nPrice: ₱90.00",
  "2. Americano\nPrice: ₱90.00",
  "3. Caffe Latte\nPrice: ₱120.00",
];

check("PT-04 dedupeBlocksByName", dedupeBlocksByName(duplicateBlocks).length === 2, 2, dedupeBlocksByName(duplicateBlocks).length);

// SEARCH TESTS
check("ST-01 findMenuMatch latte", findMenuMatch("Do you have latte?", menuText)?.includes("Caffe Latte"), "Caffe Latte match", findMenuMatch("Do you have latte?", menuText));
check("ST-02 findMenuMatch unknown", findMenuMatch("Do you have pizza?", menuText) === null, null, findMenuMatch("Do you have pizza?", menuText));
check("ST-03 findItemsByKeyword coffee", findItemsByKeyword(menuText, ["coffee"]).length === 2, 2, findItemsByKeyword(menuText, ["coffee"]).length);
check("ST-04 getBestSellerItems", getBestSellerItems(menuText).length === 1, 1, getBestSellerItems(menuText).length);
check("ST-05 getAffordableItems", getAffordableItems(menuText, 2)[0].name === "Americano", "Americano", getAffordableItems(menuText, 2)[0]?.name);

// CART / PREFERENCE TESTS
check("CT-01 summarizeCart", summarizeCart(cartText).includes("2 items"), "2 items", summarizeCart(cartText));
check("CT-02 summarizeCart empty", summarizeCart("Cart is empty.") === null, null, summarizeCart("Cart is empty."));

const prefsCoffee = inferPreferenceKeywords("I want iced latte");
check("PF-01 wantsCoffee", prefsCoffee.wantsCoffee === true, true, prefsCoffee.wantsCoffee);
check("PF-02 wantsCold", prefsCoffee.wantsCold === true, true, prefsCoffee.wantsCold);

const prefsBudget = inferPreferenceKeywords("cheap affordable please");
check("PF-03 wantsBudget", prefsBudget.wantsBudget === true, true, prefsBudget.wantsBudget);

const pairing = buildPairingSuggestion(menuText, "coffee and dessert");
check("PF-04 buildPairingSuggestion", pairing.includes("Caffe Latte") && pairing.includes("Chocolate Cake"), "Latte + Cake pairing", pairing);

// FALLBACK SYSTEM TESTS
check("FB-01 greeting", buildVivianFallback("hi", "dine_in", menuText, cartText).includes("Hello"), "Hello greeting", buildVivianFallback("hi", "dine_in", menuText, cartText));
check("FB-02 cart", buildVivianFallback("what is in my cart", "dine_in", menuText, cartText).includes("Caffe Latte"), "cart includes Caffe Latte", buildVivianFallback("what is in my cart", "dine_in", menuText, cartText));
check("FB-03 budget", buildVivianFallback("something cheap", "dine_in", menuText, cartText).includes("Americano"), "Americano", buildVivianFallback("something cheap", "dine_in", menuText, cartText));
check("FB-04 best seller", buildVivianFallback("best seller please", "dine_in", menuText, cartText).includes("Caffe Latte"), "Caffe Latte", buildVivianFallback("best seller please", "dine_in", menuText, cartText));
check("FB-05 coffee", buildVivianFallback("I want coffee", "dine_in", menuText, cartText).includes("Americano") || buildVivianFallback("I want coffee", "dine_in", menuText, cartText).includes("Caffe Latte"), "coffee recommendation", buildVivianFallback("I want coffee", "dine_in", menuText, cartText));
check("FB-06 dessert", buildVivianFallback("I want dessert", "dine_in", menuText, cartText).includes("Chocolate Cake"), "Chocolate Cake", buildVivianFallback("I want dessert", "dine_in", menuText, cartText));
check("FB-07 recommend", buildVivianFallback("recommend something", "dine_in", menuText, cartText).length > 10, "non-empty recommendation", buildVivianFallback("recommend something", "dine_in", menuText, cartText));
check("FB-08 direct item", buildVivianFallback("Tell me about Americano", "dine_in", menuText, cartText).includes("Americano"), "Americano details", buildVivianFallback("Tell me about Americano", "dine_in", menuText, cartText));
check("FB-09 no menu", buildVivianFallback("recommend", "dine_in", "No menu data provided.", "Cart is empty.").length > 10, "safe fallback", buildVivianFallback("recommend", "dine_in", "No menu data provided.", "Cart is empty."));

// LEGACY MENU TEST
const legacy = normalizeLegacyMenuContext("1. Matcha Latte | category: drinks | description: Green tea drink | variants: hot, iced12 | prices: hot ₱130 | tags: bestseller");
check("LG-01 legacy menu normalize", legacy.includes("Matcha Latte"), "Matcha Latte", legacy);
check("LG-02 legacy best seller", legacy.includes("Best Seller: Yes"), "Best Seller: Yes", legacy);

console.log("\n==============================");
console.log(`TOTAL TESTS: ${pass + fail}`);
console.log(`PASSED: ${pass}`);
console.log(`FAILED: ${fail}`);
console.log(`PASS RATE: ${Math.round((pass / (pass + fail)) * 100)}%`);
console.log("==============================\n");

if (fail > 0) {
  process.exitCode = 1;
}