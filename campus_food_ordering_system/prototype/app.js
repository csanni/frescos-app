// ═══════════════ MENU DATA ═══════════════
var menuItems = [
    { id: 1, name: "Margherita Pizza", desc: "Classic hand-tossed pizza with fresh mozzarella, basil & tomato sauce", price: 199, veg: true, color: "#E53935", icon: "local_pizza", category: "pizza" },
    { id: 2, name: "Pepperoni Feast", desc: "Loaded with double pepperoni, mozzarella & our signature spicy sauce", price: 349, veg: false, color: "#D84315", icon: "local_pizza", category: "pizza" },
    { id: 3, name: "Farmhouse Veggie", desc: "Bell peppers, mushrooms, onions, olives & sweet corn on a cheesy base", price: 279, veg: true, color: "#4CAF50", icon: "local_pizza", category: "pizza" },
    { id: 4, name: "BBQ Chicken Pizza", desc: "Smoky BBQ chicken, caramelized onions & jalapenos", price: 379, veg: false, color: "#FF6F00", icon: "local_pizza", category: "pizza" },
    { id: 5, name: "Salmon Sushi Roll", desc: "Fresh Atlantic salmon, avocado & cucumber wrapped in seasoned rice", price: 349, veg: false, color: "#F44336", icon: "set_meal", category: "japanese" },
    { id: 6, name: "Chicken Ramen", desc: "Rich tonkotsu broth with chashu pork, soft-boiled egg & noodles", price: 299, veg: false, color: "#FF7043", icon: "ramen_dining", category: "japanese" },
    { id: 7, name: "Vegetable Tempura", desc: "Crispy battered sweet potato, broccoli, zucchini & bell peppers", price: 229, veg: true, color: "#FFC107", icon: "restaurant", category: "japanese" },
    { id: 8, name: "Edamame Bowl", desc: "Steamed salted soybeans - the perfect healthy starter", price: 129, veg: true, color: "#66BB6A", icon: "eco", category: "japanese" },
    { id: 9, name: "Garlic Breadsticks", desc: "Oven-baked garlic bread with herb butter & cheese dip", price: 129, veg: true, color: "#FFB300", icon: "bakery_dining", category: "sides" },
    { id: 10, name: "Miso Soup", desc: "Traditional Japanese soup with tofu, wakame seaweed & scallions", price: 99, veg: true, color: "#8D6E63", icon: "soup_kitchen", category: "japanese" },
    { id: 11, name: "Cold Coffee", desc: "Chilled coffee blended with vanilla ice cream", price: 89, veg: true, color: "#795548", icon: "local_cafe", category: "beverages" },
    { id: 12, name: "Matcha Latte", desc: "Ceremonial grade Japanese matcha with steamed oat milk", price: 149, veg: true, color: "#558B2F", icon: "emoji_food_beverage", category: "beverages" },
    { id: 13, name: "Fresh Lime Soda", desc: "Refreshing lime soda with mint leaves & ice", price: 59, veg: true, color: "#7CB342", icon: "local_bar", category: "beverages" },
    { id: 14, name: "Mango Smoothie", desc: "Thick creamy mango smoothie with real Alphonso mango pulp", price: 129, veg: true, color: "#FFA726", icon: "local_cafe", category: "beverages" },
    { id: 15, name: "Choco Lava Cake", desc: "Warm chocolate cake with a gooey molten center", price: 109, veg: true, color: "#4E342E", icon: "cake", category: "desserts" },
    { id: 16, name: "Mochi Ice Cream", desc: "Japanese rice cake filled with creamy green tea ice cream", price: 119, veg: true, color: "#9CCC65", icon: "icecream", category: "desserts" },
    { id: 17, name: "Tiramisu", desc: "Classic Italian coffee-flavoured dessert with mascarpone cream", price: 159, veg: true, color: "#8D6E63", icon: "cake", category: "desserts" },
    { id: 18, name: "Cheesecake Slice", desc: "New York style baked cheesecake with berry compote", price: 179, veg: true, color: "#E91E63", icon: "cake", category: "desserts" },
    { id: 19, name: "Pizza Combo for 2", desc: "2 Medium Pizzas, 1 Garlic Breadsticks, 2 Cold Coffees", price: 799, veg: false, color: "#E91E63", icon: "restaurant_menu", category: "combo" },
    { id: 20, name: "Sushi & Ramen Meal", desc: "1 Salmon Sushi Roll, 1 Chicken Ramen, 1 Matcha Latte", price: 649, veg: false, color: "#9C27B0", icon: "set_meal", category: "combo" },
    { id: 21, name: "Family Feast", desc: "3 Large Pizzas, 2 Sides, 4 Cold Coffees, 2 Desserts", price: 1499, veg: false, color: "#FF5722", icon: "restaurant_menu", category: "combo" },
    { id: 22, name: "Cheesy Fries", desc: "Crispy fries loaded with melted cheddar & mozzarella", price: 149, veg: true, color: "#F9A825", icon: "fastfood", category: "sides" },
    { id: 23, name: "Chicken Wings", desc: "6 pcs crispy fried wings tossed in buffalo sauce", price: 199, veg: false, color: "#D84315", icon: "restaurant", category: "sides" },
];

// ═══════════════ APP STATE ═══════════════
var cartItems = [];
var orderCounter = 42;
var orders = [];
var notifications = [
    { title: "New: Japanese Menu! \uD83C\uDF63", text: "Try our brand new sushi rolls, ramen & mochi - available now!", time: "10:00 AM", type: "promo", unread: true },
    { title: "Buy 1 Get 1 Free! \uD83C\uDF55", text: "BOGO on all medium pizzas this Saturday! Use code PIZZABOGO.", time: "Yesterday", type: "promo", unread: false },
    { title: "App Updated", text: "Fresco's app updated with Japanese cuisine & live tracking.", time: "2 days ago", type: "system", unread: false },
];
var currentQty = 1;
var activeCategory = 'all';
var _handlingPopstate = false;
var activeOrderId = null;
var trackingTimers = {};

// ═══════════════ HELPERS ═══════════════
function formatTime(date) {
    var h = date.getHours();
    var m = date.getMinutes();
    var ampm = h >= 12 ? 'PM' : 'AM';
    h = h % 12 || 12;
    return h + ':' + (m < 10 ? '0' : '') + m + ' ' + ampm;
}

function generateOrderId() {
    orderCounter++;
    var now = new Date();
    var y = now.getFullYear();
    var mo = ('0' + (now.getMonth() + 1)).slice(-2);
    var d = ('0' + now.getDate()).slice(-2);
    return 'PIZ-' + y + mo + d + '-' + ('0000' + orderCounter).slice(-4);
}

function getCartTotal() {
    return cartItems.reduce(function (s, i) { return s + i.price * i.qty; }, 0);
}

