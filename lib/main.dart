import 'dart:typed_data';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

const String namaToko = 'iKo';
const String logoIkoAsset = 'assets/logo_iko_fix.png';
const int batasStokTipis = 5;

void main() => runApp(const TokoApp());

class Warna {
  static const tinta = Color(0xFFB5121B);
  static const kertas = Color(0xFFFFF8F6);
  static const garis = Color(0xFFF0DEDA);
  static const garisTegas = Color(0xFFD9BDB8);
  static const label = Color(0xFFFFE7E3);
  static const labelMuda = Color(0xFFFFF0ED);
  static const stempel = Color(0xFF9E1018);
  static const teks = Color(0xFF421C1D);
  static const redup = Color(0xFF806D6B);
}

class Gaya {
  static const _tabular = [FontFeature.tabularFigures()];

  static const judulHalaman = TextStyle(
    fontSize: 29,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    height: 1.1,
    color: Warna.teks,
  );
  static const judulBagian = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: Warna.teks,
  );
  static const judulBaris = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Warna.teks,
  );
  static const redup = TextStyle(
    fontSize: 13,
    height: 1.35,
    color: Warna.redup,
  );
  static const harga = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Warna.teks,
    fontFeatures: _tabular,
  );
  static const angkaBesar = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -1,
    height: 1.1,
    color: Warna.teks,
    fontFeatures: _tabular,
  );
}

const EdgeInsets sisi = EdgeInsets.symmetric(horizontal: 20);

// DATA
class Product {
  Product({
    required this.name,
    required this.price,
    required this.stock,
    this.gambar,
  });

  String name;
  int price;
  int stock;
  Uint8List? gambar;

  bool get habis => stock <= 0;
  bool get stokTipis => stock > 0 && stock <= batasStokTipis;
  bool get perluRestok => stock <= batasStokTipis;
}

class Order {
  const Order({
    required this.nomor,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.date,
    this.gambar,
  });

  final int nomor;
  final String productName;
  final int price;
  final int quantity;
  final DateTime date;
  final Uint8List? gambar;

  int get total => price * quantity;
}

class TokoStore extends ChangeNotifier {
  final List<Product> products = [
    Product(name: 'Sofa', price: 750000, stock: 20),
    Product(name: 'Kursi', price: 150000, stock: 15),
    Product(name: 'Meja', price: 2200000, stock: 10),
    Product(name: 'Lampu', price: 350000, stock: 25),
  ];
  final List<Order> orders = [];

  int get pendapatan => orders.fold(0, (jumlah, o) => jumlah + o.total);

  List<Order> get pesananHariIni {
    final sekarang = DateTime.now();
    return orders.where((o) => samaHari(o.date, sekarang)).toList();
  }

  int get pendapatanHariIni =>
      pesananHariIni.fold(0, (jumlah, o) => jumlah + o.total);

  int get terjualHariIni =>
      pesananHariIni.fold(0, (jumlah, o) => jumlah + o.quantity);

  List<Product> get perluRestok =>
      products.where((p) => p.perluRestok).toList()
        ..sort((a, b) => a.stock.compareTo(b.stock));

  void tambahBarang(Product p) {
    products.add(p);
    notifyListeners();
  }

  void ubahBarang(
    Product p, {
    required String nama,
    required int harga,
    required int stok,
    required Uint8List? gambar,
  }) {
    p.name = nama;
    p.price = harga;
    p.stock = stok;
    p.gambar = gambar;
    notifyListeners();
  }

  void hapusBarang(Product p) {
    products.remove(p);
    notifyListeners();
  }

  Order buatPesanan(Product p, int jumlah) {
    p.stock -= jumlah;
    final order = Order(
      nomor: orders.length + 1,
      productName: p.name,
      price: p.price,
      quantity: jumlah,
      date: DateTime.now(),
      gambar: p.gambar,
    );
    orders.add(order);
    notifyListeners();
    return order;
  }
}

final TokoStore store = TokoStore();
const _namaHari = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu', //
];
const _namaBulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', //
  'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String _dua(int n) => n.toString().padLeft(2, '0');

String rupiah(int value) {
  final s = value.abs().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp ${value < 0 ? '-' : ''}$buf';
}

String formatJam(DateTime d) => '${_dua(d.hour)}:${_dua(d.minute)}';

String formatTanggal(DateTime d) =>

    '${_dua(d.day)}/${_dua(d.month)}/${d.year} ${formatJam(d)}';
String tanggalPanjang(DateTime d) =>
    '${_namaHari[d.weekday - 1]}, ${d.day} ${_namaBulan[d.month - 1]} ${d.year}';

bool samaHari(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String labelHari(DateTime d) {
  final sekarang = DateTime.now();
  if (samaHari(d, sekarang)) return 'Hari ini';
  if (samaHari(d, sekarang.subtract(const Duration(days: 1)))) {
    return 'Kemarin';
  }
  return '${d.day} ${_namaBulan[d.month - 1]} ${d.year}';
}

String nomorNota(int n) => '#${n.toString().padLeft(4, '0')}';

void tampilkanPesan(BuildContext context, String text, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? Warna.stempel : Warna.tinta,
      ),
    );
}

