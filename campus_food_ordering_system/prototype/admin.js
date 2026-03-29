// ═══════ FRESCOZ ADMIN PORTAL — JS ═══════
// --- DATA ---
var adminMenuItems = [
    { id: 1, name: "Margherita Pizza", desc: "Classic hand-tossed pizza with fresh mozzarella, basil & tomato sauce", price: 199, veg: true, color: "#E53935", icon: "local_pizza", category: "pizza", active: true, orders: 156, revenue: 31044 },
    { id: 2, name: "Pepperoni Feast", desc: "Loaded with double pepperoni, mozzarella & our signature spicy sauce", price: 349, veg: false, color: "#D84315", icon: "local_pizza", category: "pizza", active: true, orders: 98, revenue: 34202 },
    { id: 3, name: "Farmhouse Veggie", desc: "Bell peppers, mushrooms, onions, olives & sweet corn on a cheesy base", price: 279, veg: true, color: "#4CAF50", icon: "local_pizza", category: "pizza", active: true, orders: 87, revenue: 24273 },
    { id: 4, name: "BBQ Chicken Pizza", desc: "Smoky BBQ chicken, caramelized onions & jalapenos", price: 379, veg: false, color: "#FF6F00", icon: "local_pizza", category: "pizza", active: true, orders: 72, revenue: 27288 },
    { id: 5, name: "Salmon Sushi Roll", desc: "Fresh Atlantic salmon, avocado & cucumber wrapped in seasoned rice", price: 349, veg: false, color: "#F44336", icon: "set_meal", category: "japanese", active: true, orders: 64, revenue: 22336 },
    { id: 6, name: "Chicken Ramen", desc: "Rich tonkotsu broth with chashu pork, soft-boiled egg & noodles", price: 299, veg: false, color: "#FF7043", icon: "ramen_dining", category: "japanese", active: true, orders: 58, revenue: 17342 },
    { id: 7, name: "Vegetable Tempura", desc: "Crispy battered sweet potato, broccoli, zucchini & bell peppers", price: 229, veg: true, color: "#FFC107", icon: "restaurant", category: "japanese", active: true, orders: 45, revenue: 10305 },
    { id: 8, name: "Edamame Bowl", desc: "Steamed salted soybeans - the perfect healthy starter", price: 129, veg: true, color: "#66BB6A", icon: "eco", category: "japanese", active: true, orders: 33, revenue: 4257 },
    { id: 9, name: "Garlic Breadsticks", desc: "Oven-baked garlic bread with herb butter & cheese dip", price: 129, veg: true, color: "#FFB300", icon: "bakery_dining", category: "sides", active: true, orders: 112, revenue: 14448 },
    { id: 10, name: "Miso Soup", desc: "Traditional Japanese soup with tofu, wakame seaweed & scallions", price: 99, veg: true, color: "#8D6E63", icon: "soup_kitchen", category: "japanese", active: true, orders: 30, revenue: 2970 },
    { id: 11, name: "Cold Coffee", desc: "Chilled coffee blended with vanilla ice cream", price: 89, veg: true, color: "#795548", icon: "local_cafe", category: "beverages", active: true, orders: 140, revenue: 12460 },
    { id: 12, name: "Matcha Latte", desc: "Ceremonial grade Japanese matcha with steamed oat milk", price: 149, veg: true, color: "#558B2F", icon: "emoji_food_beverage", category: "beverages", active: true, orders: 52, revenue: 7748 },
    { id: 13, name: "Fresh Lime Soda", desc: "Refreshing lime soda with mint leaves & ice", price: 59, veg: true, color: "#7CB342", icon: "local_bar", category: "beverages", active: true, orders: 95, revenue: 5605 },
    { id: 14, name: "Mango Smoothie", desc: "Thick creamy mango smoothie with real Alphonso mango pulp", price: 129, veg: true, color: "#FFA726", icon: "local_cafe", category: "beverages", active: true, orders: 68, revenue: 8772 },
    { id: 15, name: "Choco Lava Cake", desc: "Warm chocolate cake with a gooey molten center", price: 109, veg: true, color: "#4E342E", icon: "cake", category: "desserts", active: true, orders: 89, revenue: 9701 },
    { id: 16, name: "Mochi Ice Cream", desc: "Japanese rice cake filled with creamy green tea ice cream", price: 119, veg: true, color: "#9CCC65", icon: "icecream", category: "desserts", active: true, orders: 55, revenue: 6545 },
    { id: 17, name: "Tiramisu", desc: "Classic Italian coffee-flavoured dessert with mascarpone cream", price: 159, veg: true, color: "#8D6E63", icon: "cake", category: "desserts", active: true, orders: 42, revenue: 6678 },
    { id: 18, name: "Cheesecake Slice", desc: "New York style baked cheesecake with berry compote", price: 179, veg: true, color: "#E91E63", icon: "cake", category: "desserts", active: true, orders: 38, revenue: 6802 },
    { id: 19, name: "Pizza Combo for 2", desc: "2 Medium Pizzas, 1 Garlic Breadsticks, 2 Cold Coffees", price: 799, veg: false, color: "#E91E63", icon: "restaurant_menu", category: "combo", active: true, orders: 35, revenue: 27965 },
    { id: 20, name: "Sushi & Ramen Meal", desc: "1 Salmon Sushi Roll, 1 Chicken Ramen, 1 Matcha Latte", price: 649, veg: false, color: "#9C27B0", icon: "set_meal", category: "combo", active: true, orders: 22, revenue: 14278 },
    { id: 21, name: "Family Feast", desc: "3 Large Pizzas, 2 Sides, 4 Cold Coffees, 2 Desserts", price: 1499, veg: false, color: "#FF5722", icon: "restaurant_menu", category: "combo", active: true, orders: 15, revenue: 22485 },
    { id: 22, name: "Cheesy Fries", desc: "Crispy fries loaded with melted cheddar & mozzarella", price: 149, veg: true, color: "#F9A825", icon: "fastfood", category: "sides", active: true, orders: 78, revenue: 11622 },
    { id: 23, name: "Chicken Wings", desc: "6 pcs crispy fried wings tossed in buffalo sauce", price: 199, veg: false, color: "#D84315", icon: "restaurant", category: "sides", active: true, orders: 65, revenue: 12935 }
];

