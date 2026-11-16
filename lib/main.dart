// FinTrack — UI Flutter (Fase 1–2): tema, navigasi, beranda, tambah pengeluaran,
// transaksi, statistik, pengaturan. Data masih di memori (belum SQLite).
// Tanpa package tambahan. Ganti seluruh isi lib/main.dart dengan file ini.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const FinTrackApp());

// ───────────────────────── Tema & warna ─────────────────────────
class C {
  static const primary = Color(0xFF16856B);
  static const dark = Color(0xFF105C4C);
  static const light = Color(0xFFE5F4EF);
  static const bg = Color(0xFFF7F9F8);
  static const surface = Colors.white;
  static const text = Color(0xFF202B28);
  static const text2 = Color(0xFF87918D);
  static const border = Color(0xFFE9EEEB);
  static const income = Color(0xFF269D75);
  static const expense = Color(0xFFE36B6B);
  static const warn = Color(0xFFE8A34A);
}

// ───────────────────────── Helper format ─────────────────────────
String rp(int n) {
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${n < 0 ? '-' : ''}Rp$b';
}

const _days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _months = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
];
String fullDate(DateTime d) => '${_days[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';
String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1].substring(0, 3)} ${d.year}';
DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
String greeting() {
  final h = DateTime.now().hour;
  if (h < 11) return 'Selamat pagi';
  if (h < 15) return 'Selamat siang';
  if (h < 18) return 'Selamat sore';
  return 'Selamat malam';
}

class RupiahFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    var d = n.text.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return const TextEditingValue();
    if (d.length > 12) d = d.substring(0, 12);
    final f = rp(int.parse(d)).substring(2);
    return TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}

int parseRp(String s) => int.tryParse(s.replaceAll('.', '')) ?? 0;

// ───────────────────────── Model & state ─────────────────────────
enum TxType { expense, income }

class Tx {
  final int id;
  final int amount; // disimpan sebagai integer rupiah
  final TxType type;
  final String cat;
  final String desc;
  final DateTime date;
  const Tx(this.id, this.amount, this.type, this.cat, this.desc, this.date);
}

const expenseCats = <String, IconData>{
  'Makanan': Icons.restaurant,
  'Minuman': Icons.local_cafe,
  'Transportasi': Icons.directions_bus,
  'Belanja': Icons.shopping_bag,
  'Pendidikan': Icons.school,
  'Kesehatan': Icons.medical_services,
  'Hiburan': Icons.movie,
  'Tagihan': Icons.receipt_long,
  'Kebutuhan Pribadi': Icons.face,
  'Lainnya': Icons.category,
};
const incomeCats = <String, IconData>{
  'Gaji': Icons.work,
  'Uang Saku': Icons.account_balance_wallet,
  'Freelance': Icons.laptop_mac,
  'Bisnis': Icons.store,
  'Hadiah': Icons.card_giftcard,
  'Pemasukan Lainnya': Icons.savings,
};
IconData iconFor(String c) => expenseCats[c] ?? incomeCats[c] ?? Icons.category;

int total(Iterable<Tx> l, TxType t) => l.where((x) => x.type == t).fold(0, (s, x) => s + x.amount);
int byRecent(Tx a, Tx b) {
  final c = b.date.compareTo(a.date);
  return c != 0 ? c : b.id.compareTo(a.id);
}

class Store extends ChangeNotifier {
  final List<Tx> txs = [];
  int initial = 0;
  int budget = 1500000;
  bool hide = false;
  int _id = 0;

  Store() {
    _seed();
  }