Future<bool> konfirmasi(
  BuildContext context,
  String judul,
  String isi, {
  String yes = 'Ya',
  bool bahaya = false,
}) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(judul),
      content: Text(isi),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: bahaya ? Warna.stempel : null,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(yes),
        ),
      ],
    ),
  );
  return hasil ?? false;
}

void bukaFormBarang(BuildContext context, [Product? product]) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
  );
}

void bukaFormPesanan(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const OrderFormScreen()),
  );
}

final ImagePicker _picker = ImagePicker();

Future<Uint8List?> ambilGambar(BuildContext context, ImageSource sumber) async {
  try {
    final file = await _picker.pickImage(
      source: sumber,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 80,
    );
    if (file == null) return null;
    return await file.readAsBytes();
  } catch (_) {
    if (context.mounted) {
      tampilkanPesan(
        context,
        sumber == ImageSource.camera
            ? 'Kamera tidak bisa dibuka. Periksa izin kamera atau coba lewat galeri.'
            : 'Galeri tidak bisa dibuka. Periksa izin akses foto di pengaturan.',
        error: true,
      );
    }
    return null;
  }
}

Future<bool> tampilkanNota(
  BuildContext context,
  Order order, {
  bool setelahSimpan = false,
}) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Nota(order: order),
              const SizedBox(height: 16),
              if (setelahSimpan)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Catat lagi'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Selesai'),
                      ),
                    ),
                  ],
                )
              else
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Tutup'),
                ),
            ],
          ),
        ),
      ),
    ),
  );
  return hasil ?? false;
}

List<Widget> denganGaris(List<Widget> items) => [
      for (int i = 0; i < items.length; i++) ...[
        if (i > 0) const Divider(height: 1, thickness: 1, color: Warna.garis),
        items[i],
      ],
    ];

// WIDGET BANTUAN
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Warna.garis),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class HeaderHalaman extends StatelessWidget {
  const HeaderHalaman({super.key, required this.judul, this.keterangan});

  final String judul;
  final String? keterangan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(judul, style: Gaya.judulHalaman),
          if (keterangan != null) ...[
            const SizedBox(height: 6),
            Text(keterangan!, style: Gaya.redup),
          ],
        ],
      ),
    );
  }
}

class JudulBagian extends StatelessWidget {
  const JudulBagian(this.teks, {super.key, this.aksi});

  final String teks;
  final Widget? aksi;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
      child: Row(
        children: [
          Expanded(child: Text(teks, style: Gaya.judulBagian)),
          if (aksi != null) aksi!,
        ],
      ),
    );
  }
}

class BarisAngka extends StatelessWidget {
  const BarisAngka(this.label, this.nilai, {super.key});

  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Gaya.redup.copyWith(fontSize: 14)),
          Text(nilai, style: Gaya.harga),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.judul,
    required this.pesan,
    this.tombol,
    this.onTombol,
  });

  final String judul;
  final String pesan;
  final String? tombol;
  final VoidCallback? onTombol;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(judul, textAlign: TextAlign.center, style: Gaya.judulBagian),
          const SizedBox(height: 6),
          Text(pesan, textAlign: TextAlign.center, style: Gaya.redup),
          if (tombol != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: onTombol, child: Text(tombol!)),
          ],
        ],
      ),
    );
  }
}

class GarisPutus extends StatelessWidget {
  const GarisPutus({super.key, this.warna = Warna.garisTegas});

  final Color warna;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final jumlah = (c.maxWidth / 8).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            jumlah,
            (_) => SizedBox(
              width: 4,
              height: 1.5,
              child: DecoratedBox(decoration: BoxDecoration(color: warna)),
            ),
          ),
        );
      },
    );
  }
}