function getCartCount() {
    return cartItems.reduce(function (s, i) { return s + i.qty; }, 0);
}

function getDeliveryCharge() {
    var total = getCartTotal();
    return total >= 500 ? 0 : 30;
}

function getGrandTotal() {
    return getCartTotal() + getDeliveryCharge();
}

function getSelectedDeliveryType() {
    return 'delivery'; // delivery only mode
}

function getSelectedPaymentMethod() {
    return 'cash'; // cash on delivery only
}

// ═══════════════ INIT ═══════════════
document.addEventListener('DOMContentLoaded', function () {
    renderMenu();
    renderCart();
    updateCartTotals();
    renderOrders();
    renderNotifications();
    setupRadioGroups();
    setupCategoryTabs();

    history.replaceState({ screen: 'screen-splash' }, '');
    setTimeout(function () { navigateTo('screen-login'); }, 2500);

    window.addEventListener('popstate', function (e) {
        if (e.state && e.state.screen) {
            _handlingPopstate = true;
            showScreen(e.state.screen);
            _handlingPopstate = false;
        }
    });
});

// ═══════════════ SCREEN SWITCHING ═══════════════
function showScreen(screenId) {
    var allScreens = document.querySelectorAll('.screen');
    for (var i = 0; i < allScreens.length; i++) {
        if (allScreens[i].classList.contains('active') && allScreens[i].id !== screenId) {
            allScreens[i].classList.remove('active');
        }
    }
    var next = document.getElementById(screenId);
    if (next) {
        next.classList.add('active');
        next.scrollTop = 0;
    }
    var tabMap = { 'screen-home': 'menu', 'screen-orders': 'orders', 'screen-notifications': 'notifications', 'screen-profile': 'profile' };
    if (tabMap[screenId]) {
        document.querySelectorAll('.nav-item').forEach(function (ni) {
            ni.classList.toggle('active', ni.dataset.tab === tabMap[screenId]);
        });
    }
}

// ═══════════════ NAVIGATION ═══════════════
function navigateTo(screenId) {
    var current = document.querySelector('.screen.active');
    if (current && current.id === screenId) return;
    showScreen(screenId);
    if (!_handlingPopstate) {
        history.pushState({ screen: screenId }, '');
    }
}

function goBack() {
    history.back();
}

function switchTab(tab) {
    var screenMap = { menu: 'screen-home', orders: 'screen-orders', notifications: 'screen-notifications', profile: 'screen-profile' };
    var targetScreenId = screenMap[tab];
    if (!targetScreenId) return;
    var current = document.querySelector('.screen.active');
    if (current && current.id === targetScreenId) return;
    showScreen(targetScreenId);
    if (!_handlingPopstate) {
        history.pushState({ screen: targetScreenId }, '');
    }
}

// ═══════════════ RENDER MENU ═══════════════
function renderMenu(filter) {
    var cat = filter || activeCategory;
    activeCategory = cat;
    var list = document.getElementById('menu-list');
    var items = cat === 'all' ? menuItems : menuItems.filter(function (i) { return i.category === cat; });

    if (items.length === 0) {
        list.innerHTML = '<div style="text-align:center;padding:40px 20px;color:var(--text-hint);"><span class="material-icons-round" style="font-size:48px;opacity:0.3;">search_off</span><p style="margin-top:8px;font-size:14px;font-weight:600;">No items in this category</p></div>';
        return;
    }

    list.innerHTML = items.map(function (item, i) {
        var icon = item.icon || 'local_pizza';
        var cartItem = cartItems.find(function (c) { return c.id === item.id; });
        var inCart = cartItem ? cartItem.qty : 0;

        var addSection;
        if (inCart > 0) {
            addSection = '<div class="menu-qty-inline">' +
                '<button class="menu-qty-btn" onclick="event.stopPropagation();changeCartQty(' + item.id + ',-1)">\u2212</button>' +
                '<span class="menu-qty-val">' + inCart + '</span>' +
                '<button class="menu-qty-btn" onclick="event.stopPropagation();changeCartQty(' + item.id + ',1)">+</button>' +
                '</div>';
        } else {
            addSection = '<button class="btn-add-small" onclick="event.stopPropagation();addToCartQuick(' + item.id + ')">ADD</button>';
        }

        return '<div class="menu-card" style="animation-delay:' + i * 0.06 + 's" onclick="openItemDetail(' + item.id + ')">' +
            '<div class="menu-card-img">' +
            '<div class="menu-card-img-inner" style="background:linear-gradient(135deg,' + item.color + ',' + item.color + 'dd);display:flex;align-items:center;justify-content:center;">' +
            '<span class="material-icons-round" style="font-size:36px;color:rgba(255,255,255,0.85);">' + icon + '</span>' +
            '</div></div>' +
            '<div class="menu-card-body">' +
            '<div class="menu-card-top"><div>' +
            '<div class="menu-card-name">' + item.name + '</div>' +
            '<div class="menu-card-desc">' + item.desc + '</div>' +
            '</div>' +
            '<div class="veg-badge"><span class="veg-dot ' + (item.veg ? 'veg' : 'non-veg') + '"></span></div></div>' +
            '<div class="menu-card-bottom">' +
            '<span class="menu-card-price">\u20B9 ' + item.price + '</span>' +
            addSection +
            '</div></div></div>';
    }).join('');
}

// ═══════════════ CART RENDERING ═══════════════
function renderCart() {
    var list = document.getElementById('cart-items');
    if (!list) return;

    if (cartItems.length === 0) {
        list.innerHTML = '<div class="cart-empty-state">' +
            '<span class="material-icons-round" style="font-size:64px;opacity:0.3;color:var(--text-hint);">shopping_cart</span>' +
            '<p style="margin-top:12px;font-size:16px;font-weight:600;color:var(--text-primary);">Your cart is empty</p>' +
            '<p style="font-size:13px;margin-top:4px;color:var(--text-hint);">Add some delicious items from the menu!</p>' +
            '<button class="btn-browse-menu" onclick="navigateTo(\'screen-home\')">Browse Menu</button>' +
            '</div>';
        var summarySection = document.querySelector('.cart-summary-section');
        if (summarySection) summarySection.style.display = 'none';
        return;
    }

    var summarySection = document.querySelector('.cart-summary-section');
    if (summarySection) summarySection.style.display = 'block';

    list.innerHTML = cartItems.map(function (item) {
        var icon = item.icon || 'local_pizza';
        return '<div class="cart-item-tile" data-item-id="' + item.id + '">' +
            '<div class="cart-item-img">' +
            '<div class="cart-item-img-inner" style="background:linear-gradient(135deg,' + item.color + ',' + item.color + 'dd);display:flex;align-items:center;justify-content:center;">' +
            '<span class="material-icons-round" style="font-size:24px;color:rgba(255,255,255,0.85);">' + icon + '</span>' +
            '</div></div>' +
            '<div class="cart-item-info">' +
            '<div class="cart-item-name-row">' +
            '<div class="veg-badge veg-badge-sm"><span class="veg-dot ' + (item.veg ? 'veg' : 'non-veg') + '"></span></div>' +
            '<span class="cart-item-name">' + item.name + '</span>' +
            '</div>' +
            '<span class="cart-item-price">\u20B9 ' + item.price + ' each</span>' +
            '</div>' +
            '<div class="cart-item-right">' +
            '<span class="cart-item-total">\u20B9 ' + (item.price * item.qty) + '</span>' +
            '<div class="cart-qty">' +
            '<button class="cart-qty-btn" onclick="changeCartQty(' + item.id + ', -1)">\u2212</button>' +
            '<span class="cart-qty-val">' + item.qty + '</span>' +
            '<button class="cart-qty-btn" onclick="changeCartQty(' + item.id + ', 1)">+</button>' +
            '</div>' +
            '</div>' +
            '</div>';
    }).join('');
}