  // Data contoh sementara (Fase 1). Hapus saat SQLite dipasang.
  void _seed() {
    final t = dayOf(DateTime.now());
    final y = t.subtract(const Duration(days: 1));
    txs.addAll([
      Tx(++_id, 3000000, TxType.income, 'Gaji', 'Gaji bulanan', DateTime(t.year, t.month, 1)),
      Tx(++_id, 25000, TxType.expense, 'Makanan', 'Nasi padang', t),
      Tx(++_id, 18000, TxType.expense, 'Minuman', 'Kopi susu', t),
      Tx(++_id, 22000, TxType.expense, 'Transportasi', 'Ojek online', t),
      Tx(++_id, 10000, TxType.expense, 'Transportasi', 'Parkir', t),
      Tx(++_id, 185000, TxType.expense, 'Belanja', 'Belanja bulanan', y),
      Tx(++_id, 150000, TxType.expense, 'Tagihan', 'Listrik', t.subtract(const Duration(days: 3))),
      Tx(++_id, 60000, TxType.expense, 'Kesehatan', 'Obat', t.subtract(const Duration(days: 6))),
      Tx(++_id, 80000, TxType.expense, 'Pendidikan', 'Buku', t.subtract(const Duration(days: 10))),
    ]);
  }

  List<Tx> get month {
    final n = DateTime.now();
    return txs.where((x) => x.date.year == n.year && x.date.month == n.month).toList();
  }

  int get balance => initial + total(txs, TxType.income) - total(txs, TxType.expense);

  void add(int amount, TxType type, String cat, String desc, DateTime date) {
    txs.add(Tx(++_id, amount, type, cat, desc, dayOf(date)));
    notifyListeners();
  }

  void remove(int id) {
    txs.removeWhere((x) => x.id == id);
    notifyListeners();
  }

  void setInitial(int v) {
    initial = v;
    notifyListeners();
  }

  void setBudget(int v) {
    budget = v;
    notifyListeners();
  }

  void toggleHide() {
    hide = !hide;
    notifyListeners();
  }

  void reset() {
    txs.clear();
    initial = 0;
    notifyListeners();
  }
}

final store = Store();

// ───────────────────────── App & shell ─────────────────────────
class FinTrackApp extends StatelessWidget {
  const FinTrackApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'FinTrack',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: C.primary).copyWith(primary: C.primary, surface: C.surface),
          scaffoldBackgroundColor: C.bg,
          fontFamily: 'Roboto',
        ),
        home: const Shell(),
      );
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;

  Widget _nav(int idx, IconData icon, String label) {
    final on = i == idx;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => i = idx),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: on ? C.primary : C.text2),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: on ? C.primary : C.text2, fontWeight: on ? FontWeight.w600 : FontWeight.w400)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: store,
          builder: (_, __) => IndexedStack(index: i, children: [
            HomePage(onSeeAll: () => setState(() => i = 1), onProfile: () => setState(() => i = 3)),
            const TxPage(),
            const StatsPage(),
            const SettingsPage(),
          ]),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Tambah pengeluaran',
        backgroundColor: C.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () => showAdd(context, TxType.expense),
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: BottomAppBar(
        color: C.surface,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        child: Row(children: [
          _nav(0, Icons.home_rounded, 'Beranda'),
          _nav(1, Icons.receipt_long_rounded, 'Transaksi'),
          const SizedBox(width: 72),
          _nav(2, Icons.bar_chart_rounded, 'Statistik'),
          _nav(3, Icons.settings_rounded, 'Pengaturan'),
        ]),
      ),
    );
  }
}

// ───────────────────────── Widget umum ─────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: C.border),
          boxShadow: const [BoxShadow(color: Color(0x0F202B28), blurRadius: 10, offset: Offset(0, 2))],
        ),
        child: child,
      );
}

class IconBox extends StatelessWidget {
  final IconData icon;
  final double size;
  const IconBox(this.icon, {super.key, this.size = 42});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: C.light, borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: C.primary, size: size * 0.5),
      );
}

class TxTile extends StatelessWidget {
  final Tx t;
  const TxTile(this.t, {super.key});
  @override
  Widget build(BuildContext context) {
    final e = t.type == TxType.expense;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        IconBox(iconFor(t.cat)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.desc.isEmpty ? t.cat : t.desc,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${t.cat} · ${shortDate(t.date)}', style: const TextStyle(fontSize: 12, color: C.text2)),
          ]),
        ),
        Text('${e ? '−' : '+'}${rp(t.amount)}',
            style: TextStyle(fontWeight: FontWeight.w700, color: e ? C.expense : C.income)),
      ]),
    );
  }
}

