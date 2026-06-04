# First Principles Analysis: Payment Checkout — Adding "Buy Now" (Single-Click Purchase)

> **Scenario:** An e-commerce app has a multi-step cart checkout (Cart → Shipping → Payment → Confirmation). The team needs to add a "Buy Now" option that skips the cart and completes checkout in one click from the product detail page.

## 1. Intent

**Allow users to purchase a single product instantly from any product page.** The core capability is "complete a purchase." Multi-step cart and one-click checkout are just different process flows for the same outcome.

## 2. Current Design Critique

The existing checkout flow is structured as a page-per-step state machine:

```
class CheckoutController:
    def cart_step(request):
        # show cart items, let user edit quantities
        return render_cart_page()

    def shipping_step(request):
        # collect shipping address
        return render_shipping_form()

    def payment_step(request):
        # process payment with selected method
        return render_payment_form()

    def confirm_step(request):
        # show order summary, finalize
        order = create_order(cart.items, address, payment)
        return render_confirmation(order)
```

Each step persists data to the user's session; `confirm_step` reads accumulated session state and calls `create_order`.

**Coupling:** `create_order` is tightly coupled to the multi-step session model. It reads `cart.items` (expecting a full Cart object), `address` (expecting a validated ShippingAddress), and `payment` (expecting a PaymentIntent). Any new flow must populate all three in session first.

**Abstraction boundary violation:** The checkout controller knows too much about session structure. The session is used as both transport (data between steps) and persistence (order drafts), making it hard to differentiate "new purchase" from "resume abandoned cart."

**Hidden assumption:** Every purchase requires a full Cart object with multiple items. The entire data model assumes `order_items` originates from `cart.items`. A single-item purchase must first create a cart — an unnatural step that leaks implementation detail into the user experience.

**Extension cost:** Adding "Buy Now" would require:
1. Creating a synthetic single-item cart and injecting it into the session
2. Skipping the cart/shipping steps by pre-populating session data from defaults
3. Adding a branch in the routing logic: "if Buy Now, bypass steps 1-2"
4. Handling edge cases: what if the user has an existing cart? Merge? Replace?

## 2b. Assumptions Challenged

| Assumption | Category | Challenge | Verdict |
|------------|----------|-----------|---------|
| "Every purchase starts from a cart" | Technical | Buy Now is a different entry point altogether, not a shortcut | ❌ Discard |
| "Checkout must be multi-step" | Business | One-click purchase is a well-established UX pattern; steps are UI concerns, not business logic | ❌ Discard |
| "Session is the right transport" | Technical | Session was chosen for the multi-step flow; Buy Now has no intermediate steps → no reason to go through session | ❌ Discard |
| "`create_order` should accept a full Cart" | Historical | Cart is an aggregate that includes items, discounts, shipping estimates. Buy Now needs only item_id + qty + price | ❌ Discard |

## 3. Clean-Sheet Design

From first principles: a purchase has **products**, **buyer info**, **payment**, and an **order result**. The complexity of how they're collected (multi-step vs. one-click) is a UI concern, not an order-processing concern.

```
# Core order service — knows nothing about UI flows
class OrderService:
    def place_order(self, items: list[OrderItem],
                    buyer: BuyerInfo,
                    payment: PaymentMethod) -> Order:
        # validate stock, calculate total, process payment, create order
        ...

# UI-layer flow adapters
class MultiStepCheckoutFlow:
    def __init__(self, service: OrderService, session):
        self.service = service
        self.session = session

    def execute(self) -> Order:
        # read accumulated session data
        items = self.session.get_items()
        buyer = self.session.get_buyer()
        payment = self.session.get_payment()
        return self.service.place_order(items, buyer, payment)

class BuyNowFlow:
    def __init__(self, service: OrderService):
        self.service = service

    def execute(self, product_id: str, buyer: BuyerInfo,
                payment: PaymentMethod) -> Order:
        items = [OrderItem(product_id=product_id, quantity=1)]
        return self.service.place_order(items, buyer, payment)
```

**Key decisions:**
- **`OrderService.place_order`** is the single source of truth for creating orders. It takes structured inputs, not session objects.
- **Flow adapters** translate UI flow semantics into `place_order` arguments. No shared state between flows.
- **`OrderItem`** is the fundamental building block for what goes into an order. Cart is one way to collect `OrderItem[]`; direct selection is another.

## 4. Gap Analysis

