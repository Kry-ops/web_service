import 'dart:typed_data';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

const String namaToko = 'Dummy';
const int batasStokTipis = 5;

void main() => runApp(const TokoApp());

// ================= PALET & GAYA =================
// Konsep visual: tinta biru pulpen, kertas nota, dan label harga kuning.
// Kuning HANYA untuk aksi "buat baru". Merah HANYA untuk stok menipis/bahaya.

class Warna {
  static const tinta = Color(0xFF1B3A57);
  static const kertas = Color(0xFFF2F4F3);
  static const garis = Color(0xFFDCE1DF);
  static const garisTegas = Color(0xFFC3CBC8);
  static const label = Color(0xFFF5C242);
  static const labelMuda = Color(0xFFFBE9B5);
  static const stempel = Color(0xFFC23B2B);
  static const teks = Color(0xFF16202A);
  static const redup = Color(0xFF5F6B73);
}

class Gaya {
  static const _tabular = [FontFeature.tabularFigures()];

  static const judulHalaman = TextStyle(
    fontSize: 28,
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

// ================= DATA =================

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
  Uint8List? gambar; // foto cover (null = belum ada foto)

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
  final Uint8List? gambar; // salinan cover saat pesanan dibuat

  int get total => price * quantity;
}

/// Satu sumber data untuk semua halaman. Semua tab otomatis ikut
/// diperbarui lewat ListenableBuilder, jadi tidak perlu setState manual
/// setiap kali kembali dari halaman lain.
class TokoStore extends ChangeNotifier {
  final List<Product> products = [
    Product(name: 'Mouse Wireless', price: 75000, stock: 20),
    Product(name: 'Keyboard', price: 150000, stock: 15),
    Product(name: 'Headset', price: 120000, stock: 10),
    Product(name: 'Flashdisk 32GB', price: 55000, stock: 25),
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

/// "07/11/2026 14:30"
String formatTanggal(DateTime d) =>
    '${_dua(d.day)}/${_dua(d.month)}/${d.year} ${formatJam(d)}';

/// "Sabtu, 7 November 2026"
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

/// Ambil foto dari kamera atau galeri. Hasilnya dikecilkan (maks 1080 px)
/// agar ringan, lalu disimpan sebagai bytes di memori.
Future<Uint8List?> ambilGambar(BuildContext context, ImageSource sumber) async {
  try {
    final file = await _picker.pickImage(
      source: sumber,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 80,
    );
    if (file == null) return null; // user membatalkan
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

// ================= WIDGET BANTUAN =================
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

/// Foto cover barang. Mengisi ruang yang diberikan induknya (SizedBox /
/// AspectRatio). Kalau belum ada foto, tampil inisial nama barang.
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

/// Kartu barang bergaya toko online: foto di atas, nama, harga, stok.
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

// ================= APP =================

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
  final skema = ColorScheme.fromSeed(seedColor: Warna.tinta).copyWith(
    primary: Warna.tinta,
    onPrimary: Colors.white,
    secondary: Warna.label,
    onSecondary: Warna.teks,
    secondaryContainer: Warna.labelMuda,
    onSecondaryContainer: Warna.teks,
    error: Warna.stempel,
    surface: Colors.white,
    onSurface: Warna.teks,
    outline: Warna.garis,
  );

  final bentukInput = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Warna.garisTegas),
  );
  final bentukTombol = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
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
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Warna.teks,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: bentukInput,
      enabledBorder: bentukInput,
      focusedBorder: bentukInput.copyWith(
        borderSide: const BorderSide(color: Warna.tinta, width: 1.6),
      ),
      errorBorder: bentukInput.copyWith(
        borderSide: const BorderSide(color: Warna.stempel),
      ),
      focusedErrorBorder: bentukInput.copyWith(
        borderSide: const BorderSide(color: Warna.stempel, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Warna.tinta,
        foregroundColor: Colors.white,
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
      backgroundColor: Warna.label,
      foregroundColor: Warna.teks,
      extendedTextStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 66,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? Warna.teks
              : Warna.redup,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

// ================= 1. SPLASH =================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 350),
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
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          builder: (context, nilai, child) =>
              Opacity(opacity: nilai, child: child),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                namaToko,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Warna.label,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Stok dan penjualan toko, dalam satu tempat.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= 2. LOGIN =================

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

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    if (_username.text.trim() == 'admin' && _password.text == 'admin123') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } else {
      setState(() => _loading = false);
      tampilkanPesan(
        context,
        'Username atau password salah. Periksa lagi lalu coba masuk.',
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      namaToko,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Warna.tinta,
                      ),
                    ),
                    const SizedBox(height: 44),
                    const Text('Masuk', style: Gaya.judulHalaman),
                    const SizedBox(height: 8),
                    const Text(
                      'Gunakan akun admin untuk mengelola barang dan pesanan.',
                      style: Gaya.redup,
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _username,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Username wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: _sembunyikan,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          tooltip: _sembunyikan
                              ? 'Tampilkan password'
                              : 'Sembunyikan password',
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
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
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
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Akun demo: admin / admin123',
                      style: Gaya.redup,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ================= 3. KERANGKA UTAMA (TAB) =================

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
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Akun',
            ),
          ],
        ),
      ),
    );
  }
}