function updateCartTotals() {
    var subtotal = getCartTotal();
    var deliveryCharge = getDeliveryCharge();
    var total = subtotal + deliveryCharge;
    var count = getCartCount();

    var elSubtotal = document.getElementById('cart-subtotal');
    if (elSubtotal) elSubtotal.textContent = '\u20B9 ' + subtotal;

    var elDelivery = document.getElementById('cart-delivery-charge');
    if (elDelivery) {
        elDelivery.textContent = deliveryCharge > 0 ? '\u20B9 ' + deliveryCharge : 'FREE';
        elDelivery.className = deliveryCharge > 0 ? '' : 'free-tag';
    }

    var elTotal = document.getElementById('cart-total');
    if (elTotal) elTotal.textContent = '\u20B9 ' + total;

    var elCheckoutBtn = document.getElementById('checkout-total-btn');
    if (elCheckoutBtn) elCheckoutBtn.textContent = '\u20B9 ' + total;

    // Free delivery hint
    var elHint = document.getElementById('free-delivery-hint');
    if (elHint) {
        if (subtotal > 0 && subtotal < 500) {
            elHint.style.display = 'block';
            elHint.textContent = 'Add \u20B9 ' + (500 - subtotal) + ' more for free delivery';
        } else {
            elHint.style.display = 'none';
        }
    }

    // Update all cart badges
    document.querySelectorAll('.cart-badge').forEach(function (b) {
        b.textContent = count;
        b.style.display = count > 0 ? 'flex' : 'none';
    });

    // Update place order button
    document.querySelectorAll('.btn-place-order .btn-text').forEach(function (el) {
        el.textContent = 'Place Order \u2014 \u20B9 ' + total;
    });

    // Disable checkout button if empty
    var checkoutBtn = document.querySelector('.btn-checkout');
    if (checkoutBtn) {
        checkoutBtn.disabled = cartItems.length === 0;
        checkoutBtn.style.opacity = cartItems.length === 0 ? '0.5' : '1';
    }
}

// ═══════════════ CART ACTIONS ═══════════════
function addToCartQuick(id) {
    var item = menuItems.find(function (m) { return m.id === id; });
    if (!item) return;

    var existing = cartItems.find(function (c) { return c.id === id; });
    if (existing) {
        existing.qty++;
    } else {
        cartItems.push({
            id: item.id,
            name: item.name,
            price: item.price,
            veg: item.veg,
            color: item.color,
            icon: item.icon,
            category: item.category,
            qty: 1
        });
    }

    renderCart();
    updateCartTotals();
    renderMenu();
    showToast(item.name + ' added to cart!');
}

function addToCartFromDetail() {
    var detailScreen = document.getElementById('screen-item-detail');
    var itemId = parseInt(detailScreen.dataset.itemId);
    var item = menuItems.find(function (m) { return m.id === itemId; });
    if (!item) return;

    var finalPrice = parseFloat(detailScreen.dataset.finalPrice) || item.price;
    var optionsDesc = detailScreen.dataset.optionsDesc || '';

    var cartItemId = item.category === 'pizza' ? itemId + '_' + btoa(optionsDesc) : itemId;

    var existing = cartItems.find(function (c) { return c.customId === cartItemId || (!c.customId && c.id === cartItemId); });
    if (existing) {
        existing.qty += currentQty;
    } else {
        var nameWithOpts = (item.category === 'pizza' && optionsDesc) ? item.name + ' (' + optionsDesc + ')' : item.name;
        cartItems.push({
            id: item.id,
            customId: cartItemId,
            name: nameWithOpts,
            price: finalPrice,
            veg: item.veg,
            color: item.color,
            icon: item.icon,
            category: item.category,
            qty: currentQty
        });
    }

    renderCart();
    updateCartTotals();
    renderMenu();
    showToast(currentQty + 'x ' + item.name + ' added to cart!');
    setTimeout(function () { goBack(); }, 600);
}

function changeCartQty(id, delta) {
    var item = cartItems.find(function (c) { return c.id === id; });
    if (!item) return;

    item.qty += delta;
    if (item.qty <= 0) {
        cartItems = cartItems.filter(function (c) { return c.id !== id; });
    }

    renderCart();
    updateCartTotals();
    renderMenu();
}

function clearCart() {
    if (cartItems.length === 0) return;
    cartItems = [];
    renderCart();
    updateCartTotals();
    renderMenu();
    showToast('Cart cleared');
}

// ═══════════════ ITEM DETAIL ═══════════════
function openItemDetail(id) {
    var item = menuItems.find(function (m) { return m.id === id; });
    if (!item) return;
    currentQty = 1;
    var icon = item.icon || 'local_pizza';
    document.getElementById('detail-name').textContent = item.name;
    document.getElementById('detail-desc').textContent = item.desc;
    document.getElementById('detail-full-desc').textContent = item.desc + '. Made fresh to order with premium ingredients.';
    document.getElementById('qty-value').textContent = '1';
    document.getElementById('detail-hero-img').style.background = 'linear-gradient(135deg,' + item.color + ',' + item.color + 'cc)';
    document.getElementById('detail-hero-img').innerHTML = '<div style="display:flex;align-items:center;justify-content:center;height:100%;"><span class="material-icons-round" style="font-size:80px;color:rgba(255,255,255,0.3)">' + icon + '</span></div>';
    document.getElementById('detail-badge').innerHTML = '<span class="veg-dot ' + (item.veg ? 'veg' : 'non-veg') + '"></span>';
    var detailScreen = document.getElementById('screen-item-detail');
    detailScreen.dataset.itemId = id;
    detailScreen.dataset.basePrice = item.price;

    // Pizza customization section
    var custSection = document.getElementById('pizza-customization');
    if (custSection) {
        if (item.category === 'pizza') {
            custSection.style.display = 'block';
            // Reset size to medium
            var sizeRadios = document.querySelectorAll('input[name="pizza-size"]');
            sizeRadios.forEach(function (r) {
                r.checked = (r.value === 'medium');
                var label = r.closest('.radio-option');
                if (label) label.classList.toggle('active', r.value === 'medium');
            });
            // Reset addons
            document.querySelectorAll('.pizza-addon-cb').forEach(function (cb) {
                cb.checked = false;
                var label = cb.closest('.radio-option');
                if (label) label.classList.remove('active');
            });
        } else {
            custSection.style.display = 'none';
        }
    }

    updateDetailPrice();
    navigateTo('screen-item-detail');
}