Widget chips<T>(List<(T, String)> items, T selected, void Function(T) onTap) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(it.$2),
                selected: selected == it.$1,
                showCheckmark: false,
                selectedColor: C.primary,
                backgroundColor: C.surface,
                side: const BorderSide(color: C.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                labelStyle: TextStyle(color: selected == it.$1 ? Colors.white : C.text, fontWeight: FontWeight.w500),
                onSelected: (_) => onTap(it.$1),
              ),
            ),
        ],
      ),
    );

const _title = TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: C.text);
const _h2 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.text);
const _mut = TextStyle(fontSize: 12, color: C.text2);

// ───────────────────────── Tambah transaksi (sheet) ─────────────────────────
void showAdd(BuildContext c, TxType t) => showModalBottomSheet(
      context: c,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: C.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => AddSheet(type: t),
    );

class AddSheet extends StatefulWidget {
  final TxType type;
  const AddSheet({super.key, required this.type});
  @override
  State<AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<AddSheet> {
  final amt = TextEditingController();
  final desc = TextEditingController();
  String? cat;
  String? error;
  DateTime date = dayOf(DateTime.now());
  bool get inc => widget.type == TxType.income;

  @override
  void dispose() {
    amt.dispose();
    desc.dispose();
    super.dispose();
  }

  Future<void> pickDate() async {
    final p = await showDatePicker(
        context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (p != null) setState(() => date = p);
  }

  void save() {
    final n = parseRp(amt.text);
    if (n <= 0) return setState(() => error = 'Masukkan nominal lebih dari Rp0');
    if (cat == null) return setState(() => error = 'Pilih kategori terlebih dahulu');
    store.add(n, widget.type, cat!, desc.text.trim(), date);
    final m = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    m.showSnackBar(SnackBar(
        content: Text(inc ? 'Pemasukan tersimpan' : 'Pengeluaran tersimpan'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) {
    final cats = inc ? incomeCats : expenseCats;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: Text(inc ? 'Tambah Pemasukan' : 'Tambah Pengeluaran', style: _h2.copyWith(fontSize: 18))),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), tooltip: 'Tutup'),
          ]),
          TextField(
            controller: amt,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [RupiahFormatter()],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: C.text),
            decoration: const InputDecoration(
              prefixText: 'Rp',
              prefixStyle: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: C.text2),
              hintText: '0',
              hintStyle: TextStyle(color: C.text2),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.78,
            children: [
              for (final e in cats.entries)
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() {
                    cat = e.key;
                    error = null;
                  }),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                    decoration: BoxDecoration(
                      color: cat == e.key ? C.light : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cat == e.key ? C.primary : Colors.transparent, width: 1.5),
                    ),
                    child: Column(children: [
                      IconBox(e.value, size: 40),
                      const SizedBox(height: 4),
                      Text(e.key,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, color: C.text)),
                    ]),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (inc)
            OutlinedButton.icon(
                onPressed: pickDate, icon: const Icon(Icons.event), label: Text('Tanggal: ${shortDate(date)}'))
          else
            Row(children: [
              const Icon(Icons.event, size: 18, color: C.text2),
              const SizedBox(width: 8),
              Text('Hari ini · ${shortDate(date)}', style: _mut.copyWith(fontSize: 13)),
            ]),
          const SizedBox(height: 10),
          TextField(
            controller: desc,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: inc ? 'Catatan (opsional)' : 'Deskripsi (opsional)',
              filled: true,
              fillColor: C.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.border)),
              enabledBorder:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.border)),
            ),
          ),
          SizedBox(
              height: 28,
              child: Center(
                  child: Text(error ?? '', style: const TextStyle(color: C.expense, fontSize: 12)))),
          FilledButton(
            onPressed: save,
            style: FilledButton.styleFrom(
                backgroundColor: C.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Text(inc ? 'Simpan Pemasukan' : 'Simpan Pengeluaran',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

// ───────────────────────── Beranda ─────────────────────────
class HomePage extends StatelessWidget {
  final VoidCallback onSeeAll, onProfile;
  const HomePage({super.key, required this.onSeeAll, required this.onProfile});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final m = store.month;
    final inc = total(m, TxType.income), ex = total(m, TxType.expense);
    int dayTotal(DateTime d) =>
        store.txs.where((x) => x.type == TxType.expense && sameDay(x.date, d)).fold(0, (s, x) => s + x.amount);
    final todayCount = store.txs.where((x) => x.type == TxType.expense && sameDay(x.date, now)).length;
    final tt = dayTotal(now), yt = dayTotal(now.subtract(const Duration(days: 1)));
    final pct = store.budget > 0 ? (ex * 100 / store.budget).round() : 0;
    final col = pct >= 100 ? C.expense : (pct >= 80 ? C.warn : C.primary);
    final rec = ([...store.txs]..sort(byRecent)).take(5).toList();
    String cmp = '';
    if (yt > 0) cmp = tt >= yt ? '${rp(tt - yt)} lebih banyak dari kemarin' : '${rp(yt - tt)} lebih hemat dari kemarin';

    return ListView(padding: const EdgeInsets.fromLTRB(18, 20, 18, 100), children: [
      Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(fullDate(now), style: _mut.copyWith(fontSize: 13)),
            Text(greeting(), style: _title),
          ]),
        ),
        IconButton.filledTonal(
            onPressed: onProfile,
            icon: const Icon(Icons.person_outline, color: C.primary),
            style: IconButton.styleFrom(backgroundColor: C.light),
            tooltip: 'Pengaturan'),
      ]),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: C.primary, borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Saldo Saat Ini', style: TextStyle(color: Colors.white70)),
            IconButton(
                onPressed: store.toggleHide,
                tooltip: 'Tampilkan atau sembunyikan saldo',
                icon: Icon(store.hide ? Icons.visibility_off : Icons.visibility, color: Colors.white70, size: 20)),
          ]),
          Text(store.hide ? 'Rp••••••' : rp(store.balance),
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _Mini('Pemasukan Bulan Ini', rp(inc), C.income)),
        const SizedBox(width: 12),
        Expanded(child: _Mini('Pengeluaran Bulan Ini', rp(ex), C.expense)),
      ]),
      const SizedBox(height: 16),
      AppCard(
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Pengeluaran Hari Ini', style: _mut),
              Text(rp(tt), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$todayCount transaksi', style: _mut),
            if (cmp.isNotEmpty) Text(cmp, style: _mut),
          ]),
        ]),
      ),
      const SizedBox(height: 16),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Anggaran Bulanan', style: _h2),
            Text('$pct%', style: TextStyle(fontWeight: FontWeight.w700, color: col)),
          ]),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: store.budget > 0 ? (ex / store.budget).clamp(0.0, 1.0) : 0,
            minHeight: 8,
            color: col,
            backgroundColor: C.light,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Terpakai ${rp(ex)}', style: _mut),
            Text('Sisa ${rp(store.budget - ex)}', style: _mut),
          ]),
          if (pct >= 80)
            const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Anggaran hampir habis', style: TextStyle(color: C.warn, fontSize: 12))),
        ]),
      ),
      const SizedBox(height: 22),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Transaksi Terbaru', style: _h2),
        TextButton(onPressed: onSeeAll, child: const Text('Lihat Semua')),
      ]),
      AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: rec.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Belum ada transaksi. Tekan + untuk mencatat pengeluaran pertama.', textAlign: TextAlign.center, style: _mut)))
            : Column(children: [for (final t in rec) TxTile(t)]),
      ),
    ]);
  }
}