var adminOrders = [];
var customers = [];
var editingItemId = null;
var deleteItemId = null;
var currentMenuFilter = 'all';
var currentOrderFilter = 'all';
var selectedColor = '#E53935';

// Generate sample orders
(function generateSampleData() {
    var names = ['Rahul S.', 'Priya M.', 'Vikram K.', 'Anita D.', 'Karthik R.', 'Sneha P.', 'Arjun V.', 'Divya T.', 'Rohit G.', 'Meera N.', 'Aditya B.', 'Pooja L.', 'Suresh W.', 'Kavitha J.', 'Nikhil F.'];
    var phones = ['+91 98765 43210', '+91 87654 32109', '+91 76543 21098', '+91 65432 10987', '+91 54321 09876'];
    var statuses = ['placed', 'confirmed', 'ready', 'delivered', 'delivered', 'delivered', 'delivered', 'cancelled'];
    var addresses = ['Hostel A, Room 204', 'Hostel B, Room 112', 'Academic Block C', 'Library Building', 'Cafeteria Wing'];
    var now = new Date();

    for (var i = 0; i < 40; i++) {
        var d = new Date(now - i * 3600000 * (1 + Math.random() * 5));
        var numItems = 1 + Math.floor(Math.random() * 3);
        var items = [];
        var total = 0;
        for (var j = 0; j < numItems; j++) {
            var mi = adminMenuItems[Math.floor(Math.random() * adminMenuItems.length)];
            var qty = 1 + Math.floor(Math.random() * 2);
            items.push({ name: mi.name, qty: qty, price: mi.price });
            total += mi.price * qty;
        }
        adminOrders.push({
            id: 'PIZ-' + d.getFullYear() + ('0' + (d.getMonth() + 1)).slice(-2) + ('0' + d.getDate()).slice(-2) + '-' + ('0000' + (100 + i)).slice(-4),
            customer: names[i % names.length],
            phone: phones[i % phones.length],
            items: items,
            total: total + 30,
            status: i < 5 ? statuses[Math.min(i, 3)] : statuses[Math.floor(Math.random() * statuses.length)],
            payment: Math.random() > 0.3 ? 'Cash on Delivery' : 'UPI',
            address: addresses[i % addresses.length],
            date: d,
            timeline: [{ status: 'placed', time: d }, { status: 'confirmed', time: new Date(d.getTime() + 120000) }]
        });
    }

    // Generate customers
    names.forEach(function (n, idx) {
        var orderCount = Math.floor(Math.random() * 15) + 1;
        customers.push({
            name: n, phone: phones[idx % phones.length],
            orders: orderCount, spent: orderCount * (200 + Math.floor(Math.random() * 400)),
            lastOrder: new Date(now - Math.random() * 7 * 86400000),
            status: Math.random() > 0.1 ? 'active' : 'inactive'
        });
    });
})();

// --- INVENTORY ---
var inventory = [
    { name: 'Mozzarella Cheese', cat: 'Dairy', stock: 85, unit: 'kg', lastRestock: '2026-02-25' },
    { name: 'Pizza Dough', cat: 'Base', stock: 120, unit: 'pcs', lastRestock: '2026-02-27' },
    { name: 'Tomato Sauce', cat: 'Sauce', stock: 45, unit: 'L', lastRestock: '2026-02-20' },
    { name: 'Pepperoni', cat: 'Meat', stock: 12, unit: 'kg', lastRestock: '2026-02-18' },
    { name: 'Fresh Basil', cat: 'Herbs', stock: 8, unit: 'bunches', lastRestock: '2026-02-26' },
    { name: 'Chicken Breast', cat: 'Meat', stock: 25, unit: 'kg', lastRestock: '2026-02-24' },
    { name: 'Sushi Rice', cat: 'Grain', stock: 60, unit: 'kg', lastRestock: '2026-02-22' },
    { name: 'Salmon Fillet', cat: 'Seafood', stock: 5, unit: 'kg', lastRestock: '2026-02-19' },
    { name: 'Ramen Noodles', cat: 'Noodles', stock: 90, unit: 'packs', lastRestock: '2026-02-21' },
    { name: 'Coffee Beans', cat: 'Beverage', stock: 30, unit: 'kg', lastRestock: '2026-02-23' }
];

var staff = [
    { name: 'Sanni Kumar', role: 'Super Admin', contact: 'sanni@frescoz.com', color: '#FF6B35' },
    { name: 'Priya Sharma', role: 'Kitchen Manager', contact: 'priya@frescoz.com', color: '#6366F1' },
    { name: 'Rahul Verma', role: 'Delivery Manager', contact: 'rahul@frescoz.com', color: '#10B981' },
    { name: 'Anita Das', role: 'Cashier', contact: 'anita@frescoz.com', color: '#F59E0B' },
    { name: 'Vikram Singh', role: 'Chef', contact: 'vikram@frescoz.com', color: '#EF4444' },
    { name: 'Sneha Patel', role: 'Chef', contact: 'sneha@frescoz.com', color: '#8B5CF6' }
];

var promos = [
    { title: 'BOGO Pizza Saturday', desc: 'Buy 1 Get 1 Free on all medium pizzas every Saturday', code: 'PIZZABOGO', validTill: '2026-03-31', bg: 'linear-gradient(135deg,#FF6B35,#FF8F65)', emoji: '🍕' },
    { title: 'New User Welcome', desc: 'Flat 30% off on first order for new customers', code: 'WELCOME30', validTill: '2026-12-31', bg: 'linear-gradient(135deg,#6366F1,#818CF8)', emoji: '🎉' },
    { title: 'Combo Special', desc: '₹100 off on any combo meal above ₹599', code: 'COMBO100', validTill: '2026-04-15', bg: 'linear-gradient(135deg,#10B981,#34D399)', emoji: '🍱' },
    { title: 'Free Delivery Week', desc: 'Free delivery on all orders this week', code: 'FREEDELIVERY', validTill: '2026-03-07', bg: 'linear-gradient(135deg,#F59E0B,#FBBF24)', emoji: '🚀' }
];

