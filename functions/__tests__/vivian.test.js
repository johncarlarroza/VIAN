const { __test } = require("../index");

const {
  safeString,
  safeList,
  toNumber,
  peso,
  cleanReply,
  formatCart,
  formatMenu,
  buildVivianFallback,
  findMenuMatch,
  getAffordableItems,
  summarizeCart,
} = __test;

// Sample menu
const menuItems = [
  {
    id: "burger_steak",
    name: "Burger Steak",
    categoryId: "meals",
    description: "A filling rice meal.",
    prices: { withDrink: 89, withoutDrink: 80 },
    availableVariants: ["withDrink", "withoutDrink"],
    isAvailable: true,
    isBestSeller: true,
    tags: ["food"],
    sortOrder: 1,
  },
  {
    id: "spanish_latte",
    name: "Spanish Latte",
    categoryId: "drinks",
    description: "A sweet coffee.",
    prices: { hot: 95, iced12: 105 },
    availableVariants: ["hot", "iced12"],
    isAvailable: true,
    tags: ["coffee"],
    sortOrder: 2,
  },
  {
    id: "hidden",
    name: "Hidden Item",
    prices: { hot: 999 },
    isAvailable: false,
  },
];

const menuText = formatMenu(menuItems);

describe("Vivian AI Unit Tests", () => {

  test("safeString null", () => {
    expect(safeString(null)).toBe("");
  });

  test("toNumber valid", () => {
    expect(toNumber("100")).toBe(100);
  });

  test("toNumber fallback", () => {
    expect(toNumber("abc", 5)).toBe(5);
  });

  test("peso format", () => {
    expect(peso(150)).toBe("₱150.00");
  });

  test("cleanReply removes markdown", () => {
    expect(cleanReply("**Hello**")).toBe("Hello");
  });

});

describe("Vivian AI Integration Tests", () => {

  test("formatMenu includes items", () => {
    expect(menuText).toContain("Burger Steak");
    expect(menuText).toContain("Spanish Latte");
  });

  test("formatMenu hides unavailable", () => {
    expect(menuText).not.toContain("Hidden Item");
  });

  test("findMenuMatch works", () => {
    const match = findMenuMatch("Tell me about Spanish Latte", menuText);
    expect(match).toContain("Spanish Latte");
  });

  test("getAffordableItems works", () => {
    const items = getAffordableItems(menuText, 2);
    expect(items.length).toBeGreaterThan(0);
  });

  test("cart summary works", () => {
    const cartText = formatCart([
      { name: "Burger Steak", variant: "withDrink", quantity: 1, price: 89 }
    ]);

    const summary = summarizeCart(cartText);

    expect(cartText).toContain("Burger Steak");
    expect(summary).toContain("1 item");
  });

  test("fallback greeting", () => {
    const reply = buildVivianFallback(
      "Hi",
      "dine_in",
      menuText,
      "Cart is empty."
    );

    expect(reply).toContain("Hello");
  });

  test("fallback empty cart", () => {
    const reply = buildVivianFallback(
      "What is in my cart?",
      "dine_in",
      menuText,
      "Cart is empty."
    );

    expect(reply.toLowerCase()).toContain("empty");
  });

  test("fallback cart with items", () => {
    const cartText = formatCart([
      { name: "Burger Steak", variant: "withDrink", quantity: 1, price: 89 }
    ]);

    const reply = buildVivianFallback(
      "What is in my cart?",
      "dine_in",
      menuText,
      cartText
    );

    expect(reply).toContain("Burger Steak");
  });

  test("fallback coffee recommendation", () => {
    const reply = buildVivianFallback(
      "I want coffee",
      "dine_in",
      menuText,
      "Cart is empty."
    );

    expect(reply).toContain("Spanish Latte");
  });

  test("fallback unrelated request", () => {
    const reply = buildVivianFallback(
      "Can you book me a hotel?",
      "dine_in",
      menuText,
      "Cart is empty."
    );

    expect(reply.length).toBeGreaterThan(10);
  });

});