function toggleAddonCb(cb) {
    var label = cb.closest('.radio-option');
    if (label) {
        if (cb.checked) label.classList.add('active');
        else label.classList.remove('active');
    }
    updateDetailPrice();
}

function updateDetailPrice() {
    var detailScreen = document.getElementById('screen-item-detail');
    if (!detailScreen) return;
    var basePrice = parseFloat(detailScreen.dataset.basePrice) || 0;
    var custSection = document.getElementById('pizza-customization');
    var extraPrice = 0;
    var optionsDesc = [];
    if (custSection && custSection.style.display !== 'none') {
        var size = document.querySelector('input[name="pizza-size"]:checked');
        if (size && size.value === 'small') { extraPrice -= 50; optionsDesc.push("Small"); }
        if (size && size.value === 'medium') { optionsDesc.push("Medium"); }
        if (size && size.value === 'large') { extraPrice += 100; optionsDesc.push("Large"); }

        document.querySelectorAll('.pizza-addon-cb:checked').forEach(function (cb) {
            extraPrice += parseFloat(cb.dataset.price);
            var title = cb.closest('.radio-option').querySelector('.radio-title');
            if (title) optionsDesc.push(title.textContent);
        });
    }
    var itemPrice = Math.max(0, basePrice + extraPrice);
    document.getElementById('detail-price').textContent = '\u20B9 ' + itemPrice;
    document.getElementById('detail-total').textContent = '\u20B9 ' + (itemPrice * currentQty);
    detailScreen.dataset.finalPrice = itemPrice;
    detailScreen.dataset.optionsDesc = optionsDesc.join(", ");
}

function changeQty(delta) {
    currentQty = Math.max(1, currentQty + delta);
    document.getElementById('qty-value').textContent = currentQty;
    updateDetailPrice();
}

// ═══════════════ CHECKOUT ═══════════════
function goToCheckout() {
    if (cartItems.length === 0) {
        showToast('Your cart is empty!');
        return;
    }
    // Beverage-only restriction
    var nonBeverageItems = cartItems.filter(function (i) { return i.category !== 'beverages' && i.category !== 'drinks'; });
    if (nonBeverageItems.length === 0) {
        showToast('Please add at least one food item before checkout.');
        return;
    }
    renderCheckoutSummary();
    updateCheckoutTotals();
    navigateTo('screen-checkout');
}

function renderCheckoutSummary() {
    var el = document.getElementById('checkout-summary');
    if (!el) return;
    var subtotal = getCartTotal();
    var deliveryCharge = getDeliveryCharge();
    var total = subtotal + deliveryCharge;

    el.innerHTML = cartItems.map(function (i) {
        return '<div class="checkout-item-row"><span>' + i.name + ' x' + i.qty + '</span><span>\u20B9 ' + (i.price * i.qty) + '</span></div>';
    }).join('') +
        '<div class="checkout-item-row" style="color:var(--text-secondary);font-size:13px;"><span>Delivery Charge</span><span class="' + (deliveryCharge === 0 ? 'free-tag' : '') + '">' + (deliveryCharge > 0 ? '\u20B9 ' + deliveryCharge : 'FREE') + '</span></div>' +
        '<div class="checkout-item-row" style="font-weight:700;color:var(--text-primary);border-top:1px solid var(--divider);padding-top:8px;margin-top:4px;"><span>Total</span><span>\u20B9 ' + total + '</span></div>';
}

function updateCheckoutTotals() {
    var total = getGrandTotal();
    document.querySelectorAll('.btn-place-order .btn-text').forEach(function (el) {
        el.textContent = 'Place Order \u2014 \u20B9 ' + total;
    });

    var modalItems = document.getElementById('modal-items-count');
    var modalTotal = document.getElementById('modal-total');
    if (modalItems) modalItems.textContent = getCartCount() + ' items';
    if (modalTotal) modalTotal.textContent = '\u20B9 ' + total;
}

function showPlaceOrderConfirm() {
    var total = getGrandTotal();

    var modalItems = document.getElementById('modal-items-count');
    var modalTotal = document.getElementById('modal-total');
    var modalDelivery = document.getElementById('modal-delivery-type');
    var modalPayment = document.getElementById('modal-payment-type');

    if (modalItems) modalItems.textContent = getCartCount() + ' items';
    if (modalTotal) modalTotal.textContent = '\u20B9 ' + total;
    if (modalDelivery) modalDelivery.textContent = 'Delivery';
    if (modalPayment) modalPayment.textContent = 'Cash on Delivery';

    document.getElementById('modal-confirm').style.display = 'flex';
}

function hideModal() {
    document.getElementById('modal-confirm').style.display = 'none';
}

function confirmOrder() {
    hideModal();
    placeOrder('cash');
}

// ═══════════════ ORDER CREATION ═══════════════
function placeOrder(paymentMethod) {
    var now = new Date();
    var orderId = generateOrderId();

    var address = '';
    var addrInput = document.getElementById('delivery-address');
    if (addrInput) address = addrInput.value;

    var instructions = '';
    var instrInput = document.querySelector('.special-instructions');
    if (instrInput) instructions = instrInput.value;

    var newOrder = {
        id: orderId,
        date: 'Today, ' + formatTime(now),
        items: cartItems.map(function (i) { return i.qty + 'x ' + i.name; }).join(', '),
        itemsList: cartItems.map(function (i) {
            return { name: i.name, qty: i.qty, price: i.price, icon: i.icon, color: i.color };
        }),
        subtotal: getCartTotal(),
        deliveryCharge: getDeliveryCharge(),
        total: getGrandTotal(),
        status: 'placed',
        statusHistory: [
            { status: 'placed', time: formatTime(now), label: 'Order Placed' }
        ],
        paymentMethod: 'cash',
        deliveryType: 'delivery',
        address: address,
        instructions: instructions,
        isPaid: false,
        createdAt: now
    };

    orders.unshift(newOrder);
    activeOrderId = orderId;

    // Add notification
    notifications.unshift({
        title: 'Order Placed! \uD83C\uDF89',
        text: 'Your order #' + orderId + ' has been placed successfully!',
        time: formatTime(now),
        type: 'order',
        unread: true
    });

    // Clear cart
    cartItems = [];
    renderCart();
    updateCartTotals();
    renderMenu();
    renderOrders();
    renderNotifications();

    // Navigate to tracking
    showOrderTracking(orderId);

    // Start simulated order progression
    startOrderProgression(orderId);

    // Auto-send WhatsApp notification to user's registered number
    autoSendWhatsApp(orderId);
}