class _TepiGerigi extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const tinggi = 6.0;
    final n = (size.width / 10).floor();
    final langkah = size.width / n;
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - tinggi);
    for (int i = n; i > 0; i--) {
      p.lineTo(langkah * (i - 0.5), size.height);
      p.lineTo(langkah * (i - 1), size.height - tinggi);
    }
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class Nota extends StatelessWidget {
  const Nota({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    const tebal = TextStyle(fontWeight: FontWeight.w700);

    return ClipPath(
      clipper: _TepiGerigi(),
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 34),
        child: DefaultTextStyle(
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.5,
            color: Warna.teks,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                namaToko,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              Text(
                'Nota ${nomorNota(order.nomor)}',
                textAlign: TextAlign.center,
              ),
              Text(formatTanggal(order.date), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              const GarisPutus(),
              const SizedBox(height: 12),
              Text(order.productName),
              Row(
                children: [
                  Expanded(
                    child: Text('${order.quantity} x ${rupiah(order.price)}'),
                  ),
                  Text(rupiah(order.total)),
                ],
              ),
              const SizedBox(height: 12),
              const GarisPutus(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: tebal),
                  Text(
                    rupiah(order.total),
                    style: tebal.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget teksStok(Product p) {
  const merah = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: Warna.stempel,
  );
  if (p.habis) return const Text('Habis', style: merah);
  if (p.stokTipis) return Text('Sisa ${p.stock}', style: merah);
  return Text('Stok ${p.stock}', style: Gaya.redup);
}

class GambarBarang extends StatelessWidget {
  const GambarBarang({
    super.key,
    required this.nama,
    required this.gambar,
    this.radius = 10,
  });

  final String nama;
  final Uint8List? gambar;
  final double radius;

  Widget _placeholder() {
    return LayoutBuilder(
      builder: (context, c) {
        final sisiPendek = c.biggest.shortestSide;
        final ukuran = sisiPendek.isFinite ? sisiPendek : 48.0;
        final huruf = nama.trim().isEmpty ? '?' : nama.trim()[0].toUpperCase();
        return Container(
          color: Warna.garis,
          alignment: Alignment.center,
          child: Text(
            huruf,
            style: TextStyle(
              fontSize: ukuran * 0.4,
              fontWeight: FontWeight.w700,
              color: Warna.redup,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: gambar == null
          ? _placeholder()
          : Image.memory(
              gambar!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
              errorBuilder: (context, error, stack) => _placeholder(),
            ),
    );
  }
}

class KartuBarang extends StatelessWidget {
  const KartuBarang({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Warna.garis),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: product.habis ? 0.4 : 1,
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: GambarBarang(
                  nama: product.name,
                  gambar: product.gambar,
                  radius: 0,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Gaya.judulBaris,
                  ),
                  const SizedBox(height: 2),
                  Text(rupiah(product.price), style: Gaya.harga),
                  const SizedBox(height: 4),
                  teksStok(product),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BarisBarang extends StatelessWidget {
  const BarisBarang({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: GambarBarang(
                nama: product.name,
                gambar: product.gambar,
                radius: 8,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Gaya.judulBaris,
                  ),
                  const SizedBox(height: 3),
                  teksStok(product),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(rupiah(product.price), style: Gaya.harga),
          ],
        ),
      ),
    );
  }
}

class BarisPesanan extends StatelessWidget {
  const BarisPesanan({super.key, required this.order, this.tampilHari = false});

  final Order order;
  final bool tampilHari;

  @override
  Widget build(BuildContext context) {
    final waktu = tampilHari
        ? '${labelHari(order.date)}, ${formatJam(order.date)}'
        : formatJam(order.date);

    return InkWell(
      onTap: () => tampilkanNota(context, order),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: GambarBarang(
                nama: order.productName,
                gambar: order.gambar,
                radius: 8,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Gaya.judulBaris,
                  ),
                  const SizedBox(height: 3),
                  Text('$waktu, ${order.quantity} item', style: Gaya.redup),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(rupiah(order.total), style: Gaya.harga),
          ],
        ),
      ),
    );
  }
}

// APP
class TokoApp extends StatelessWidget {
  const TokoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: namaToko,
      theme: _tema(),
      home: const SplashScreen(),
    );
  }
}

ThemeData _tema() {
  final skema = ColorScheme.fromSeed(
    seedColor: Warna.tinta,
    brightness: Brightness.light,
  ).copyWith(
    primary: Warna.tinta,
    onPrimary: Colors.white,
    secondary: const Color(0xFFE16A62),
    onSecondary: Colors.white,
    secondaryContainer: Warna.label,
    onSecondaryContainer: Warna.teks,
    error: Warna.stempel,
    surface: Colors.white,
    onSurface: Warna.teks,
    outline: Warna.garisTegas,
  );

  final bentukInput = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Warna.garisTegas),
  );
  final bentukTombol = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: skema,
    scaffoldBackgroundColor: Warna.kertas,
    appBarTheme: const AppBarTheme(
      backgroundColor: Warna.kertas,
      foregroundColor: Warna.teks,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: Warna.teks,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: bentukInput,
      enabledBorder: bentukInput,
      focusedBorder: bentukInput.copyWith(
        borderSide: const BorderSide(color: Warna.tinta, width: 1.8),
      ),
      errorBorder: bentukInput.copyWith(
        borderSide: const BorderSide(color: Warna.stempel),
      ),
      focusedErrorBorder: bentukInput.copyWith(
        borderSide: const BorderSide(color: Warna.stempel, width: 1.6),
      ),
      labelStyle: const TextStyle(color: Warna.redup),
      prefixIconColor: Warna.redup,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Warna.tinta,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE8D4D1),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size(88, 52),
        shape: bentukTombol,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Warna.tinta,
        minimumSize: const Size(88, 52),
        shape: bentukTombol,
        side: const BorderSide(color: Warna.garisTegas),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Warna.tinta,
      foregroundColor: Colors.white,
      extendedTextStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Warna.label,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? Warna.tinta
              : Warna.redup,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? Warna.tinta
              : Warna.redup,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      backgroundColor: Warna.teks,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

// SPLASH SCREEN

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 420),
          pageBuilder: (context, animasi, sekunder) => const LoginScreen(),
          transitionsBuilder: (context, animasi, sekunder, child) =>
              FadeTransition(opacity: animasi, child: child),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Warna.tinta,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _LingkaranDekorasi(diameter: 260, warna: Colors.white.withOpacity(.08)),
          ),
          Positioned(
            bottom: -115,
            left: -65,
            child: _LingkaranDekorasi(diameter: 290, warna: Colors.white.withOpacity(.07)),
          ),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: .82, end: 1),
              duration: const Duration(milliseconds: 900), //ubah di sini
              curve: Curves.easeOutBack,
              builder: (context, nilai, child) => Transform.scale(
                scale: nilai,
                child: Opacity(opacity: nilai.clamp(0, 1).toDouble(), child: child),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: Warna.tinta,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.13),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Image.asset(
                      logoIkoAsset,
                      width: 68,
                      height: 68,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.storefront_rounded,
                              color: Warna.tinta, size: 42),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    namaToko,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'KELOLA TOKO JADI LEBIH MUDAH',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      letterSpacing: 2.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 34),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LingkaranDekorasi extends StatelessWidget {
  const _LingkaranDekorasi({required this.diameter, required this.warna});
  final double diameter;
  final Color warna;

  @override
  Widget build(BuildContext context) => Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(shape: BoxShape.circle, color: warna),
      );
}

