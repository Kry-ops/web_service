import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const TokoApp());

// ================= DATA =================

const int batasStokTipis = 5;

class Product {
  String name;
  int price;
  int stock;

  Product({required this.name, required this.price, required this.stock});

  bool get stokTipis => stock <= batasStokTipis;
}

class Order {
  final String productName;
  final int quantity;
  final int total;
  final DateTime date;

  Order({
    required this.productName,
    required this.quantity,
    required this.total,
    required this.date,
  });
}

class AppData {
  static final List<Product> products = [
    Product(name: 'Mouse Wireless', price: 75000, stock: 20),
    Product(name: 'Keyboard', price: 150000, stock: 15),
    Product(name: 'Headset', price: 120000, stock: 10),
    Product(name: 'Flashdisk 32GB', price: 55000, stock: 25),
  ];

  static final List<Order> orders = [];

  static int get pendapatan => orders.fold(0, (sum, o) => sum + o.total);
  static int get jumlahStokTipis =>
      products.where((p) => p.stokTipis).length;
}

// ================= HELPER =================

/// 150000 -> "Rp 150.000"
String rupiah(int value) {
  final s = value.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp ${value < 0 ? '-' : ''}$buf';
}

/// DateTime -> "06/11/2026 14:30"
String formatTanggal(DateTime d) {
  String dua(int n) => n.toString().padLeft(2, '0');
  return '${dua(d.day)}/${dua(d.month)}/${d.year} ${dua(d.hour)}:${dua(d.minute)}';
}

void tampilkanPesan(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
}

Future<bool> konfirmasi(
  BuildContext context,
  String judul,
  String isi, {
  String yes = 'Ya',
}) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(judul),
      content: Text(isi),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(yes),
        ),
      ],
    ),
  );
  return hasil ?? false;
}

// ================= WIDGET BANTUAN =================

class SoftCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets margin;

  const SoftCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const EmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= APP =================