// ═══════════════ ORDER TRACKING ═══════════════
function showOrderTracking(orderId) {
    var order = orders.find(function (o) { return o.id === orderId; });
    if (!order) return;

    activeOrderId = orderId;
    renderTrackingScreen(order);
    navigateTo('screen-tracking');
}

function renderTrackingScreen(order) {
    var trackingId = document.querySelector('.tracking-id span:last-child');
    if (trackingId) trackingId.textContent = 'Order #' + order.id;

    var trackingTime = document.querySelector('.tracking-time');
    if (trackingTime) trackingTime.textContent = order.date;

    // Estimated time - 25-30 minutes
    var etaValue = document.querySelector('.eta-value');
    if (etaValue) {
        var statusTimes = {
            placed: '~25-30 minutes',
            confirmed: '~20-25 minutes',
            ready: 'Ready for pickup!',
            delivered: 'Completed',
            cancelled: 'Cancelled'
        };
        etaValue.textContent = statusTimes[order.status] || '~25-30 minutes';
    }

    // Payment badge
    var paymentBadge = document.getElementById('tracking-payment-badge');
    if (paymentBadge) {
        paymentBadge.textContent = '\uD83D\uDCB5 Cash on Delivery';
        paymentBadge.className = 'payment-method-badge cod';
    }

    // Status stepper
    renderStatusStepper(order);

    // Slide to accept button (shown when order is ready for pickup)
    renderSlideToAccept(order);

    // Order details
    var detailsBody = document.getElementById('tracking-details-body');
    if (detailsBody && order.itemsList) {
        detailsBody.innerHTML = order.itemsList.map(function (item) {
            return '<div class="tracking-item"><span>' + item.name + ' x' + item.qty + '</span><span>\u20B9 ' + (item.price * item.qty) + '</span></div>';
        }).join('') +
            (order.deliveryCharge > 0 ? '<div class="tracking-item"><span>Delivery Charge</span><span>\u20B9 ' + order.deliveryCharge + '</span></div>' : '') +
            '<div class="tracking-item total"><span>Total</span><span>\u20B9 ' + order.total + '</span></div>';
    }

    // Cancel button visibility
    var cancelBtn = document.getElementById('cancel-order-btn');
    if (cancelBtn) {
        cancelBtn.style.display = (order.status === 'placed' || order.status === 'confirmed') ? 'flex' : 'none';
    }
}

function renderSlideToAccept(order) {
    var container = document.getElementById('slide-accept-container');
    if (!container) return;

    if (order.status === 'ready') {
        container.style.display = 'block';
        container.innerHTML =
            '<div class="slide-accept-wrapper">' +
            '<p class="slide-accept-label">\uD83C\uDF55 Your order is ready!<br>Visit the store, pay cash & collect.</p>' +
            '<div class="slide-track" id="slide-track">' +
            '<div class="slide-thumb" id="slide-thumb">' +
            '<span class="material-icons-round slide-arrow-icon">double_arrow</span>' +
            '</div>' +
            '<div class="slide-hint-arrows">' +
            '<span class="material-icons-round">chevron_right</span>' +
            '<span class="material-icons-round">chevron_right</span>' +
            '<span class="material-icons-round">chevron_right</span>' +
            '<span class="material-icons-round">chevron_right</span>' +
            '</div>' +
            '<span class="slide-text">Slide to Collect \u279C</span>' +
            '<span class="slide-text-done" style="display:none;">\u2714 Collected!</span>' +
            '</div>' +
            '<p class="slide-hint-text">\u261E Drag the green circle to the right</p>' +
            '</div>';
        initSlideToAccept(order.id);
    } else {
        container.style.display = 'none';
        container.innerHTML = '';
    }
}

function initSlideToAccept(orderId) {
    var track = document.getElementById('slide-track');
    var thumb = document.getElementById('slide-thumb');
    if (!track || !thumb) return;

    var isDragging = false;
    var startX = 0;
    var thumbLeft = 0;
    var maxLeft = 0;

    function getMaxLeft() {
        return track.offsetWidth - thumb.offsetWidth - 6;
    }

    function onStart(e) {
        isDragging = true;
        startX = (e.touches ? e.touches[0].clientX : e.clientX) - thumbLeft;
        thumb.style.transition = 'none';
        e.preventDefault();
    }

    function onMove(e) {
        if (!isDragging) return;
        maxLeft = getMaxLeft();
        var clientX = e.touches ? e.touches[0].clientX : e.clientX;
        var newLeft = clientX - startX;
        newLeft = Math.max(0, Math.min(newLeft, maxLeft));
        thumbLeft = newLeft;
        thumb.style.left = newLeft + 'px';
        e.preventDefault();
    }

    function onEnd() {
        if (!isDragging) return;
        isDragging = false;
        maxLeft = getMaxLeft();
        thumb.style.transition = 'left 0.3s ease';

        if (thumbLeft >= maxLeft * 0.75) {
            // Accepted!
            thumb.style.left = maxLeft + 'px';
            track.classList.add('accepted');
            track.querySelector('.slide-text').style.display = 'none';
            track.querySelector('.slide-text-done').style.display = 'block';
            thumb.innerHTML = '<span class="material-icons-round">check</span>';

            setTimeout(function () {
                slideToAcceptDelivery(orderId);
            }, 600);
        } else {
            // Snap back
            thumbLeft = 0;
            thumb.style.left = '0px';
        }
    }

    thumb.addEventListener('mousedown', onStart);
    thumb.addEventListener('touchstart', onStart, { passive: false });
    document.addEventListener('mousemove', onMove);
    document.addEventListener('touchmove', onMove, { passive: false });
    document.addEventListener('mouseup', onEnd);
    document.addEventListener('touchend', onEnd);
}

function slideToAcceptDelivery(orderId) {
    var order = orders.find(function (o) { return o.id === orderId; });
    if (!order || order.status !== 'ready') return;

    order.status = 'delivered';
    order.isPaid = true;
    order.statusHistory.push({
        status: 'delivered',
        time: formatTime(new Date()),
        label: 'Order Collected'
    });

    notifications.unshift({
        title: 'Order Collected! \uD83C\uDF89',
        text: 'Your order #' + orderId + ' has been picked up. Enjoy!',
        time: formatTime(new Date()),
        type: 'order',
        unread: true
    });

    // Stop any remaining timers
    if (trackingTimers[orderId]) {
        trackingTimers[orderId].forEach(function (t) { clearTimeout(t); });
    }

    renderTrackingScreen(order);
    renderOrders();
    renderNotifications();
    showToast('Order collected successfully!');
}