// LOGIN
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
    if (_loading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 550));
    if (!mounted) return;

    if (_username.text.trim() == 'staff' && _password.text == 'staff999') {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (_, animation, __) => const HomeShell(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } else {
      setState(() => _loading = false);
      tampilkanPesan(
        context,
        'Username atau password tidak sesuai.',
        error: true,
      );
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
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -105,
              right: -90,
              child: _LingkaranDekorasi(
                diameter: 250,
                warna: Warna.label.withOpacity(.8),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: Warna.tinta,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Warna.tinta.withOpacity(.2),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Image.asset(
                              logoIkoAsset,
                              width: 54,
                              height: 54,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.storefront_rounded,
                                      color: Colors.white, size: 36),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Selamat datang',
                          textAlign: TextAlign.center,
                          style: Gaya.judulHalaman,
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Masuk untuk mulai mengelola toko iKo.',
                          textAlign: TextAlign.center,
                          style: Gaya.redup,
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Warna.garis),
                            boxShadow: [
                              BoxShadow(
                                color: Warna.teks.withOpacity(.045),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Login', style: Gaya.judulBagian),
                              const SizedBox(height: 15),
                              TextFormField(
                                controller: _username,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.username],
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'staff'
                                        : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _password,
                                obscureText: _sembunyikan,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.password],
                                onFieldSubmitted: (_) => _login(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _sembunyikan
                                        ? 'Tampilkan password'
                                        : 'Sembunyikan password',
                                    icon: Icon(
                                      _sembunyikan
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () => _sembunyikan = !_sembunyikan,
                                    ),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'staff999'
                                    : null,
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _loading ? null : _login,
                                  child: _loading
                                      ? const SizedBox(
                                          height: 21,
                                          width: 21,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text('Masuk ke iKo'),
                                            SizedBox(width: 8),
                                            Icon(Icons.arrow_forward_rounded,
                                                size: 18),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: Warna.labelMuda,
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// KERANGKA UTAMA

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: [
            BerandaPage(pindahTab: (i) => setState(() => _tab = i)),
            const BarangPage(),
            const RiwayatPage(),
            const AkunPage(),
          ],
        ),
      ),
      floatingActionButton: _tab == 1
          ? FloatingActionButton.extended(
              onPressed: () => bukaFormBarang(context),
              icon: const Icon(Icons.add),
              label: const Text('Tambah barang'),
            )
          : null,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Warna.garis)),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Barang',
            ),
            NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long),
              label: 'Riwayat',
            ),
            NavigationDestination(
              icon: Icon(Icons.info_outline),
              selectedIcon: Icon(Icons.info),
              label: 'Tentang',
            ),
          ],
        ),
      ),
    );
  }
}

// BERANDA

class BerandaPage extends StatelessWidget {
  const BerandaPage({super.key, required this.pindahTab});