| Aspect | Current | Ideal | Delta |
|--------|---------|-------|-------|
| Order creation | Reads from session (cart, saved address, saved payment) | `place_order(items, buyer, payment)` | Decouple from session |
| Entry point | Must flow through cart → shipping → payment → confirm | Any flow adapter produces same `OrderService` call | Flow adapters abstract routing |
| Single-item purchase | Create synthetic cart in session, bypass steps | `BuyNowFlow` constructs `OrderItem[]` directly | No session dependency |
| Extension (gift purchase, subscription) | Would need yet another session injection hack | Add `GiftFlow`, `SubscriptionFlow` as new adapters | Add, don't modify |

## 5. Path Comparison

### Path A: Minimal Modification

Create a "shortcut" route that populates the session with a single-item cart and redirects to the payment step:

```python
def buy_now(request, product_id):
    cart = Cart()
    cart.add(product_id, qty=1)
    request.session['cart'] = cart
    request.session['skip_shipping'] = True  # flag for existing shipping step
    return redirect('checkout:payment')
```

**Pros:** ~15 lines changed, zero architecture changes.

**Costs:**
- New `skip_shipping` flag adds implicit state machine complexity
- Existing cart session code now handles two incompatible cases
- What if user has items in cart? Silent merge? Replace with alert? Undefined
- Gift purchases, subscriptions would each need their own session flags
- Testing complexity: `session` now has "normal cart + skip_shipping=False" and "synthetic cart + skip_shipping=True" states

### Path B: First-Principles Refactor

1. **Extract `OrderService`** from the controller (1 new file)
2. **Introduce `OrderItem`** as value object (1 new file/modification)
3. **Convert existing multi-step flow into `MultiStepCheckoutFlow` adapter** (1 refactored file)
4. **Implement `BuyNowFlow`** (1 new file)
5. **Wire controllers to use flow adapters** instead of direct session manipulation (1 modified file)

**Pros:**
- `place_order` is testable without session mocks
- Next flow (gift, subscription, recurring) is a new adapter, not a controller modification
- Session remains only in the multi-step flow, where it naturally belongs
- Each flow has clear lifecycle — no shared implicit state

**Costs & risks:**
- ~5 files changed/created, ~150 lines
- Refactoring existing multi-step flow: must ensure session data extraction matches `place_order` contract exactly
- Regression risk if shipping/payment steps have implicit validation not captured in `BuyerInfo`
- Team must agree on the new boundary (is this over-engineered for a small codebase?)

## 6. Recommendation

**Recommend: Path A** (Minimal Modification), with a documented refactoring trigger.

### Decision framework

| Heuristic | Path A | Path B |
|-----------|--------|--------|
| Diff size | 1 file / ~15 lines | 5 files / ~150 lines |
| Risk | Very low | Medium (refactoring multi-step flow) |
| Design debt | Moderate (`skip_shipping` flag accumulates) | Eliminated |
| Future extension cost | Each new flow = new flag | Each new flow = new adapter |
| Incremental? | N/A | ✅ Strangler Fig (extract flows one by one) |

1. **Touch frequency:** The team is building an MVP. "Buy Now" is likely the only non-standard flow in the next 3 months. The checkout code won't be touched frequently in the near term → Path A is acceptable.

2. **Provably wrong vs. merely suboptimal:** The current design is *merely suboptimal* for a single addition. It only becomes provably wrong when 3+ flow types coexist with session flags. Currently at 2 (normal + buy now), which is manageable.

3. **Strangler Fig test:** ✅ Path B can be done incrementally, but the cost of doing so (extracting the multi-step flow) is significant relative to the immediate need.

4. **Compounding debt test:** Anticipated 1-2 more touches before the design debt causes real pain (gift purchase in Q3). Track this — when the next non-standard flow arrives, do the refactoring.

### Actionable next step

```
Step 1: Implement Path A (add buy_now route + skip_shipping flag)
  → verify: Buy Now works for logged-in users with a default address

Step 2: Add a `TODO.md` note:
  "When adding the 3rd checkout flow type, refactor OrderService
   out of the controller first — current session-flag approach
   doesn't scale past 3 variants."

Step 3 (future, when refactoring trigger fires):
  Extract OrderService → OrderItem → flow adapters → wire controllers
```

This keeps the MVP moving while acknowledging that the shortcut approach has a limited shelf life. The documented trigger prevents the team from accidentally adding a 4th flag three months from now without awareness.