class TokoApp extends StatelessWidget {
  const TokoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Toko Kita',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ================= 1. SPLASH SCREEN =================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          builder: (context, value, child) =>
              Opacity(opacity: value, child: child),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag, color: Colors.white, size: 85),
              SizedBox(height: 20),
              Text(
                'Toko Kita',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Kelola barang dan pesanan dalam satu aplikasi',
                style: TextStyle(color: Colors.white70),
              ),
              SizedBox(height: 30),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= 2. LOGIN SCREEN =================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _sembunyikan = true;
  bool _loading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    if (_username.text.trim() == 'admin' && _password.text == 'admin123') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      setState(() => _loading = false);
      tampilkanPesan(context, 'Username atau password salah.', error: true);
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Icon(Icons.store, size: 85, color: Colors.indigo),
                  const SizedBox(height: 15),
                  const Text(
                    'Selamat datang',
                    style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
                  ),
                  const Text('Masuk untuk mengelola toko Anda'),
                  const SizedBox(height: 35),
                  TextFormField(
                    controller: _username,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Username wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _password,
                    obscureText: _sembunyikan,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _sembunyikan
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _sembunyikan = !_sembunyikan),
                      ),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Password wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Masuk'),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Demo: admin / admin123',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================= 3. DASHBOARD =================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Refresh angka dashboard setiap kali kembali dari halaman lain.
  Future<void> _buka(Widget halaman) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => halaman),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Toko')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3949AB), Color(0xFF5C6BC0)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Halo, Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Total pendapatan',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  rupiah(AppData.pendapatan),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _infoCard(
                  'Barang',
                  '${AppData.products.length}',
                  Icons.inventory,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoCard(
                  'Pesanan',
                  '${AppData.orders.length}',
                  Icons.shopping_cart,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoCard(
                  'Stok tipis',
                  '${AppData.jumlahStokTipis}',
                  Icons.warning_amber_rounded,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          const Text(
            'Menu utama',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _menu('Katalog barang', 'Lihat, cari, ubah, dan hapus barang',
              Icons.storefront, Colors.indigo, const CatalogScreen()),
          _menu('Tambah barang', 'Daftarkan barang baru ke katalog',
              Icons.add_box, Colors.teal, const ProductFormScreen()),
          _menu('Buat pesanan', 'Catat penjualan dan kurangi stok',
              Icons.shopping_cart, Colors.orange, const OrderFormScreen()),
          _menu('Riwayat pesanan', 'Semua pesanan yang sudah dibuat',
              Icons.history, Colors.purple, const HistoryScreen()),
          _menu('Profil admin', 'Akun dan keluar', Icons.person,
              Colors.blueGrey, const ProfileScreen()),
        ],
      ),
    );
  }

  Widget _infoCard(String judul, String nilai, IconData icon, Color warna) {
    return SoftCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: warna, size: 30),
          const SizedBox(height: 6),
          Text(
            nilai,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(judul, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _menu(
    String judul,
    String subjudul,
    IconData icon,
    Color warna,
    Widget halaman,
  ) {
    return SoftCard(
      onTap: () => _buka(halaman),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: warna.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: warna),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subjudul,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }
}

// ================= 4. KATALOG BARANG =================

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _cari = '';

  Future<void> _formBarang([Product? product]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
    if (mounted) setState(() {});
  }

  Future<void> _hapus(Product product) async {
    final ok = await konfirmasi(
      context,
      'Hapus barang?',
      '"${product.name}" akan dihapus dari katalog.',
      yes: 'Hapus',
    );
    if (!ok || !mounted) return;
    setState(() => AppData.products.remove(product));
    tampilkanPesan(context, 'Barang dihapus.');
  }

  @override
  Widget build(BuildContext context) {
    final daftar = AppData.products
        .where((p) => p.name.toLowerCase().contains(_cari.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Katalog Barang')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formBarang(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah barang'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
            child: TextField(
              onChanged: (v) => setState(() => _cari = v),
              decoration: const InputDecoration(
                hintText: 'Cari nama barang',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: daftar.isEmpty
                ? EmptyState(
                    icon: Icons.inventory_2_outlined,
                    message: AppData.products.isEmpty
                        ? 'Katalog masih kosong.\nTambahkan barang pertama Anda.'
                        : 'Tidak ada barang bernama "$_cari".',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(15, 10, 15, 90),
                    itemCount: daftar.length,
                    itemBuilder: (context, index) => _itemBarang(daftar[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _itemBarang(Product p) {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.indigo.withAlpha(30),
            child: const Icon(Icons.inventory_2, color: Colors.indigo),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(rupiah(p.price),
                    style: const TextStyle(color: Colors.indigo)),
                const SizedBox(height: 6),
                _lencanaStok(p),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Ubah',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _formBarang(p),
          ),
          IconButton(
            tooltip: 'Hapus',
            icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
            onPressed: () => _hapus(p),
          ),
        ],
      ),
    );
  }

  Widget _lencanaStok(Product p) {
    final warna = p.stock == 0
        ? Colors.red
        : (p.stokTipis ? Colors.orange : Colors.green);
    final teks = p.stock == 0
        ? 'Stok habis'
        : (p.stokTipis ? 'Stok tipis: ${p.stock}' : 'Stok: ${p.stock}');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: warna.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        teks,
        style: TextStyle(
          color: warna.shade800,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ================= 5. FORM TAMBAH / UBAH BARANG =================

class ProductFormScreen extends StatefulWidget {
  final Product? product; // null = tambah baru, isi = ubah

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.product?.name ?? '');
  late final TextEditingController _price =
      TextEditingController(text: widget.product?.price.toString() ?? '');
  late final TextEditingController _stock =
      TextEditingController(text: widget.product?.stock.toString() ?? '');

  bool get _ubah => widget.product != null;

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;

    final name = _name.text.trim();
    final price = int.parse(_price.text);
    final stock = int.parse(_stock.text);

    if (_ubah) {
      final p = widget.product!;
      p.name = name;
      p.price = price;
      p.stock = stock;
    } else {
      AppData.products.add(Product(name: name, price: price, stock: stock));
    }

    tampilkanPesan(
      context,
      _ubah ? 'Perubahan disimpan.' : 'Barang berhasil ditambahkan.',
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_ubah ? 'Ubah Barang' : 'Tambah Barang')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _ubah ? 'Ubah data barang' : 'Data barang baru',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nama barang'),
                validator: (v) {
                  final nama = v?.trim() ?? '';
                  if (nama.isEmpty) return 'Nama barang wajib diisi';
                  final kembar = AppData.products.any((p) =>
                      p != widget.product &&
                      p.name.toLowerCase() == nama.toLowerCase());
                  return kembar ? 'Barang ini sudah ada di katalog' : null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Harga barang',
                  prefixText: 'Rp ',
                ),
                validator: (v) {
                  final harga = int.tryParse(v ?? '');
                  if (harga == null) return 'Harga wajib diisi';
                  if (harga <= 0) return 'Harga harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _stock,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onFieldSubmitted: (_) => _simpan(),
                decoration: const InputDecoration(labelText: 'Jumlah stok'),
                validator: (v) =>
                    int.tryParse(v ?? '') == null ? 'Stok wajib diisi' : null,
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: _simpan,
                child: Text(_ubah ? 'Simpan perubahan' : 'Simpan barang'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= 6. FORM BUAT PESANAN =================

class OrderFormScreen extends StatefulWidget {
  const OrderFormScreen({super.key});

  @override
  State<OrderFormScreen> createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  Product? _dipilih;
  final _qtyController = TextEditingController();

  int get _qty => int.tryParse(_qtyController.text) ?? 0;
  int get _total => (_dipilih?.price ?? 0) * _qty;

  void _ubahQty(int delta) {
    final stok = _dipilih?.stock ?? 1;
    final baru = (_qty + delta).clamp(1, stok).toInt();
    setState(() => _qtyController.text = baru.toString());
  }

  void _simpan() {
    final p = _dipilih;

    if (p == null || _qty <= 0) {
      tampilkanPesan(context, 'Pilih barang dan isi jumlah pesanan.',
          error: true);
      return;
    }
    if (_qty > p.stock) {
      tampilkanPesan(context, 'Stok ${p.name} hanya tersisa ${p.stock}.',
          error: true);
      return;
    }

    p.stock -= _qty;
    AppData.orders.add(
      Order(
        productName: p.name,
        quantity: _qty,
        total: _total,
        date: DateTime.now(),
      ),
    );

    tampilkanPesan(context, 'Pesanan berhasil dibuat.');
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _dipilih;

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Pesanan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Form pesanan',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<Product>(
              // ignore: deprecated_member_use
              value: _dipilih,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Pilih barang'),
              items: AppData.products.map((product) {
                return DropdownMenuItem<Product>(
                  value: product,
                  enabled: product.stock > 0,
                  child: Text(
                    product.stock > 0
                        ? product.name
                        : '${product.name} (habis)',
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _dipilih = value;
                  _qtyController.text = '1';
                });
              },
            ),
            if (p != null) ...[
              const SizedBox(height: 12),
              Text(
                '${rupiah(p.price)} per item  •  Stok tersedia: ${p.stock}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 15),
            Row(
              children: [
                IconButton.filledTonal(
                  onPressed: p == null ? null : () => _ubahQty(-1),
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _qtyController,
                    enabled: p != null,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration:
                        const InputDecoration(labelText: 'Jumlah pesanan'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: p == null ? null : () => _ubahQty(1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SoftCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total harga',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    rupiah(_total),
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _simpan,
              child: const Text('Buat pesanan'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= 7. RIWAYAT PESANAN =================

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Pesanan terbaru tampil paling atas.
    final daftar = AppData.orders.reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pesanan')),
      body: daftar.isEmpty
          ? const EmptyState(
              icon: Icons.receipt_long_outlined,
              message: 'Belum ada pesanan.\nPesanan yang Anda buat muncul di sini.',
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                  child: SoftCard(
                    margin: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _ringkasan('Pesanan', '${daftar.length}'),
                        _ringkasan('Pendapatan', rupiah(AppData.pendapatan)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: daftar.length,
                    itemBuilder: (context, index) {
                      final order = daftar[index];
                      return SoftCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.indigo.withAlpha(30),
                              child: const Icon(Icons.receipt_long,
                                  color: Colors.indigo),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${order.quantity} item  •  ${formatTanggal(order.date)}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              rupiah(order.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _ringkasan(String label, String nilai) {
    return Column(
      children: [
        Text(
          nilai,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}

// ================= 8. PROFIL ADMIN =================

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _keluar(BuildContext context) async {
    final ok = await konfirmasi(
      context,
      'Keluar dari akun?',
      'Anda perlu masuk lagi untuk mengelola toko.',
      yes: 'Keluar',
    );
    if (!ok || !context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Admin')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 55,
                backgroundColor: Colors.indigo,
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Administrator',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text('admin@tokokita.com'),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => _keluar(context),
                icon: const Icon(Icons.logout),
                label: const Text('Keluar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}