var mediaFiles = [
    { name: 'margherita.jpg', folder: 'pizza', size: '245 KB', color: '#E53935' },
    { name: 'pepperoni.jpg', folder: 'pizza', size: '312 KB', color: '#D84315' },
    { name: 'farmhouse.jpg', folder: 'pizza', size: '198 KB', color: '#4CAF50' },
    { name: 'extra_cheese.png', folder: 'toppings', size: '56 KB', color: '#FFC107' },
    { name: 'mushrooms.png', folder: 'toppings', size: '43 KB', color: '#8D6E63' },
    { name: 'jalapenos.png', folder: 'toppings', size: '38 KB', color: '#4CAF50' },
    { name: 'summer_banner.jpg', folder: 'banners', size: '890 KB', color: '#FF6B35' },
    { name: 'diwali_special.jpg', folder: 'seasonal', size: '1.2 MB', color: '#FF9800' },
    { name: 'bogo_offer.jpg', folder: 'banners', size: '567 KB', color: '#E91E63' },
    { name: 'combo_banner.jpg', folder: 'banners', size: '445 KB', color: '#9C27B0' },
    { name: 'sushi_roll.jpg', folder: 'pizza', size: '278 KB', color: '#F44336' },
    { name: 'ramen_bowl.jpg', folder: 'pizza', size: '301 KB', color: '#FF7043' }
];

// --- INIT ---
document.addEventListener('DOMContentLoaded', function () {
    renderDashboard();
    renderAdminMenu();
    renderOrdersTable();
    renderCustomers();
    renderInventory();
    renderStaff();
    renderPromos();
    renderMedia();
    setupFormListeners();
});

// --- NAV ---
function navigateTo(page) {
    document.querySelectorAll('.page').forEach(function (p) { p.classList.remove('active'); });
    document.querySelectorAll('.nav-link').forEach(function (n) { n.classList.remove('active'); });
    var el = document.getElementById('page-' + page);
    if (el) el.classList.add('active');
    var nav = document.querySelector('.nav-link[data-page="' + page + '"]');
    if (nav) nav.classList.add('active');
    var titles = { dashboard: 'Dashboard', menu: 'Menu Management', orders: 'Orders', customers: 'Customers', promotions: 'Promotions & Offers', media: 'Media Library', reports: 'Reports & Analytics', inventory: 'Inventory', staff: 'Staff Management', settings: 'Settings' };
    document.getElementById('page-title').textContent = titles[page] || page;
    if (page === 'reports') renderReport('daily');
    // Close mobile sidebar
    document.getElementById('sidebar').classList.remove('mobile-open');
}

function toggleSidebar() {
    var sb = document.getElementById('sidebar');
    if (window.innerWidth <= 768) {
        sb.classList.toggle('mobile-open');
    } else {
        sb.classList.toggle('collapsed');
    }
}

// --- DASHBOARD ---
function renderDashboard() {
    renderRevenueChart();
    renderPopularItems();
    renderRecentOrders();
    renderStatusChart();
}

function renderRevenueChart() {
    var c = document.getElementById('revenue-chart');
    var days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    var values = [32400, 28900, 35600, 41200, 48520, 52300, 45800];
    var maxV = Math.max.apply(null, values);
    c.innerHTML = '';
    days.forEach(function (d, i) {
        var h = Math.max(20, (values[i] / maxV) * 240);
        c.innerHTML += '<div class="chart-bar-group"><div class="chart-bar" style="height:' + h + 'px;background:linear-gradient(180deg,' + (i === 4 ? '#FF6B35' : '#FFB088') + ',' + (i === 4 ? '#FF8F65' : '#FFD4BB') + ');animation-delay:' + i * 0.1 + 's"><span class="chart-bar-value">₹' + Math.round(values[i] / 1000) + 'K</span></div><span class="chart-bar-label">' + d + '</span></div>';
    });
}

function renderPopularItems() {
    var c = document.getElementById('popular-items');
    var sorted = adminMenuItems.slice().sort(function (a, b) { return b.orders - a.orders; }).slice(0, 6);
    c.innerHTML = sorted.map(function (item, i) {
        var rankClass = i === 0 ? 'gold' : i === 1 ? 'silver' : i === 2 ? 'bronze' : 'default';
        return '<div class="popular-item"><span class="popular-rank ' + rankClass + '">' + (i + 1) + '</span><div class="popular-item-icon" style="background:' + item.color + '"><span class="material-icons-round">' + item.icon + '</span></div><div class="popular-item-info"><span class="popular-item-name">' + item.name + '</span><span class="popular-item-orders">' + item.orders + ' orders</span></div><span class="popular-item-revenue">₹' + item.revenue.toLocaleString() + '</span></div>';
    }).join('');
}

function renderRecentOrders() {
    var tbody = document.getElementById('recent-orders-body');
    tbody.innerHTML = adminOrders.slice(0, 8).map(function (o) {
        var itemsText = o.items.map(function (i) { return i.qty + 'x ' + i.name; }).join(', ');
        if (itemsText.length > 40) itemsText = itemsText.substring(0, 40) + '...';
        return '<tr><td><strong>' + o.id + '</strong></td><td>' + o.customer + '</td><td>' + itemsText + '</td><td><strong>₹' + o.total + '</strong></td><td><span class="status-badge ' + o.status + '"><span class="status-dot"></span>' + capitalize(o.status) + '</span></td><td>' + formatTime(o.date) + '</td></tr>';
    }).join('');
}