class _Mini extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Mini(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: _mut),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color)),
        ]),
      );
}

// ───────────────────────── Transaksi ─────────────────────────
class TxPage extends StatefulWidget {
  const TxPage({super.key});
  @override
  State<TxPage> createState() => _TxPageState();
}

class _TxPageState extends State<TxPage> {
  String q = '';
  TxType? type;
  String range = 'Semua';
  DateTimeRange? custom;

  bool inRange(DateTime d) {
    final n = dayOf(DateTime.now());
    switch (range) {
      case 'Hari Ini':
        return sameDay(d, n);
      case 'Minggu Ini':
        return !d.isBefore(n.subtract(Duration(days: n.weekday - 1)));
      case 'Bulan Ini':
        return d.year == n.year && d.month == n.month;
      case 'Pilih Tanggal':
        return custom == null || (!d.isBefore(custom!.start) && !d.isAfter(custom!.end));
      default:
        return true;
    }
  }

  Future<void> setRange(String r) async {
    if (r == 'Pilih Tanggal') {
      final p = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now().add(const Duration(days: 365)));
      if (p == null) return;
      custom = p;
    }
    setState(() => range = r);
  }

  @override
  Widget build(BuildContext context) {
    final list = store.txs
        .where((x) => (type == null || x.type == type) && inRange(x.date) && '${x.desc} ${x.cat}'.toLowerCase().contains(q.toLowerCase()))
        .toList()
      ..sort(byRecent);
    final groups = <DateTime, List<Tx>>{};
    for (final t in list) {
      groups.putIfAbsent(t.date, () => []).add(t);
    }
    return ListView(padding: const EdgeInsets.fromLTRB(18, 20, 18, 100), children: [
      const Text('Transaksi', style: _title),
      const SizedBox(height: 14),
      TextField(
        onChanged: (v) => setState(() => q = v),
        decoration: InputDecoration(
          hintText: 'Cari transaksi',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: C.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.border)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.border)),
        ),
      ),
      const SizedBox(height: 12),
      chips<TxType?>([(null, 'Semua'), (TxType.expense, 'Pengeluaran'), (TxType.income, 'Pemasukan')], type, (v) => setState(() => type = v)),
      const SizedBox(height: 8),
      chips<String>([for (final r in ['Semua', 'Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Pilih Tanggal']) (r, r)], range, setRange),
      if (groups.isEmpty)
        const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('Tidak ada transaksi yang cocok.', style: _mut))),
      for (final e in groups.entries) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 18, 0, 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(sameDay(e.key, DateTime.now()) ? 'Hari Ini' : shortDate(e.key), style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${rp(total(e.value, TxType.expense))} keluar', style: _mut),
          ]),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(children: [
            for (final t in e.value)
              Dismissible(
                key: ValueKey(t.id),
                direction: DismissDirection.endToStart,
                background: Container(
                    alignment: Alignment.centerRight,
                    color: C.expense.withOpacity(0.15),
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete_outline, color: C.expense)),
                onDismissed: (_) {
                  store.remove(t.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaksi dihapus'), behavior: SnackBarBehavior.floating));
                },
                child: TxTile(t),
              ),
          ]),
        ),
      ],
    ]);
  }
}