function renderStatusStepper(order) {
    var stepper = document.querySelector('.status-stepper');
    if (!stepper) return;

    // Flow: Placed > Confirmed > Ready for Pickup > Completed (no 'Out for Delivery')
    var allStatuses = [
        { key: 'placed', label: 'Order Placed', icon: 'receipt_long' },
        { key: 'confirmed', label: 'Confirmed', icon: 'check_circle' },
        { key: 'ready', label: 'Ready for Pickup', icon: 'takeout_dining' },
        { key: 'delivered', label: 'Collected', icon: 'done_all' }
    ];

    var currentIdx = allStatuses.findIndex(function (s) { return s.key === order.status; });
    if (order.status === 'cancelled') currentIdx = -2;

    var html = '';
    allStatuses.forEach(function (step, idx) {
        var isCompleted = idx < currentIdx;
        var isActive = idx === currentIdx;
        var stepClass = isCompleted ? 'step completed' : (isActive ? 'step active' : 'step');

        var historyEntry = order.statusHistory.find(function (h) { return h.status === step.key; });
        var timeText = historyEntry ? historyEntry.time : (isActive ? 'In progress...' : '--');

        var iconName = isCompleted ? 'check_circle' : (isActive ? step.icon : 'radio_button_unchecked');

        html += '<div class="' + stepClass + '">' +
            '<div class="step-indicator' + (isActive ? ' active-pulse' : '') + '">' +
            '<span class="material-icons-round">' + iconName + '</span>' +
            '</div>' +
            '<div class="step-content">' +
            '<h4 class="step-title">' + step.label + '</h4>' +
            '<p class="step-time">' + timeText + '</p>' +
            '</div></div>';

        if (idx < allStatuses.length - 1) {
            var lineClass = isCompleted ? 'step-line completed' : 'step-line';
            html += '<div class="' + lineClass + '"></div>';
        }
    });

    // Cancelled overlay
    if (order.status === 'cancelled') {
        html = '<div class="order-cancelled-banner">' +
            '<span class="material-icons-round">cancel</span>' +
            '<div><h4>Order Cancelled</h4><p>This order has been cancelled</p></div>' +
            '</div>' + html;
    }

    stepper.innerHTML = html;
}

function startOrderProgression(orderId) {
    if (trackingTimers[orderId]) {
        trackingTimers[orderId].forEach(function (t) { clearTimeout(t); });
    }
    trackingTimers[orderId] = [];

    // Auto-progression stops at 'ready' - customer must slide to accept
    var statusProgression = [
        { status: 'confirmed', label: 'Order Confirmed', delay: 5000 },
        { status: 'ready', label: 'Ready for Pickup', delay: 15000 }
    ];

    statusProgression.forEach(function (step) {
        var timer = setTimeout(function () {
            var order = orders.find(function (o) { return o.id === orderId; });
            if (!order || order.status === 'cancelled' || order.status === 'delivered') return;

            order.status = step.status;
            order.statusHistory.push({
                status: step.status,
                time: formatTime(new Date()),
                label: step.label
            });

            notifications.unshift({
                title: step.label + (step.status === 'ready' ? ' \uD83C\uDF89' : ''),
                text: 'Your order #' + orderId + ' \u2014 ' + step.label.toLowerCase(),
                time: formatTime(new Date()),
                type: 'order',
                unread: true
            });

            if (activeOrderId === orderId) {
                renderTrackingScreen(order);
            }
            renderOrders();
            renderNotifications();
        }, step.delay);
        trackingTimers[orderId].push(timer);
    });
}

function cancelOrder() {
    if (!activeOrderId) return;
    var order = orders.find(function (o) { return o.id === activeOrderId; });
    if (!order || (order.status !== 'placed' && order.status !== 'confirmed')) {
        showToast('Cannot cancel this order');
        return;
    }

    if (trackingTimers[activeOrderId]) {
        trackingTimers[activeOrderId].forEach(function (t) { clearTimeout(t); });
    }

    order.status = 'cancelled';
    order.statusHistory.push({
        status: 'cancelled',
        time: formatTime(new Date()),
        label: 'Order Cancelled'
    });

    notifications.unshift({
        title: 'Order Cancelled',
        text: 'Your order #' + activeOrderId + ' has been cancelled.',
        time: formatTime(new Date()),
        type: 'order',
        unread: true
    });

    renderTrackingScreen(order);
    renderOrders();
    renderNotifications();
    showToast('Order cancelled');
}

// ═══════════════ WHATSAPP AUTO-SEND ═══════════════
function getRegisteredPhone() {
    var phoneInput = document.getElementById('phone-input');
    var phone = phoneInput ? phoneInput.value.trim() : '';
    if (!phone) phone = '9876543210'; // fallback
    var clean = phone.replace(/[^\d]/g, '');
    if (!clean.startsWith('91')) clean = '91' + clean;
    return clean;
}

function autoSendWhatsApp(orderId) {
    var order = orders.find(function (o) { return o.id === orderId; });
    if (!order) return;

    var statusLabels = {
        placed: 'Order Placed', confirmed: 'Confirmed',
        ready: 'Ready for Pickup',
        delivered: 'Collected', cancelled: 'Cancelled'
    };

    var itemsText = order.itemsList.map(function (item) {
        return '  \u2022 ' + item.qty + 'x ' + item.name + ' \u2014 \u20B9 ' + (item.price * item.qty);
    }).join('\n');

    var msg = '\uD83C\uDF55 *Fresco\'s Pizza \u2014 Order Confirmation*\n\n' +
        '\uD83D\uDCCB *Order:* #' + order.id + '\n' +
        '\uD83D\uDCC5 *Date:* ' + order.date + '\n' +
        '\uD83D\uDCCC *Status:* ' + (statusLabels[order.status] || order.status) + '\n\n' +
        '\uD83D\uDED2 *Items:*\n' + itemsText + '\n\n' +
        '\uD83D\uDCB0 Subtotal: \u20B9 ' + order.subtotal + '\n' +
        '\uD83D\uDE9A Delivery: ' + (order.deliveryCharge > 0 ? '\u20B9 ' + order.deliveryCharge : 'FREE') + '\n' +
        '\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\n' +
        '\uD83D\uDCB5 *Total: \u20B9 ' + order.total + '*\n\n' +
        '\uD83D\uDE9A Delivery' + (order.address ? ' to ' + order.address : '') + '\n' +
        '\uD83D\uDCB5 Cash on Delivery\n\n' +
        'Track your order in the Fresco\'s Pizza app! \uD83C\uDF55';

    var phone = getRegisteredPhone();
    var encodedMsg = encodeURIComponent(msg);
    var url = 'https://wa.me/' + phone + '?text=' + encodedMsg;

    setTimeout(function () {
        window.open(url, '_blank');
        showToast('Order details sent via WhatsApp!');
    }, 800);
}