function renderStatusChart() {
    var counts = { placed: 0, confirmed: 0, ready: 0, delivered: 0, cancelled: 0 };
    adminOrders.forEach(function (o) { counts[o.status] = (counts[o.status] || 0) + 1; });
    var total = adminOrders.length;
    var colors = { placed: '#3B82F6', confirmed: '#10B981', ready: '#F59E0B', delivered: '#059669', cancelled: '#EF4444' };
    var labels = { placed: 'New', confirmed: 'Confirmed', ready: 'Ready', delivered: 'Collected', cancelled: 'Cancelled' };

    var c = document.getElementById('status-chart');
    var offset = 0;
    var segments = '';
    var circumference = 2 * Math.PI * 70;

    Object.keys(counts).forEach(function (status) {
        var pct = counts[status] / total;
        var len = pct * circumference;
        segments += '<circle cx="90" cy="90" r="70" fill="none" stroke="' + colors[status] + '" stroke-width="20" stroke-dasharray="' + len + ' ' + (circumference - len) + '" stroke-dashoffset="-' + offset + '" />';
        offset += len;
    });

    c.innerHTML = '<svg viewBox="0 0 180 180" style="width:180px;height:180px;">' + segments + '<text x="90" y="85" text-anchor="middle" font-size="28" font-weight="800" fill="#1A1D23">' + total + '</text><text x="90" y="105" text-anchor="middle" font-size="12" fill="#6B7280">Total Orders</text></svg>';

    var legend = document.getElementById('status-legend');
    legend.innerHTML = Object.keys(counts).map(function (s) {
        return '<span class="legend-item"><span class="legend-dot" style="background:' + colors[s] + '"></span>' + labels[s] + ': ' + counts[s] + '</span>';
    }).join('');
}

// --- MENU MANAGEMENT ---
function renderAdminMenu() {
    var grid = document.getElementById('admin-menu-grid');
    var items = currentMenuFilter === 'all' ? adminMenuItems : adminMenuItems.filter(function (i) { return i.category === currentMenuFilter; });
    var searchTerm = (document.getElementById('menu-search') || {}).value || '';
    if (searchTerm) items = items.filter(function (i) { return i.name.toLowerCase().indexOf(searchTerm.toLowerCase()) >= 0; });

    grid.innerHTML = items.map(function (item) {
        return '<div class="admin-menu-card' + (item.active ? '' : ' inactive') + '"><div class="card-img" style="background:linear-gradient(135deg,' + item.color + ',' + item.color + 'dd)"><span class="material-icons-round">' + item.icon + '</span><div class="card-veg ' + (item.veg ? 'veg' : 'non-veg') + '"></div>' + (item.active ? '' : '<span class="inactive-badge">Inactive</span>') + '</div><div class="card-body"><div class="card-name">' + item.name + '</div><div class="card-desc">' + item.desc + '</div><div class="card-meta"><span class="card-price">₹ ' + item.price + '</span><span class="card-category">' + item.category + '</span></div></div><div class="card-actions"><button class="btn-sm btn-sm-primary" onclick="openEditItemModal(' + item.id + ')"><span class="material-icons-round">edit</span>Edit</button><button class="btn-sm btn-sm-outline" onclick="openEditItemModal(' + item.id + ')"><span class="material-icons-round">visibility</span>View</button><button class="btn-sm btn-sm-danger" onclick="openDeleteModal(' + item.id + ')"><span class="material-icons-round">delete</span></button></div></div>';
    }).join('');

    // Update count
    var countEl = document.querySelector('.pill[data-filter="all"] .pill-count');
    if (countEl) countEl.textContent = adminMenuItems.filter(function (i) { return i.active; }).length;
}

function filterMenu(cat) {
    currentMenuFilter = cat;
    document.querySelectorAll('#page-menu .pill').forEach(function (p) { p.classList.remove('active'); });
    var btn = document.querySelector('#page-menu .pill[data-filter="' + cat + '"]');
    if (btn) btn.classList.add('active');
    renderAdminMenu();
}

function searchMenuItems() { renderAdminMenu(); }

function openAddItemModal() {
    editingItemId = null;
    document.getElementById('item-modal-title').textContent = 'Add Menu Item';
    document.getElementById('mi-name').value = '';
    document.getElementById('mi-desc').value = '';
    document.getElementById('mi-price').value = '';
    document.getElementById('mi-category').value = '';
    document.getElementById('mi-ingredients').value = '';
    document.getElementById('upload-preview').style.display = 'none';
    document.getElementById('upload-placeholder').style.display = '';
    document.getElementById('mi-save-btn').innerHTML = '<span class="material-icons-round">check</span> Save Item';
    document.getElementById('item-modal').style.display = 'flex';
    updateCharCounts();
}

function openEditItemModal(id) {
    var item = adminMenuItems.find(function (i) { return i.id === id; });
    if (!item) return;
    editingItemId = id;
    document.getElementById('item-modal-title').textContent = 'Edit Menu Item';
    document.getElementById('mi-name').value = item.name;
    document.getElementById('mi-desc').value = item.desc;
    document.getElementById('mi-price').value = item.price;
    document.getElementById('mi-category').value = item.category;
    document.getElementById('mi-ingredients').value = '';
    selectedColor = item.color;
    document.querySelectorAll('.color-swatch').forEach(function (s) { s.classList.toggle('active', s.dataset.color === item.color); });
    document.getElementById('mi-save-btn').innerHTML = '<span class="material-icons-round">check</span> Update Item';
    document.getElementById('item-modal').style.display = 'flex';
    togglePizzaOptions();
    updateCharCounts();
}

function closeItemModal() { document.getElementById('item-modal').style.display = 'none'; }

function saveMenuItem() {
    var name = document.getElementById('mi-name').value.trim();
    var desc = document.getElementById('mi-desc').value.trim();
    var price = parseInt(document.getElementById('mi-price').value);
    var category = document.getElementById('mi-category').value;
    var icon = document.getElementById('mi-icon').value;
    var veg = document.querySelector('input[name="mi-veg"]:checked').value === 'true';

    if (!name || !desc || !price || !category) { showAdminToast('Please fill all required fields', 'error'); return; }

    if (editingItemId) {
        var item = adminMenuItems.find(function (i) { return i.id === editingItemId; });
        if (item) { item.name = name; item.desc = desc; item.price = price; item.category = category; item.icon = icon; item.veg = veg; item.color = selectedColor; }
        showAdminToast(name + ' updated successfully!', 'success');
    } else {
        adminMenuItems.push({ id: Date.now(), name: name, desc: desc, price: price, veg: veg, color: selectedColor, icon: icon, category: category, active: true, orders: 0, revenue: 0 });
        showAdminToast(name + ' added to menu!', 'success');
    }
    closeItemModal();
    renderAdminMenu();
    renderPopularItems();
}