  final ValueChanged<int> pindahTab;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final hariIni = store.pesananHariIni;
        final restok = store.perluRestok;
        final terakhir = store.orders.reversed.take(3).toList();
        final jumlahBarang = store.products.length;
        final stokTotal = store.products.fold<int>(0, (sum, p) => sum + p.stock);

        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Warna.tinta,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        logoIkoAsset,
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.storefront_rounded,
                                color: Colors.white, size: 27),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selamat datang di',
                          style: TextStyle(
                            color: Warna.redup,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Text(
                          namaToko,
                          style: TextStyle(
                            color: Warna.teks,
                            fontSize: 23,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Warna.garis),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: Warna.tinta),
                        const SizedBox(width: 7),
                        Text(
                          '${_dua(DateTime.now().day)} ${_namaBulan[DateTime.now().month - 1].substring(0, 3)}',
                          style: const TextStyle(
                            color: Warna.teks,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: sisi,
              child: Container(
                padding: const EdgeInsets.all(21),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC91D28), Color(0xFF941019)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Warna.tinta.withOpacity(.19),
                      blurRadius: 22,
                      offset: const Offset(0, 11),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -28,
                      top: -34,
                      child: _LingkaranDekorasi(
                        diameter: 150,
                        warna: Colors.white.withOpacity(.08),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'PENDAPATAN HARI INI',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.trending_up_rounded,
                                color: Colors.white,
                                size: 19,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            rupiah(store.pendapatanHariIni),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 31,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.8,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(height: 1, color: Colors.white24),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoPendapatan(
                                icon: Icons.receipt_long_outlined,
                                label: 'Pesanan',
                                value: '${hariIni.length}',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 34,
                              color: Colors.white24,
                            ),
                            Expanded(
                              child: _InfoPendapatan(
                                icon: Icons.inventory_2_outlined,
                                label: 'Item terjual',
                                value: '${store.terjualHariIni}',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _KartuRingkas(
                      icon: Icons.widgets_outlined,
                      label: 'Jenis barang',
                      value: '$jumlahBarang',
                      caption: 'Dalam katalog',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _KartuRingkas(
                      icon: Icons.inventory_outlined,
                      label: 'Total stok',
                      value: '$stokTotal',
                      caption: 'Unit tersedia',
                    ),
                  ),
                ],
              ),
            ),
            const JudulBagian('Aksi cepat'),
            Padding(
              padding: sisi,
              child: Row(
                children: [
                  Expanded(
                    child: _AksiCepat(
                      icon: Icons.add_shopping_cart_rounded,
                      label: 'Catat penjualan',
                      primary: true,
                      onTap: () => bukaFormPesanan(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _AksiCepat(
                      icon: Icons.add_box_outlined,
                      label: 'Tambah barang',
                      onTap: () => bukaFormBarang(context),
                    ),
                  ),
                ],
              ),
            ),
            JudulBagian(
              'Perlu perhatian',
              aksi: TextButton(
                onPressed: () => pindahTab(1),
                child: const Text('Buka katalog'),
              ),
            ),
            Padding(
              padding: sisi,
              child: restok.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2EC),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: const Color(0xFFD8E7DB)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Color(0xFF4D8060)),
                          SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              'Stok aman. Belum ada barang yang perlu direstok.',
                              style: TextStyle(
                                color: Color(0xFF42634D),
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Warna.garis),
                      ),
                      child: Column(
                        children: denganGaris([
                          for (final p in restok.take(4))
                            BarisBarang(
                              product: p,
                              onTap: () => bukaFormBarang(context, p),
                            ),
                        ]),
                      ),
                    ),
            ),
            JudulBagian(
              'Pesanan terbaru',
              aksi: TextButton(
                onPressed: () => pindahTab(2),
                child: const Text('Lihat semua'),
              ),
            ),
            Padding(
              padding: sisi,
              child: terakhir.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Warna.garis),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 30, color: Warna.garisTegas),
                          SizedBox(height: 9),
                          Text('Belum ada penjualan',
                              style: Gaya.judulBaris),
                          SizedBox(height: 4),
                          Text(
                            'Pesanan yang sudah dicatat akan tampil di sini.',
                            textAlign: TextAlign.center,
                            style: Gaya.redup,
                          ),
                        ],
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Warna.garis),
                      ),
                      child: Column(
                        children: denganGaris([
                          for (final o in terakhir)
                            BarisPesanan(order: o, tampilHari: true),
                        ]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _InfoPendapatan extends StatelessWidget {
  const _InfoPendapatan({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _KartuRingkas extends StatelessWidget {
  const _KartuRingkas({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
  });
  final IconData icon;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Warna.garis),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Warna.tinta, size: 20),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                  color: Warna.teks,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                  color: Warna.teks,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                )),
            Text(caption, style: Gaya.redup.copyWith(fontSize: 11)),
          ],
        ),
      );
}

class _AksiCepat extends StatelessWidget {
  const _AksiCepat({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) => Material(
        color: primary ? Warna.tinta : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 92),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: primary ? Warna.tinta : Warna.garis,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    color: primary ? Colors.white : Warna.tinta, size: 22),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: primary ? Colors.white : Warna.teks,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// BARANG
class BarangPage extends StatefulWidget {
  const BarangPage({super.key});

  @override
  State<BarangPage> createState() => _BarangPageState();
}

class _BarangPageState extends State<BarangPage> {
  String _cari = '';
  bool _hanyaRestok = false;
  bool _grid = true;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final semua = store.products;
        final kata = _cari.trim().toLowerCase();
        final daftar = semua
            .where((p) =>
                p.name.toLowerCase().contains(kata) &&
                (!_hanyaRestok || p.perluRestok))
            .toList();
        final jumlahRestok = store.perluRestok.length;

        final keterangan = semua.isEmpty
            ? 'Belum ada barang'
            : '${semua.length} barang'
                '${jumlahRestok > 0 ? ', $jumlahRestok perlu restok' : ''}';