function toggleTrackingDetails() {
    var body = document.getElementById('tracking-details-body');
    var icon = document.getElementById('tracking-expand');
    body.classList.toggle('open');
    icon.textContent = body.classList.contains('open') ? 'expand_less' : 'expand_more';
}

// ═══════════════ ORDERS LIST ═══════════════
function renderOrders() {
    var list = document.getElementById('orders-list');
    if (!list) return;

    if (orders.length === 0) {
        list.innerHTML = '<div class="orders-empty">' +
            '<span class="material-icons-round" style="font-size:64px;opacity:0.3;color:var(--text-hint);">receipt_long</span>' +
            '<p style="margin-top:12px;font-size:16px;font-weight:600;">No orders yet</p>' +
            '<p style="font-size:13px;color:var(--text-hint);margin-top:4px;">Your order history will appear here</p>' +
            '<button class="btn-browse-menu" onclick="switchTab(\'menu\')">Order Now</button>' +
            '</div>';
        return;
    }

    var activeOrders = orders.filter(function (o) {
        return o.status !== 'delivered' && o.status !== 'cancelled';
    });
    var pastOrders = orders.filter(function (o) {
        return o.status === 'delivered' || o.status === 'cancelled';
    });

    var html = '';

    if (activeOrders.length > 0) {
        html += '<div class="orders-section-header">Active Orders</div>';
        html += activeOrders.map(function (o) {
            return buildOrderCard(o, true);
        }).join('');
    }

    if (pastOrders.length > 0) {
        html += '<div class="orders-section-header">Past Orders</div>';
        html += pastOrders.map(function (o) {
            return buildOrderCard(o, false);
        }).join('');
    }

    list.innerHTML = html;
}

function buildOrderCard(o, isActive) {
    var statusColors = {
        placed: '#2196F3', confirmed: '#FF9800', ready: '#4CAF50',
        delivered: '#4CAF50', cancelled: '#E53935'
    };
    var statusLabels = {
        placed: 'Placed', confirmed: 'Confirmed', ready: 'Ready',
        delivered: 'Collected', cancelled: 'Cancelled'
    };

    return '<div class="order-card' + (isActive ? ' order-active' : '') + '" onclick="showOrderTracking(\'' + o.id + '\')">' +
        '<div class="order-card-header">' +
        '<span class="order-card-id">#' + o.id + '</span>' +
        '<span class="order-status-badge" style="background:' + statusColors[o.status] + '15;color:' + statusColors[o.status] + '">' +
        statusLabels[o.status] +
        '</span></div>' +
        '<div class="order-card-info">' +
        '<span>' + o.date + '</span>' +
        '<span class="order-card-total">\u20B9 ' + o.total + '</span>' +
        '</div>' +
        '<div class="order-card-items">' + o.items + '</div>' +
        '<div class="order-card-footer">' +
        '<span class="order-payment-tag">\uD83D\uDCB5 COD</span>' +
        (isActive ? '<button class="btn-track" onclick="event.stopPropagation();showOrderTracking(\'' + o.id + '\')"><span class="material-icons-round" style="font-size:16px;">location_on</span> Track</button>' : '') +
        (!isActive && o.status === 'delivered' ? '<button class="btn-reorder" onclick="event.stopPropagation();reorder(\'' + o.id + '\')">Reorder</button>' : '') +
        '</div></div>';
}

function reorder(orderId) {
    var order = orders.find(function (o) { return o.id === orderId; });
    if (!order || !order.itemsList) return;

    order.itemsList.forEach(function (item) {
        var menuItem = menuItems.find(function (m) { return m.name === item.name; });
        if (!menuItem) return;

        var existing = cartItems.find(function (c) { return c.id === menuItem.id; });
        if (existing) {
            existing.qty += item.qty;
        } else {
            cartItems.push({
                id: menuItem.id,
                name: menuItem.name,
                price: menuItem.price,
                veg: menuItem.veg,
                color: menuItem.color,
                icon: menuItem.icon,
                category: menuItem.category,
                qty: item.qty
            });
        }
    });

    renderCart();
    updateCartTotals();
    renderMenu();
    showToast('Items added to cart!');
    navigateTo('screen-cart');
}

// ═══════════════ NOTIFICATIONS ═══════════════
function renderNotifications() {
    var list = document.getElementById('notif-list');
    if (!list) return;
    var iconMap = { order: 'local_shipping', promo: 'local_offer', system: 'info' };
    list.innerHTML = '<div class="notif-date-header">Recent</div>' + notifications.map(function (n) {
        return '<div class="notif-card ' + (n.unread ? 'unread' : '') + '">' +
            '<div class="notif-icon-wrap ' + n.type + '">' +
            '<span class="material-icons-round">' + iconMap[n.type] + '</span>' +
            '</div>' +
            '<div class="notif-body">' +
            '<div class="notif-title">' + n.title + '</div>' +
            '<div class="notif-text">' + n.text + '</div>' +
            '<div class="notif-time">' + n.time + '</div>' +
            '</div></div>';
    }).join('');

    var hasUnread = notifications.some(function (n) { return n.unread; });
    document.querySelectorAll('.notif-dot').forEach(function (d) {
        d.style.display = hasUnread ? 'block' : 'none';
    });
}

// ═══════════════ UI HELPERS ═══════════════
function setupRadioGroups() {
    document.querySelectorAll('.radio-option').forEach(function (opt) {
        opt.addEventListener('click', function () {
            var inp = opt.querySelector('input');
            // Skip checkboxes - they are handled by toggleAddonCb
            if (inp && inp.type === 'checkbox') return;
            var group = opt.closest('.radio-group');
            group.querySelectorAll('.radio-option').forEach(function (o) { o.classList.remove('active'); });
            opt.classList.add('active');
            if (inp) inp.checked = true;
        });
    });
}

function setupCategoryTabs() {
    document.querySelectorAll('.cat-tab').forEach(function (tab) {
        tab.addEventListener('click', function () {
            document.querySelectorAll('.cat-tab').forEach(function (t) { t.classList.remove('active'); });
            tab.classList.add('active');
            var cat = tab.dataset.cat || 'all';
            renderMenu(cat);
        });
    });
}

function showSearch() { showToast('Search \u2014 tap any item to explore!'); }

function showToast(msg) {
    var toast = document.getElementById('toast-success');
    toast.querySelector('.toast-text').textContent = msg;
    toast.style.display = 'flex';
    setTimeout(function () { toast.style.display = 'none'; }, 2200);
}