function openDeleteModal(id) {
    var item = adminMenuItems.find(function (i) { return i.id === id; });
    if (!item) return;
    deleteItemId = id;
    document.getElementById('delete-item-name').textContent = item.name;
    document.getElementById('delete-order-count').textContent = item.orders;
    document.getElementById('delete-modal').style.display = 'flex';
}

function closeDeleteModal() { document.getElementById('delete-modal').style.display = 'none'; }

function confirmDeleteItem() {
    var item = adminMenuItems.find(function (i) { return i.id === deleteItemId; });
    if (item) { item.active = false; showAdminToast(item.name + ' deactivated (soft-deleted)', 'warning'); }
    closeDeleteModal();
    renderAdminMenu();
}

function handleImageUpload(input) {
    if (!input.files || !input.files[0]) return;
    document.getElementById('upload-placeholder').style.display = 'none';
    document.getElementById('upload-progress').style.display = '';
    var fill = document.getElementById('progress-fill');
    var text = document.getElementById('progress-text');
    var pct = 0;
    var iv = setInterval(function () {
        pct += Math.random() * 25 + 5;
        if (pct >= 100) {
            pct = 100; clearInterval(iv);
            setTimeout(function () {
                document.getElementById('upload-progress').style.display = 'none';
                document.getElementById('upload-preview').style.display = '';
                var reader = new FileReader();
                reader.onload = function (e) { document.getElementById('preview-img').src = e.target.result; };
                reader.readAsDataURL(input.files[0]);
                showAdminToast('Image uploaded successfully!', 'success');
            }, 300);
        }
        fill.style.width = pct + '%';
        text.textContent = 'Uploading... ' + Math.round(pct) + '%';
    }, 200);
}

function selectColor(el) {
    document.querySelectorAll('.color-swatch').forEach(function (s) { s.classList.remove('active'); });
    el.classList.add('active');
    selectedColor = el.dataset.color;
}

function togglePizzaOptions() {
    var cat = document.getElementById('mi-category').value;
    document.getElementById('pizza-options-section').style.display = cat === 'pizza' ? '' : 'none';
}

// --- ORDERS ---
function renderOrdersTable() {
    var tbody = document.getElementById('orders-body');
    var filtered = currentOrderFilter === 'all' ? adminOrders : adminOrders.filter(function (o) { return o.status === currentOrderFilter; });
    var searchTerm = (document.getElementById('order-search') || {}).value || '';
    if (searchTerm) filtered = filtered.filter(function (o) { return o.id.toLowerCase().indexOf(searchTerm.toLowerCase()) >= 0 || o.customer.toLowerCase().indexOf(searchTerm.toLowerCase()) >= 0; });

    tbody.innerHTML = filtered.map(function (o) {
        var itemsText = o.items.map(function (i) { return i.qty + 'x ' + i.name; }).join(', ');
        if (itemsText.length > 35) itemsText = itemsText.substring(0, 35) + '...';
        return '<tr><td><input type="checkbox"></td><td><strong>' + o.id + '</strong></td><td><div><strong>' + o.customer + '</strong><br><span style="font-size:11px;color:var(--text-hint)">' + o.phone + '</span></div></td><td>' + itemsText + '</td><td><strong>₹' + o.total + '</strong></td><td>' + o.payment + '</td><td><span class="status-badge ' + o.status + '"><span class="status-dot"></span>' + capitalize(o.status) + '</span></td><td>' + formatDate(o.date) + '<br><span style="font-size:11px;color:var(--text-hint)">' + formatTime(o.date) + '</span></td><td><button class="btn-sm btn-sm-primary" onclick="openOrderDetail(\'' + o.id + '\')"><span class="material-icons-round">visibility</span></button></td></tr>';
    }).join('');
}

function filterOrders(status) {
    currentOrderFilter = status;
    document.querySelectorAll('#page-orders .pill').forEach(function (p) { p.classList.remove('active'); });
    var btn = document.querySelector('#page-orders .pill[data-filter="' + status + '"]');
    if (btn) btn.classList.add('active');
    renderOrdersTable();
}

function searchOrders() { renderOrdersTable(); }
function filterOrdersByDate() { renderOrdersTable(); }
function toggleAllOrders(cb) { document.querySelectorAll('#orders-body input[type=checkbox]').forEach(function (c) { c.checked = cb.checked; }); }

function openOrderDetail(orderId) {
    var o = adminOrders.find(function (x) { return x.id === orderId; });
    if (!o) return;
    var body = document.getElementById('order-detail-body');
    body.innerHTML = '<div class="order-detail-grid"><div><div class="order-info-section"><h4>Order Information</h4><div class="order-info-row"><span class="label">Order ID</span><span class="value">' + o.id + '</span></div><div class="order-info-row"><span class="label">Date</span><span class="value">' + formatDate(o.date) + ' ' + formatTime(o.date) + '</span></div><div class="order-info-row"><span class="label">Status</span><span class="value"><span class="status-badge ' + o.status + '"><span class="status-dot"></span>' + capitalize(o.status) + '</span></span></div><div class="order-info-row"><span class="label">Payment</span><span class="value">' + o.payment + '</span></div></div><div class="order-info-section"><h4>Customer</h4><div class="order-info-row"><span class="label">Name</span><span class="value">' + o.customer + '</span></div><div class="order-info-row"><span class="label">Phone</span><span class="value">' + o.phone + '</span></div><div class="order-info-row"><span class="label">Address</span><span class="value">' + o.address + '</span></div></div></div><div><div class="order-info-section"><h4>Items</h4>' + o.items.map(function (i) { return '<div class="order-info-row"><span class="label">' + i.qty + 'x ' + i.name + '</span><span class="value">₹' + (i.price * i.qty) + '</span></div>'; }).join('') + '<div class="order-info-row" style="border-top:1px solid var(--divider);padding-top:8px;margin-top:4px;"><span class="label"><strong>Delivery</strong></span><span class="value">₹30</span></div><div class="order-info-row" style="font-size:15px;"><span class="label"><strong>Total</strong></span><span class="value" style="color:var(--primary)"><strong>₹' + o.total + '</strong></span></div></div><div class="order-info-section"><h4>Timeline</h4><div class="order-timeline"><div class="timeline-item"><span class="timeline-label">Order Placed</span><br><span class="timeline-time">' + formatTime(o.date) + '</span></div><div class="timeline-item"><span class="timeline-label">Confirmed</span><br><span class="timeline-time">' + formatTime(new Date(o.date.getTime() + 120000)) + '</span></div><div class="timeline-item ' + (o.status === 'placed' || o.status === 'confirmed' ? 'future' : '') + '"><span class="timeline-label">Ready for Pickup</span><br><span class="timeline-time">' + (o.status === 'ready' || o.status === 'delivered' ? formatTime(new Date(o.date.getTime() + 900000)) : '--') + '</span></div><div class="timeline-item ' + (o.status !== 'delivered' ? 'future' : '') + '"><span class="timeline-label">Collected</span><br><span class="timeline-time">' + (o.status === 'delivered' ? formatTime(new Date(o.date.getTime() + 1800000)) : '--') + '</span></div></div></div></div></div>';
    document.getElementById('order-detail-modal').style.display = 'flex';
}