        return ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            HeaderHalaman(judul: 'Barang', keterangan: keterangan),
            Padding(
              padding: sisi,
              child: TextField(
                onChanged: (v) => setState(() => _cari = v),
                decoration: const InputDecoration(
                  hintText: 'Cari nama barang',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      children: [
                        _chip('Semua', !_hanyaRestok,
                            () => setState(() => _hanyaRestok = false)),
                        _chip('Perlu restok', _hanyaRestok,
                            () => setState(() => _hanyaRestok = true)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: _grid ? 'Tampilan daftar' : 'Tampilan kotak',
                    icon: Icon(
                      _grid ? Icons.view_list_outlined : Icons.grid_view_outlined,
                    ),
                    onPressed: () => setState(() => _grid = !_grid),
                  ),
                ],
              ),
            ),
            if (daftar.isEmpty)
              _kosong(context, semua.isEmpty, kata)
            else if (_grid)
              Padding(
                padding: sisi,
                child: LayoutBuilder(
                  builder: (context, c) {
                    final kolom = (c.maxWidth / 170).floor().clamp(2, 4).toInt();
                    final lebar = (c.maxWidth - 12 * (kolom - 1)) / kolom;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final p in daftar)
                          SizedBox(
                            width: lebar,
                            child: KartuBarang(
                              product: p,
                              onTap: () => bukaFormBarang(context, p),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              )
            else
              Padding(
                padding: sisi,
                child: Panel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: denganGaris([
                      for (final p in daftar)
                        BarisBarang(
                          product: p,
                          onTap: () => bukaFormBarang(context, p),
                        ),
                    ]),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _chip(String teks, bool aktif, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(teks),
      selected: aktif,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: Warna.labelMuda,
      backgroundColor: Colors.white,
      side: const BorderSide(color: Warna.garisTegas),
    );
  }

  Widget _kosong(BuildContext context, bool katalogKosong, String kata) {
    if (katalogKosong) {
      return EmptyState(
        judul: 'Belum ada barang',
        pesan: 'Tambahkan barang pertama supaya bisa dicatat dalam penjualan.',
        tombol: 'Tambah barang',
        onTombol: () => bukaFormBarang(context),
      );
    }
    if (kata.isNotEmpty) {
      return EmptyState(
        judul: 'Tidak ada hasil',
        pesan: 'Tidak ada barang bernama "$_cari". Periksa ejaan atau '
            'tambahkan sebagai barang baru.',
        tombol: 'Tambah barang',
        onTombol: () => bukaFormBarang(context),
      );
    }
    return const EmptyState(
      judul: 'Stok aman',
      pesan: 'Tidak ada barang yang perlu direstok saat ini.',
    );
  }
}

// 6. RIWAYAT

class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final urut = store.orders.reversed.toList();

        if (urut.isEmpty) {
          return ListView(
            children: [
              const HeaderHalaman(judul: 'Riwayat'),
              EmptyState(
                judul: 'Belum ada pesanan',
                pesan: 'Pesanan yang Anda catat akan muncul di sini, '
                    'lengkap dengan notanya.',
                tombol: 'Catat penjualan',
                onTombol: () => bukaFormPesanan(context),
              ),
            ],
          );
        }


        final grup = <String, List<Order>>{};
        for (final o in urut) {
          final kunci = '${o.date.year}-${o.date.month}-${o.date.day}';
          grup.putIfAbsent(kunci, () => []).add(o);
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            HeaderHalaman(
              judul: 'Riwayat',
              keterangan:
                  '${urut.length} pesanan, ${rupiah(store.pendapatan)} total',
            ),
            for (final pesanan in grup.values) ...[
              JudulBagian(
                labelHari(pesanan.first.date),
                aksi: Text(
                  rupiah(pesanan.fold(0, (j, o) => j + o.total)),
                  style: Gaya.harga.copyWith(color: Warna.redup),
                ),
              ),
              Padding(
                padding: sisi,
                child: Panel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: denganGaris([
                      for (final o in pesanan) BarisPesanan(order: o),
                    ]),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// AKUN
class AkunPage extends StatelessWidget {
  const AkunPage({super.key});

  Future<void> _keluar(BuildContext context) async {
    final ok = await konfirmasi(
      context,
      'Keluar dari iKo?',
      'Kamu akan kembali ke halaman login. Data demo akan tetap tersedia selama aplikasi berjalan.',
      yes: 'Keluar',
      bahaya: true,
    );
    if (!ok || !context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _barisInfo(IconData icon, String judul, String isi) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Warna.labelMuda,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Warna.tinta, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul, style: Gaya.judulBaris),
                const SizedBox(height: 3),
                Text(isi, style: Gaya.redup),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.only(bottom: 30),
        children: [
          const HeaderHalaman(
            judul: 'Tentang iKo',
            keterangan: 'Kenali toko dan fitur yang tersedia di aplikasi.',
          ),
          Padding(
            padding: sisi,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFC91D28), Color(0xFF941019)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(23),
              ),
              child: Row(
                children: [
                  Container(
                    width: 49,
                    height: 49,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    alignment: Alignment.center,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        logoIkoAsset,
                        width: 46,
                        height: 46,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.storefront_rounded,
                                color: Warna.tinta, size: 34),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'iKo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -.7,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Manajemen Toko Furnitur',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.storefront_rounded,
                      color: Colors.white70, size: 28),
                ],
              ),
            ),
          ),
          const JudulBagian('Informasi toko'),
          Padding(
            padding: sisi,
            child: Panel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Column(
                children: [
                  _barisInfo(
                    Icons.storefront_outlined,
                    'Nama toko',
                    'iKo Furniture',
                  ),
                  const Divider(height: 1, color: Warna.garis),
                  _barisInfo(
                    Icons.inventory_2_outlined,
                    'Katalog saat ini',
                    '${store.products.length} jenis barang tersedia dengan total ${store.products.fold<int>(0, (sum, p) => sum + p.stock)} unit stok.',
                  ),
                ],
              ),
            ),
          ),
          const JudulBagian('Tentang aplikasi'),
          Padding(
            padding: sisi,
            child: Panel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Column(
                children: [
                  _barisInfo(
                    Icons.dashboard_customize_outlined,
                    'Dashboard penjualan',
                    'Pantau pendapatan, jumlah pesanan, barang terjual, dan kondisi stok',
                  ),
                  const Divider(height: 1, color: Warna.garis),
                  _barisInfo(
                    Icons.add_box_outlined,
                    'Manajemen barang',
                    'Tambah, ubah, cari, dan hapus produk',
                  ),
                  const Divider(height: 1, color: Warna.garis),
                  _barisInfo(
                    Icons.point_of_sale_outlined,
                    'Pencatatan penjualan',
                    'Pilih produk, tentukan jumlah, hitung total otomatis, dan kurangi stok',
                  ),
                  const Divider(height: 1, color: Warna.garis),
                  _barisInfo(
                    Icons.receipt_long_outlined,
                    'Riwayat dan nota',
                    'Lihat transaksi yang pernah dicatat',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: sisi,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Warna.labelMuda,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Warna.label),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: sisi,
            child: Column(
              children: [
                const Text(
                  'iKo • Aplikasi Manajeman Toko',
                  style: TextStyle(
                    color: Warna.redup,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Versi 0.0.1', style: Gaya.redup),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _keluar(context),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Keluar dari aplikasi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Warna.stempel,
                      side: const BorderSide(color: Warna.garisTegas),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// FORM TAMBAH / UBAH BARANG
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product; // null = tambah baru, isi = ubah

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

  late Uint8List? _gambar = widget.product?.gambar;

  bool get _ubah => widget.product != null;

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;

    final nama = _name.text.trim();
    final harga = int.parse(_price.text);
    final stok = int.parse(_stock.text);

    if (_ubah) {
      store.ubahBarang(
        widget.product!,
        nama: nama,
        harga: harga,
        stok: stok,
        gambar: _gambar,
      );
    } else {
      store.tambahBarang(
        Product(name: nama, price: harga, stock: stok, gambar: _gambar),
      );
    }

    tampilkanPesan(
      context,
      _ubah ? 'Perubahan disimpan.' : '$nama ditambahkan ke katalog.',
    );
    Navigator.pop(context);
  }

  Future<void> _pilihSumber() async {
    FocusScope.of(context).unfocus();
    final aksi = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Ambil foto'),
              onTap: () => Navigator.pop(ctx, 'kamera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () => Navigator.pop(ctx, 'galeri'),
            ),
            if (_gambar != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Warna.stempel),
                title: const Text(
                  'Hapus foto',
                  style: TextStyle(color: Warna.stempel),
                ),
                onTap: () => Navigator.pop(ctx, 'hapus'),
              ),
          ],
        ),
      ),
    );
    if (aksi == null || !mounted) return;

    if (aksi == 'hapus') {
      setState(() => _gambar = null);
      return;
    }

    final bytes = await ambilGambar(
      context,
      aksi == 'kamera' ? ImageSource.camera : ImageSource.gallery,
    );
    if (bytes != null && mounted) setState(() => _gambar = bytes);
  }

  Widget _areaCover() {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_gambar != null)
            GambarBarang(nama: _name.text, gambar: _gambar, radius: 12)
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Warna.garisTegas),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 32, color: Warna.tinta),
                  SizedBox(height: 10),
                  Text('Tambah foto cover', style: Gaya.judulBaris),
                  SizedBox(height: 2),
                  Text(
                    'Ambil foto atau pilih dari galeri',
                    style: Gaya.redup,
                  ),
                ],
              ),
            ),
          if (_gambar != null)
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined, size: 16, color: Warna.teks),
                    SizedBox(width: 6),
                    Text(
                      'Ubah foto',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Warna.teks,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pilihSumber,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _hapus() async {
    final p = widget.product!;
    final ok = await konfirmasi(
      context,
      'Hapus barang?',
      '"${p.name}" akan dihapus dari katalog. Riwayat pesanan tidak ikut terhapus.',
      yes: 'Hapus',
      bahaya: true,
    );
    if (!ok || !mounted) return;

    store.hapusBarang(p);
    tampilkanPesan(context, 'Barang dihapus.');
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
      appBar: AppBar(title: Text(_ubah ? 'Ubah barang' : 'Tambah barang')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _areaCover(),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Nama barang'),
                validator: (v) {
                  final nama = v?.trim() ?? '';
                  if (nama.isEmpty) return 'Nama barang wajib diisi';
                  final kembar = store.products.any((p) =>
                      p != widget.product &&
                      p.name.toLowerCase() == nama.toLowerCase());
                  return kembar ? 'Barang ini sudah ada di katalog' : null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                decoration: const InputDecoration(
                  labelText: 'Harga per item',
                  prefixText: 'Rp ',
                ),
                validator: (v) {
                  final harga = int.tryParse(v ?? '');
                  if (harga == null) return 'Harga wajib diisi';
                  if (harga <= 0) return 'Harga harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _stock,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onFieldSubmitted: (_) => _simpan(),
                decoration: const InputDecoration(
                  labelText: 'Jumlah stok',
                  helperText: 'Isi 0 jika barang sedang habis.',
                ),
                validator: (v) =>
                    int.tryParse(v ?? '') == null ? 'Stok wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _simpan,
                child: Text(_ubah ? 'Simpan perubahan' : 'Simpan barang'),
              ),
              if (_ubah) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _hapus,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus barang'),
                  style: TextButton.styleFrom(
                    foregroundColor: Warna.stempel,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// FORM CATAT PENJUALAN 
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

  bool get _valid {
    final p = _dipilih;
    return p != null && _qty >= 1 && _qty <= p.stock;
  }

  String? get _errorQty {
    final p = _dipilih;
    if (p == null || _qtyController.text.isEmpty) return null;
    if (_qty < 1) return 'Jumlah minimal 1';
    if (_qty > p.stock) return 'Stok ${p.name} hanya tersisa ${p.stock}';
    return null;
  }

  void _ubahQty(int delta) {
    final p = _dipilih;
    if (p == null) return;
    final baru = (_qty + delta).clamp(1, p.stock).toInt();
    setState(() => _qtyController.text = '$baru');
  }

  Future<void> _pilihBarang() async {
    final hasil = await showModalBottomSheet<Product>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      builder: (ctx) => SafeArea(
        child: store.products.isEmpty
            ? const Padding(
                padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Text(
                  'Belum ada barang di katalog. Tambahkan barang dulu dari tab Barang.',
                  style: Gaya.redup,
                ),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final p in store.products)
                    ListTile(
                      enabled: !p.habis,
                      selected: p == _dipilih,
                      selectedColor: Warna.tinta,
                      leading: SizedBox(
                        width: 44,
                        height: 44,
                        child: GambarBarang(
                          nama: p.name,
                          gambar: p.gambar,
                          radius: 8,
                        ),
                      ),
                      title: Text(p.name),
                      subtitle: Text(rupiah(p.price)),
                      trailing: teksStok(p),
                      onTap: () => Navigator.pop(ctx, p),
                    ),
                ],
              ),
      ),
    );
    if (hasil == null) return;
    setState(() {
      _dipilih = hasil;
      _qtyController.text = '1';
    });
  }

  Future<void> _simpan() async {
    final p = _dipilih;
    if (p == null || !_valid) return;

    final order = store.buatPesanan(p, _qty);
    final lagi = await tampilkanNota(context, order, setelahSimpan: true);
    if (!mounted) return;

    if (lagi) {
      setState(() {
        _dipilih = null;
        _qtyController.clear();
      });
    } else {
      Navigator.pop(context);
    }
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
      appBar: AppBar(title: const Text('Catat penjualan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Panel(
              onTap: _pilihBarang,
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    if (p != null) ...[
                      SizedBox(
                        width: 56,
                        height: 56,
                        child: GambarBarang(
                          nama: p.name,
                          gambar: p.gambar,
                          radius: 8,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: p == null
                          ? Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(
                                'Pilih barang',
                                style: Gaya.judulBaris.copyWith(
                                  color: Warna.redup,
                                ),
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Gaya.judulBaris,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${rupiah(p.price)} per item, stok tersedia ${p.stock}',
                                  style: Gaya.redup,
                                ),
                              ],
                            ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Warna.redup),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: IconButton.filledTonal(
                    tooltip: 'Kurangi',
                    onPressed: p == null ? null : () => _ubahQty(-1),
                    icon: const Icon(Icons.remove),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _qtyController,
                    enabled: p != null,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Jumlah',
                      errorText: _errorQty,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: IconButton.filledTonal(
                    tooltip: 'Tambah',
                    onPressed: p == null ? null : () => _ubahQty(1),
                    icon: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Warna.garis)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total', style: Gaya.redup),
                  Text(
                    rupiah(_total),
                    style: Gaya.harga.copyWith(fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: FilledButton(
                  onPressed: _valid ? _simpan : null,
                  child: const Text('Simpan pesanan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}