// ═══════════════ LOGOUT ═══════════════
function logout() {
    showToast('Logging out...');
    setTimeout(function () {
        cartItems = [];
        activeOrderId = null;
        var inputs = document.querySelectorAll('input');
        inputs.forEach(function (i) { i.value = ''; });
        renderCart();
        updateCartTotals();
        navigateTo('screen-login');
        document.querySelectorAll('.nav-item').forEach(function (t) { t.classList.remove('active'); });
        var menuTab = document.querySelector('.nav-item[data-tab="menu"]');
        if (menuTab) menuTab.classList.add('active');
    }, 800);
}

// ═══════════════ PROFILE FUNCTIONS ═══════════════
var savedAddresses = [
    { id: 1, name: 'Boys Hostel - Block A', isDefault: true },
    { id: 2, name: 'Library Building', isDefault: false }
];
var favoriteItems = [1, 3, 5]; // IDs of favorite menu items
var addressCounter = 2;

function toggleProfileSection(sectionId) {
    var sectionEl = document.getElementById('section-' + sectionId);
    if (!sectionEl) return;

    var isOpen = sectionEl.style.display !== 'none';

    // Close all profile sections first
    document.querySelectorAll('.profile-section').forEach(function (s) {
        s.style.display = 'none';
    });
    // Reset all arrows
    document.querySelectorAll('.menu-item-arrow').forEach(function (a) {
        a.textContent = 'chevron_right';
    });

    if (!isOpen) {
        sectionEl.style.display = 'block';
        sectionEl.style.animation = 'slideDown 0.3s ease-out';
        var arrow = document.getElementById('arrow-' + sectionId);
        if (arrow) arrow.textContent = 'expand_more';

        // Populate content when opening
        if (sectionId === 'addresses') renderAddresses();
        if (sectionId === 'favorites') renderFavorites();
    }
}

function saveProfile() {
    var nameInput = document.getElementById('edit-name');
    var emailInput = document.getElementById('edit-email');
    var phoneInput = document.getElementById('edit-phone');

    var name = nameInput ? nameInput.value.trim() : '';
    var phone = phoneInput ? phoneInput.value.trim() : '';

    if (!name) {
        showToast('Please enter your name');
        return;
    }

    // Update display
    var displayName = document.getElementById('profile-display-name');
    var displayPhone = document.getElementById('profile-display-phone');
    var avatarText = document.getElementById('profile-avatar-text');

    if (displayName) displayName.textContent = name;
    if (displayPhone) displayPhone.textContent = phone;
    if (avatarText) {
        var initials = name.split(' ').map(function (w) { return w[0]; }).join('').toUpperCase().slice(0, 2);
        avatarText.textContent = initials;
    }

    // Update greeting on home screen
    var greetingName = document.querySelector('.greeting-name');
    if (greetingName) greetingName.textContent = name + '!';

    showToast('Profile updated successfully!');
    toggleProfileSection('edit-profile'); // Close the section
}

function renderAddresses() {
    var list = document.getElementById('address-list');
    if (!list) return;

    if (savedAddresses.length === 0) {
        list.innerHTML = '<p style="font-size:13px;color:var(--text-hint);text-align:center;padding:12px 0;">No saved addresses yet</p>';
        return;
    }

    list.innerHTML = savedAddresses.map(function (addr) {
        return '<div class="saved-address-item">' +
            '<div class="saved-address-info">' +
            '<span class="material-icons-round" style="font-size:18px;color:var(--primary);">location_on</span>' +
            '<div>' +
            '<span class="saved-address-name">' + addr.name + '</span>' +
            (addr.isDefault ? '<span class="default-badge">Default</span>' : '') +
            '</div>' +
            '</div>' +
            '<div class="saved-address-actions">' +
            (!addr.isDefault ? '<button class="addr-action-btn" onclick="setDefaultAddress(' + addr.id + ')" title="Set as default"><span class="material-icons-round" style="font-size:16px;">star_outline</span></button>' : '<span class="material-icons-round" style="font-size:16px;color:#FFA726;">star</span>') +
            '<button class="addr-action-btn delete" onclick="deleteAddress(' + addr.id + ')" title="Delete"><span class="material-icons-round" style="font-size:16px;">delete_outline</span></button>' +
            '</div>' +
            '</div>';
    }).join('');
}

function addAddress() {
    var input = document.getElementById('new-address-input');
    var value = input ? input.value.trim() : '';
    if (!value) {
        showToast('Please enter an address');
        return;
    }

    addressCounter++;
    savedAddresses.push({
        id: addressCounter,
        name: value,
        isDefault: savedAddresses.length === 0
    });

    input.value = '';
    renderAddresses();
    showToast('Address added!');
}

function deleteAddress(id) {
    savedAddresses = savedAddresses.filter(function (a) { return a.id !== id; });
    // If deleted was default, make first one default
    if (savedAddresses.length > 0 && !savedAddresses.some(function (a) { return a.isDefault; })) {
        savedAddresses[0].isDefault = true;
    }
    renderAddresses();
    showToast('Address removed');
}

function setDefaultAddress(id) {
    savedAddresses.forEach(function (a) {
        a.isDefault = (a.id === id);
    });
    renderAddresses();
    showToast('Default address updated');
}

function renderFavorites() {
    var list = document.getElementById('favorites-list');
    if (!list) return;

    var favItems = menuItems.filter(function (m) {
        return favoriteItems.indexOf(m.id) !== -1;
    });

    if (favItems.length === 0) {
        list.innerHTML = '<p style="font-size:13px;color:var(--text-hint);text-align:center;padding:16px 0;">No favorites yet. Tap the heart icon on menu items to add!</p>';
        return;
    }

    list.innerHTML = favItems.map(function (item) {
        return '<div class="fav-item">' +
            '<div class="fav-item-left">' +
            '<div class="fav-item-icon" style="background:' + item.color + ';">' +
            '<span class="material-icons-round" style="font-size:18px;color:rgba(255,255,255,0.85);">' + item.icon + '</span>' +
            '</div>' +
            '<div>' +
            '<span class="fav-item-name">' + item.name + '</span>' +
            '<span class="fav-item-price">\u20B9 ' + item.price + '</span>' +
            '</div>' +
            '</div>' +
            '<div class="fav-item-actions">' +
            '<button class="fav-add-btn" onclick="addToCartQuick(' + item.id + ')">ADD</button>' +
            '<button class="fav-remove-btn" onclick="removeFavorite(' + item.id + ')">' +
            '<span class="material-icons-round" style="font-size:18px;">favorite</span>' +
            '</button>' +
            '</div>' +
            '</div>';
    }).join('');
}

function removeFavorite(id) {
    favoriteItems = favoriteItems.filter(function (fid) { return fid !== id; });
    renderFavorites();
    showToast('Removed from favorites');
}