function closeOrderDetail() { document.getElementById('order-detail-modal').style.display = 'none'; }
function reprintInvoice() { showAdminToast('Invoice sent to printer', 'success'); }

// --- CUSTOMERS ---
function renderCustomers() {
    var tbody = document.getElementById('customers-body');
    tbody.innerHTML = customers.map(function (c) {
        return '<tr><td><div style="display:flex;align-items:center;gap:10px"><div style="width:32px;height:32px;border-radius:50%;background:var(--primary);color:#fff;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:700">' + c.name.split(' ').map(function (w) { return w[0]; }).join('') + '</div><strong>' + c.name + '</strong></div></td><td>' + c.phone + '</td><td>' + c.orders + '</td><td><strong>₹' + c.spent.toLocaleString() + '</strong></td><td>' + formatDate(c.lastOrder) + '</td><td><span class="status-badge ' + c.status + '"><span class="status-dot"></span>' + capitalize(c.status) + '</span></td></tr>';
    }).join('');
}

function exportCustomers() { showAdminToast('Customer data exported as CSV', 'success'); }

// --- INVENTORY ---
function renderInventory() {
    var tbody = document.getElementById('inventory-body');
    tbody.innerHTML = inventory.map(function (item) {
        var level = item.stock > 50 ? 'high' : item.stock > 15 ? 'medium' : 'low';
        var statusText = level === 'high' ? 'In Stock' : level === 'medium' ? 'Moderate' : 'Low Stock';
        var statusClass = level === 'high' ? 'active' : level === 'medium' ? 'placed' : 'cancelled';
        return '<tr><td><strong>' + item.name + '</strong></td><td>' + item.cat + '</td><td><div style="display:flex;align-items:center;gap:8px"><div class="stock-bar"><div class="stock-fill ' + level + '" style="width:' + Math.min(item.stock, 100) + '%"></div></div><span>' + item.stock + '</span></div></td><td>' + item.unit + '</td><td><span class="status-badge ' + statusClass + '"><span class="status-dot"></span>' + statusText + '</span></td><td>' + item.lastRestock + '</td><td><button class="btn-sm btn-sm-primary" onclick="showAdminToast(\'Restock order placed\',\'success\')"><span class="material-icons-round">add</span>Restock</button></td></tr>';
    }).join('');
}

function showLowStock() { showAdminToast('3 items below minimum stock level', 'warning'); }
function openRestockModal() { showAdminToast('Restock form opened', 'success'); }

// --- STAFF ---
function renderStaff() {
    var grid = document.getElementById('staff-grid');
    grid.innerHTML = staff.map(function (s) {
        var initials = s.name.split(' ').map(function (w) { return w[0]; }).join('');
        return '<div class="staff-card"><div class="staff-avatar" style="background:' + s.color + '">' + initials + '</div><div class="staff-name">' + s.name + '</div><span class="staff-role">' + s.role + '</span><span class="staff-contact">' + s.contact + '</span><div class="staff-actions"><button class="btn-sm btn-sm-primary" onclick="showAdminToast(\'Edit staff\',\'success\')"><span class="material-icons-round">edit</span>Edit</button><button class="btn-sm btn-sm-outline"><span class="material-icons-round">schedule</span>Schedule</button></div></div>';
    }).join('');
}

function openStaffModal() { showAdminToast('Add staff form', 'success'); }

// --- PROMOS ---
function renderPromos() {
    var grid = document.getElementById('promo-grid');
    grid.innerHTML = promos.map(function (p) {
        return '<div class="promo-card"><div class="promo-banner" style="background:' + p.bg + '">' + p.emoji + '</div><div class="promo-body"><div class="promo-title">' + p.title + '</div><div class="promo-desc">' + p.desc + '</div><div class="promo-meta"><span class="promo-code">' + p.code + '</span><span class="promo-validity">Valid till ' + p.validTill + '</span></div></div></div>';
    }).join('');
}

function openPromoModal() { showAdminToast('Create promotion form', 'success'); }

// --- MEDIA ---
function renderMedia(filter) {
    var grid = document.getElementById('media-grid');
    var items = !filter || filter === 'all' ? mediaFiles : mediaFiles.filter(function (f) { return f.folder === filter; });
    grid.innerHTML = items.map(function (f) {
        return '<div class="media-card"><div class="media-img" style="background:linear-gradient(135deg,' + f.color + ',' + f.color + 'aa)"><span class="material-icons-round" style="font-size:36px;color:rgba(255,255,255,0.8)">image</span></div><div class="media-info"><span class="media-name">' + f.name + '</span><span class="media-size">' + f.size + ' • ' + f.folder + '</span></div></div>';
    }).join('');
}

function filterMedia(f) {
    document.querySelectorAll('#page-media .pill').forEach(function (p) { p.classList.remove('active'); });
    event.target.classList.add('active');
    renderMedia(f);
}

function openMediaUpload() { showAdminToast('Media upload dialog', 'success'); }

// --- REPORTS ---
function renderReport(period) { switchReport(period); }