// ================= 4. BERANDA =================

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

        return ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            HeaderHalaman(
              judul: namaToko,
              keterangan: tanggalPanjang(DateTime.now()),
            ),
            Padding(
              padding: sisi,
              child: Panel(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pendapatan hari ini', style: Gaya.redup),
                    const SizedBox(height: 6),
                    Text(
                      rupiah(store.pendapatanHariIni),
                      style: Gaya.angkaBesar,
                    ),
                    const SizedBox(height: 16),
                    const GarisPutus(),
                    const SizedBox(height: 12),
                    BarisAngka('Pesanan hari ini', '${hariIni.length}'),
                    BarisAngka('Barang terjual', '${store.terjualHariIni}'),
                    BarisAngka(
                      'Total semua pesanan',
                      rupiah(store.pendapatan),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: sisi,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => bukaFormPesanan(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Catat penjualan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Warna.label,
                    foregroundColor: Warna.teks,
                  ),
                ),
              ),
            ),
            JudulBagian(
              'Perlu restok',
              aksi: restok.length > 5
                  ? TextButton(
                      onPressed: () => pindahTab(1),
                      child: const Text('Lihat semua'),
                    )
                  : null,
            ),
            Padding(
              padding: sisi,
              child: restok.isEmpty
                  ? const Panel(
                      child: Text(
                        'Semua barang masih aman.',
                        style: Gaya.redup,
                      ),
                    )
                  : Panel(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: denganGaris([
                          for (final p in restok.take(5))
                            BarisBarang(
                              product: p,
                              onTap: () => bukaFormBarang(context, p),
                            ),
                        ]),
                      ),
                    ),
            ),
            JudulBagian(
              'Pesanan terakhir',
              aksi: terakhir.isNotEmpty
                  ? TextButton(
                      onPressed: () => pindahTab(2),
                      child: const Text('Lihat riwayat'),
                    )
                  : null,
            ),
            Padding(
              padding: sisi,
              child: terakhir.isEmpty
                  ? const Panel(
                      child: Text(
                        'Belum ada pesanan. Pesanan yang Anda catat muncul di sini.',
                        style: Gaya.redup,
                      ),
                    )
                  : Panel(
                      padding: EdgeInsets.zero,
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

// ================= 5. BARANG =================

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

// ================= 6. RIWAYAT =================

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

        // Kelompokkan per hari; urutan sudah terbaru di atas.
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

// ================= 7. AKUN =================

class AkunPage extends StatelessWidget {
  const AkunPage({super.key});

  Future<void> _keluar(BuildContext context) async {
    final ok = await konfirmasi(
      context,
      'Keluar dari akun?',
      'Anda perlu masuk lagi untuk mengelola toko.',
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const HeaderHalaman(judul: 'Akun'),
        Padding(
          padding: sisi,
          child: Panel(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Warna.tinta,
                  child: Text(
                    'A',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Administrator', style: Gaya.judulBagian),
                      SizedBox(height: 2),
                      Text('admin@tokokita.com', style: Gaya.redup),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: sisi,
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _keluar(context),
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Warna.stempel,
                side: const BorderSide(color: Warna.stempel),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ================= 8. FORM TAMBAH / UBAH BARANG =================

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

// ================= 9. FORM CATAT PENJUALAN =================

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