// ───────────────────────── Statistik ─────────────────────────
class DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  DonutPainter(this.values, this.colors);
  @override
  void paint(Canvas canvas, Size size) {
    final sum = values.fold<double>(0, (a, b) => a + b);
    if (sum == 0) return;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - 9);
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / sum * 2 * math.pi;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..color = colors[i % colors.length];
      canvas.drawArc(rect, start, values.length > 1 ? sweep - 0.03 : sweep, false, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutPainter old) => true;
}

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});
  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  String p = 'Bulanan';
  static const cols = [C.primary, C.warn, C.expense, Color(0xFF5B9BD5), Color(0xFF8E7CC3), Color(0xFFA3B8B0)];

  bool inPeriod(DateTime d) {
    final n = dayOf(DateTime.now());
    switch (p) {
      case 'Harian':
        return sameDay(d, n);
      case 'Mingguan':
        return !d.isBefore(n.subtract(const Duration(days: 6))) && !d.isAfter(n);
      case 'Bulanan':
        return d.year == n.year && d.month == n.month;
      default:
        return d.year == n.year;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = store.txs.where((x) => inPeriod(x.date)).toList();
    final ex = total(l, TxType.expense), inc = total(l, TxType.income);
    final by = <String, int>{};
    for (final t in l.where((x) => x.type == TxType.expense)) {
      by[t.cat] = (by[t.cat] ?? 0) + t.amount;
    }
    final ar = by.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final n = dayOf(DateTime.now());
    final week = [
      for (var i = 6; i >= 0; i--)
        (
          n.subtract(Duration(days: i)),
          store.txs.where((x) => x.type == TxType.expense && sameDay(x.date, n.subtract(Duration(days: i)))).fold<int>(0, (s, x) => s + x.amount)
        )
    ];
    final mx = week.fold<int>(1, (m, e) => math.max(m, e.$2));

    return ListView(padding: const EdgeInsets.fromLTRB(18, 20, 18, 100), children: [
      const Text('Statistik', style: _title),
      const SizedBox(height: 12),
      chips<String>([for (final s in ['Harian', 'Mingguan', 'Bulanan', 'Tahunan']) (s, s)], p, (v) => setState(() => p = v)),
      const SizedBox(height: 12),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Total Pengeluaran', style: _mut),
          Text(rp(ex), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: C.expense)),
        ]),
      ),
      const SizedBox(height: 16),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Per Kategori', style: _h2),
          const SizedBox(height: 12),
          if (ar.isEmpty)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Belum ada pengeluaran pada periode ini.', style: _mut)))
          else
            Row(children: [
              SizedBox(width: 130, height: 130, child: CustomPaint(painter: DonutPainter([for (final e in ar) e.value.toDouble()], cols))),
              const SizedBox(width: 16),
              Expanded(
                child: Column(children: [
                  for (var i = 0; i < ar.length && i < 5; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: cols[i % cols.length], borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 8),
                        Expanded(child: Text(ar[i].key, style: const TextStyle(fontSize: 12))),
                        Text('${(ar[i].value * 100 / ex).round()}%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ]),
                    ),
                ]),
              ),
            ]),
        ]),
      ),
      const SizedBox(height: 16),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tren 7 Hari', style: _h2),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (final w in week)
                Expanded(
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      height: math.max(3, w.$2 / mx * 85),
                      decoration: BoxDecoration(color: C.primary, borderRadius: BorderRadius.circular(6)),
                    ),
                    const SizedBox(height: 4),
                    Text('${w.$1.day}', style: _mut.copyWith(fontSize: 10)),
                  ]),
                ),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Terbesar', style: _mut),
              const SizedBox(height: 4),
              Text(ar.isEmpty ? '—' : ar.first.key, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(ar.isEmpty ? '' : rp(ar.first.value), style: _mut),
            ]),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Pemasukan vs Pengeluaran', style: _mut),
              const SizedBox(height: 4),
              Text('+${rp(inc)}', style: const TextStyle(fontWeight: FontWeight.w700, color: C.income)),
              Text('−${rp(ex)}', style: const TextStyle(fontWeight: FontWeight.w700, color: C.expense)),
            ]),
          ),
        ),
      ]),
    ]);
  }
}