function switchReport(period) {
    document.querySelectorAll('#page-reports .pill').forEach(function (p) { p.classList.remove('active'); });
    var btn = document.querySelector('#page-reports .pill[data-rp="' + period + '"]');
    if (btn) btn.classList.add('active');

    var kpis = document.getElementById('report-kpis');
    var data = getReportData(period);

    kpis.innerHTML = data.kpis.map(function (k) {
        return '<div class="report-kpi"><span class="report-kpi-label">' + k.label + '</span><span class="report-kpi-value">' + k.value + '</span><span class="report-kpi-change ' + k.trend + '">' + k.change + '</span></div>';
    }).join('');

    document.getElementById('report-chart-title').textContent = data.chartTitle;
    var chart = document.getElementById('report-chart');
    var maxV = Math.max.apply(null, data.chartValues);
    chart.innerHTML = data.chartLabels.map(function (l, i) {
        var h = Math.max(15, (data.chartValues[i] / maxV) * 240);
        return '<div class="chart-bar-group"><div class="chart-bar" style="height:' + h + 'px"><span class="chart-bar-value">₹' + Math.round(data.chartValues[i] / 1000) + 'K</span></div><span class="chart-bar-label">' + l + '</span></div>';
    }).join('');

    document.getElementById('report-table-title').textContent = data.tableTitle;
    var thead = document.getElementById('report-thead');
    thead.innerHTML = '<tr>' + data.tableCols.map(function (c) { return '<th>' + c + '</th>'; }).join('') + '</tr>';
    var tbody = document.getElementById('report-tbody');
    tbody.innerHTML = data.tableRows.map(function (r) { return '<tr>' + r.map(function (c) { return '<td>' + c + '</td>'; }).join('') + '</tr>'; }).join('');

    var topItems = document.getElementById('report-top-items');
    topItems.innerHTML = '<div class="popular-items-list">' + adminMenuItems.slice().sort(function (a, b) { return b.revenue - a.revenue; }).slice(0, 5).map(function (item, i) {
        var rc = i === 0 ? 'gold' : i === 1 ? 'silver' : i === 2 ? 'bronze' : 'default';
        return '<div class="popular-item"><span class="popular-rank ' + rc + '">' + (i + 1) + '</span><div class="popular-item-icon" style="background:' + item.color + '"><span class="material-icons-round">' + item.icon + '</span></div><div class="popular-item-info"><span class="popular-item-name">' + item.name + '</span><span class="popular-item-orders">' + item.orders + ' orders</span></div><span class="popular-item-revenue">₹' + item.revenue.toLocaleString() + '</span></div>';
    }).join('') + '</div>';
}

function getReportData(period) {
    var periods = {
        daily: { chartTitle: 'Hourly Breakdown — Today', chartLabels: ['8AM', '9AM', '10AM', '11AM', '12PM', '1PM', '2PM', '3PM', '4PM', '5PM', '6PM', '7PM'], chartValues: [1200, 3400, 5600, 8900, 12300, 9800, 7600, 6500, 8200, 11400, 9300, 4800], tableTitle: 'Hourly Details', tableCols: ['Hour', 'Orders', 'Revenue', 'Avg. Value', 'Top Item'], tableRows: [['8-9 AM', '3', '₹1,200', '₹400', 'Margherita'], ['9-10 AM', '8', '₹3,400', '₹425', 'Cold Coffee'], ['10-11 AM', '12', '₹5,600', '₹467', 'Pepperoni Feast'], ['11-12 PM', '18', '₹8,900', '₹494', 'Pizza Combo'], ['12-1 PM', '25', '₹12,300', '₹492', 'Margherita'], ['1-2 PM', '21', '₹9,800', '₹467', 'Family Feast']], kpis: [{ label: 'Revenue', value: '₹48,520', change: '↑ 12.5%', trend: 'up' }, { label: 'Orders', value: '127', change: '↑ 8.3%', trend: 'up' }, { label: 'Avg. Order', value: '₹382', change: '↓ 2.1%', trend: 'down' }, { label: 'New Customers', value: '18', change: '↑ 5.8%', trend: 'up' }] },
        weekly: { chartTitle: 'Day-by-Day — This Week', chartLabels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'], chartValues: [32400, 28900, 35600, 41200, 48520, 52300, 45800], tableTitle: 'Daily Summary', tableCols: ['Day', 'Orders', 'Revenue', 'Avg. Value', 'Growth'], tableRows: [['Monday', '89', '₹32,400', '₹364', '--'], ['Tuesday', '78', '₹28,900', '₹371', '-10.8%'], ['Wednesday', '95', '₹35,600', '₹375', '+23.2%'], ['Thursday', '108', '₹41,200', '₹381', '+15.7%'], ['Friday', '127', '₹48,520', '₹382', '+17.8%'], ['Saturday', '138', '₹52,300', '₹379', '+7.8%'], ['Sunday', '121', '₹45,800', '₹379', '-12.4%']], kpis: [{ label: 'Weekly Revenue', value: '₹2,84,720', change: '↑ 15.2%', trend: 'up' }, { label: 'Weekly Orders', value: '756', change: '↑ 11.4%', trend: 'up' }, { label: 'Avg. Order', value: '₹377', change: '↑ 3.2%', trend: 'up' }, { label: 'New Customers', value: '89', change: '↑ 22.1%', trend: 'up' }] },
        monthly: { chartTitle: 'Week-by-Week — February', chartLabels: ['Week 1', 'Week 2', 'Week 3', 'Week 4'], chartValues: [185000, 210000, 198000, 245000], tableTitle: 'Weekly Breakdown', tableCols: ['Week', 'Orders', 'Revenue', 'Avg. Value', 'Top Category'], tableRows: [['Week 1', '485', '₹1,85,000', '₹381', 'Pizza'], ['Week 2', '552', '₹2,10,000', '₹380', 'Pizza'], ['Week 3', '518', '₹1,98,000', '₹382', 'Japanese'], ['Week 4', '642', '₹2,45,000', '₹382', 'Combo']], kpis: [{ label: 'Monthly Revenue', value: '₹8,38,000', change: '↑ 18.7%', trend: 'up' }, { label: 'Monthly Orders', value: '2,197', change: '↑ 14.2%', trend: 'up' }, { label: 'Avg. Order', value: '₹381', change: '↑ 1.8%', trend: 'up' }, { label: 'Customer Growth', value: '+342', change: '↑ 25.3%', trend: 'up' }] },
        quarterly: { chartTitle: 'Monthly — Q1 2026', chartLabels: ['Jan', 'Feb', 'Mar'], chartValues: [720000, 838000, 910000], tableTitle: 'Monthly Breakdown', tableCols: ['Month', 'Orders', 'Revenue', 'Growth', 'Top Item'], tableRows: [['January', '1,890', '₹7,20,000', '--', 'Margherita'], ['February', '2,197', '₹8,38,000', '+16.4%', 'Pepperoni'], ['March (proj)', '2,380', '₹9,10,000', '+8.6%', 'Pizza Combo']], kpis: [{ label: 'Q1 Revenue', value: '₹24,68,000', change: '↑ 22.4%', trend: 'up' }, { label: 'Q1 Orders', value: '6,467', change: '↑ 18.9%', trend: 'up' }, { label: 'Avg. Order', value: '₹382', change: '↑ 4.1%', trend: 'up' }, { label: 'Retention Rate', value: '78%', change: '↑ 5.2%', trend: 'up' }] },
        halfyearly: { chartTitle: '6-Month Summary', chartLabels: ['Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'], chartValues: [580000, 620000, 690000, 720000, 838000, 910000], tableTitle: 'Monthly Overview', tableCols: ['Month', 'Orders', 'Revenue', 'Avg. Value', 'YoY Growth'], tableRows: [['October', '1,520', '₹5,80,000', '₹382', '+12%'], ['November', '1,625', '₹6,20,000', '₹381', '+15%'], ['December', '1,810', '₹6,90,000', '₹381', '+18%'], ['January', '1,890', '₹7,20,000', '₹381', '+20%'], ['February', '2,197', '₹8,38,000', '₹382', '+25%'], ['March', '2,380', '₹9,10,000', '₹382', '+28%']], kpis: [{ label: 'H2 Revenue', value: '₹43,58,000', change: '↑ 28.4%', trend: 'up' }, { label: 'H2 Orders', value: '11,422', change: '↑ 22.1%', trend: 'up' }, { label: 'Avg. Order', value: '₹381', change: '↑ 3.8%', trend: 'up' }, { label: 'Active Customers', value: '1,245', change: '↑ 34.2%', trend: 'up' }] },
        annual: { chartTitle: 'Year Overview — 2025-2026', chartLabels: ['Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Jan', 'Feb', 'Mar'], chartValues: [380000, 420000, 450000, 480000, 510000, 550000, 580000, 620000, 690000, 720000, 838000, 910000], tableTitle: 'Annual Overview', tableCols: ['Month', 'Orders', 'Revenue', 'Growth', 'Highlight'], tableRows: [['Apr 2025', '980', '₹3,80,000', '--', 'Launch month'], ['Jul 2025', '1,260', '₹4,80,000', '+12%', 'Japanese menu added'], ['Oct 2025', '1,520', '₹5,80,000', '+21%', 'Festival season'], ['Jan 2026', '1,890', '₹7,20,000', '+24%', 'New year promos'], ['Feb 2026', '2,197', '₹8,38,000', '+16%', 'Best month'], ['Mar 2026', '2,380', '₹9,10,000', '+9%', 'Projected']], kpis: [{ label: 'Annual Revenue', value: '₹71,48,000', change: '↑ 42.8%', trend: 'up' }, { label: 'Annual Orders', value: '18,720', change: '↑ 35.2%', trend: 'up' }, { label: 'Avg. Order', value: '₹382', change: '↑ 8.4%', trend: 'up' }, { label: 'Total Customers', value: '2,890', change: '↑ 52.1%', trend: 'up' }] }
    };
    return periods[period] || periods.daily;
}

function exportReport(format) { showAdminToast('Report exported as ' + format.toUpperCase(), 'success'); }

// --- HELPERS ---
function capitalize(s) { return s.charAt(0).toUpperCase() + s.slice(1); }
function formatTime(d) { var h = d.getHours(), m = d.getMinutes(), ap = h >= 12 ? 'PM' : 'AM'; h = h % 12 || 12; return h + ':' + ('0' + m).slice(-2) + ' ' + ap; }
function formatDate(d) { var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']; return d.getDate() + ' ' + months[d.getMonth()]; }

function showAdminToast(msg, type) {
    var t = document.getElementById('admin-toast');
    var icons = { success: 'check_circle', error: 'error', warning: 'warning' };
    t.className = 'admin-toast ' + (type || 'success');
    document.getElementById('toast-icon').textContent = icons[type] || 'check_circle';
    document.getElementById('toast-msg').textContent = msg;
    t.style.display = 'flex';
    setTimeout(function () { t.style.display = 'none'; }, 3000);
}

function setupFormListeners() {
    var nameInput = document.getElementById('mi-name');
    var descInput = document.getElementById('mi-desc');
    if (nameInput) nameInput.addEventListener('input', updateCharCounts);
    if (descInput) descInput.addEventListener('input', updateCharCounts);
    var catSelect = document.getElementById('mi-category');
    if (catSelect) catSelect.addEventListener('change', togglePizzaOptions);

    // Drag & drop
    var zone = document.getElementById('image-upload-zone');
    if (zone) {
        zone.addEventListener('dragover', function (e) { e.preventDefault(); zone.classList.add('drag-over'); });
        zone.addEventListener('dragleave', function () { zone.classList.remove('drag-over'); });
        zone.addEventListener('drop', function (e) {
            e.preventDefault(); zone.classList.remove('drag-over');
            if (e.dataTransfer.files.length) { document.getElementById('mi-image-input').files = e.dataTransfer.files; handleImageUpload(document.getElementById('mi-image-input')); }
        });
    }
}

function updateCharCounts() {
    var n = document.getElementById('mi-name');
    var d = document.getElementById('mi-desc');
    if (n) document.getElementById('mi-name-count').textContent = n.value.length;
    if (d) document.getElementById('mi-desc-count').textContent = d.value.length;
}