// ───────────────────────── Pengaturan ─────────────────────────
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void soon(BuildContext c) => ScaffoldMessenger.of(c)
      .showSnackBar(const SnackBar(content: Text('Tersedia di fase berikutnya'), behavior: SnackBarBehavior.floating));

  Future<void> askNumber(BuildContext c, String title, int cur, void Function(int) onSave) {
    final ctl = TextEditingController(text: cur == 0 ? '' : rp(cur).substring(2));
    return showDialog(
      context: c,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [RupiahFormatter()],
          decoration: const InputDecoration(prefixText: 'Rp'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Batal')),
          FilledButton(
              onPressed: () {
                onSave(parseRp(ctl.text));
                Navigator.pop(d);
              },
              child: const Text('Simpan')),
        ],
      ),
    );
  }

  void history(BuildContext c) => showModalBottomSheet(
        context: c,
        isScrollControlled: true,
        backgroundColor: C.bg,
        builder: (_) => ListenableBuilder(
          listenable: store,
          builder: (ctx, __) {
            final l = store.txs.where((x) => x.type == TxType.income).toList()..sort(byRecent);
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Riwayat Pemasukan', style: _h2),
                const SizedBox(height: 12),
                if (l.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Belum ada pemasukan.', style: _mut))),
                Flexible(
                  child: ListView(shrinkWrap: true, children: [
                    for (final t in l)
                      Row(children: [
                        Expanded(child: TxTile(t)),
                        IconButton(onPressed: () => store.remove(t.id), icon: const Icon(Icons.delete_outline, color: C.text2), tooltip: 'Hapus'),
                      ]),
                  ]),
                ),
              ]),
            );
          },
        ),
      );

  Future<void> confirmReset(BuildContext c) async {
    final ok = await showDialog<bool>(
      context: c,
      builder: (d) => AlertDialog(
        title: const Text('Reset data?'),
        content: const Text('Semua transaksi dan saldo awal akan dihapus. Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Batal')),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: C.expense),
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Hapus Semua')),
        ],
      ),
    );
    if (ok == true) store.reset();
  }

  Widget tile(IconData i, String t, {String? trailing, Color? color, required VoidCallback onTap}) => ListTile(
        leading: Icon(i, color: color ?? C.primary),
        title: Text(t, style: TextStyle(color: color ?? C.text, fontWeight: FontWeight.w500)),
        trailing: trailing == null ? const Icon(Icons.chevron_right, color: C.text2) : Text(trailing, style: const TextStyle(fontWeight: FontWeight.w700)),
        onTap: onTap,
      );

  Widget section(String t) => Padding(padding: const EdgeInsets.fromLTRB(4, 22, 0, 6), child: Text(t, style: _mut));

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(18, 20, 18, 100), children: [
      const Text('Pengaturan', style: _title),
      section('Pemasukan'),
      AppCard(padding: EdgeInsets.zero, child: Column(children: [
        tile(Icons.add_circle_outline, 'Tambah Pemasukan', onTap: () => showAdd(context, TxType.income)),
        tile(Icons.history, 'Riwayat Pemasukan', onTap: () => history(context)),
      ])),
      section('Keuangan'),
      AppCard(padding: EdgeInsets.zero, child: Column(children: [
        tile(Icons.account_balance_wallet_outlined, 'Saldo Awal', trailing: rp(store.initial), onTap: () => askNumber(context, 'Saldo Awal', store.initial, store.setInitial)),
        tile(Icons.flag_outlined, 'Anggaran Bulanan', trailing: rp(store.budget), onTap: () => askNumber(context, 'Anggaran Bulanan', store.budget, store.setBudget)),
        tile(Icons.category_outlined, 'Kelola Kategori', onTap: () => soon(context)),
      ])),
      section('Data'),
      AppCard(padding: EdgeInsets.zero, child: Column(children: [
        tile(Icons.file_download_outlined, 'Ekspor CSV', onTap: () => soon(context)),
        tile(Icons.backup_outlined, 'Cadangkan & Pulihkan Database', onTap: () => soon(context)),
        tile(Icons.delete_forever_outlined, 'Reset Data Aplikasi', color: C.expense, onTap: () => confirmReset(context)),
      ])),
      section('Tentang'),
      const AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('FinTrack', style: TextStyle(fontWeight: FontWeight.w700)),
          Text('Versi 1.0.0 · Catat pengeluaran harian dengan cepat, tanpa akun, sepenuhnya offline.', style: _mut),
        ]),
      ),
    ]);
  }
}
