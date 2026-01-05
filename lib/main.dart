import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LicenseStatus { trial, licensed, expired }

class LicenseManager {
  static const String _firstRunKey = 'app_first_run';
  static const String _licenseKey = 'app_license';
  static const int trialDays = 5;

  static Future<LicenseStatus> checkLicense() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_licenseKey) != null) return LicenseStatus.licensed;
    final firstRun = prefs.getString(_firstRunKey);
    if (firstRun == null) {
      await prefs.setString(_firstRunKey, DateTime.now().toIso8601String());
      return LicenseStatus.trial;
    }
    final startDate = DateTime.parse(firstRun);
    final daysUsed = DateTime.now().difference(startDate).inDays;
    return daysUsed < trialDays ? LicenseStatus.trial : LicenseStatus.expired;
  }

  static Future<int> getRemainingDays() async {
    final prefs = await SharedPreferences.getInstance();
    final firstRun = prefs.getString(_firstRunKey);
    if (firstRun == null) return trialDays;
    final startDate = DateTime.parse(firstRun);
    final daysUsed = DateTime.now().difference(startDate).inDays;
    return (trialDays - daysUsed).clamp(0, trialDays);
  }

  static Future<bool> activate(String key) async {
    final cleaned = key.trim().toUpperCase();
    if (cleaned.length == 19 && cleaned.contains('-')) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_licenseKey, cleaned);
      return true;
    }
    return false;
  }
}

class TrialBanner extends StatelessWidget {
  final int daysRemaining;
  const TrialBanner({super.key, required this.daysRemaining});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: daysRemaining <= 2 ? Colors.red : Colors.orange,
      child: Text(
        'Periodo de teste: ' + daysRemaining.toString() + ' dias restantes',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class LicenseExpiredScreen extends StatefulWidget {
  const LicenseExpiredScreen({super.key});
  @override
  State<LicenseExpiredScreen> createState() => _LicenseExpiredScreenState();
}

class _LicenseExpiredScreenState extends State<LicenseExpiredScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _activate() async {
    setState(() { _loading = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 500));
    final ok = await LicenseManager.activate(_ctrl.text);
    if (ok && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RestartApp()));
    } else if (mounted) {
      setState(() { _error = 'Chave invalida'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.red.shade800, Colors.red.shade600], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                const Text('Periodo de Teste Encerrado', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 32),
                TextField(controller: _ctrl, decoration: InputDecoration(labelText: 'Chave de Licenca', hintText: 'XXXX-XXXX-XXXX-XXXX', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), errorText: _error), textCapitalization: TextCapitalization.characters, maxLength: 19),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loading ? null : _activate, style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.green), child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Ativar', style: TextStyle(fontSize: 18, color: Colors.white)))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RestartApp extends StatelessWidget {
  const RestartApp({super.key});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([LicenseManager.checkLicense(), LicenseManager.getRemainingDays()]),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return MyApp(licenseStatus: snap.data![0] as LicenseStatus, remainingDays: snap.data![1] as int);
      },
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final status = await LicenseManager.checkLicense();
  final days = await LicenseManager.getRemainingDays();
  runApp(MyApp(licenseStatus: status, remainingDays: days));
}

class MyApp extends StatelessWidget {
  final LicenseStatus licenseStatus;
  final int remainingDays;
  const MyApp({super.key, required this.licenseStatus, required this.remainingDays});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), useMaterial3: true),
      home: licenseStatus == LicenseStatus.expired ? const LicenseExpiredScreen() : HomeScreen(licenseStatus: licenseStatus, remainingDays: remainingDays),
    );
  }
}

class MarmitaFit {
  final String nome;
  final String descricao;
  final double preco;
  final String categoria;
  final int calorias;

  MarmitaFit({
    required this.nome,
    required this.descricao,
    required this.preco,
    required this.categoria,
    required this.calorias,
  });
}

class HomeScreen extends StatefulWidget {
  final LicenseStatus licenseStatus;
  final int remainingDays;

  const HomeScreen({super.key, required this.licenseStatus, required this.remainingDays});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<MarmitaFit> marmitas = [
    MarmitaFit(nome: 'Frango Grelhado', descricao: 'Frango grelhado, arroz integral e salada', preco: 18.90, categoria: 'Proteína', calorias: 450),
    MarmitaFit(nome: 'Salmão Assado', descricao: 'Salmão com legumes e quinoa', preco: 25.90, categoria: 'Peixe', calorias: 380),
    MarmitaFit(nome: 'Carne Magra', descricao: 'Patinho grelhado com batata doce', preco: 22.90, categoria: 'Carne', calorias: 520),
    MarmitaFit(nome: 'Veggie Power', descricao: 'Hambúrguer vegetal com salada', preco: 16.90, categoria: 'Vegano', calorias: 320),
    MarmitaFit(nome: 'Peixe Branco', descricao: 'Tilápia com arroz e brócolis', preco: 19.90, categoria: 'Peixe', calorias: 400),
    MarmitaFit(nome: 'Peru Fit', descricao: 'Peru desfiado com sweet potato', preco: 21.90, categoria: 'Proteína', calorias: 480),
  ];

  final List<Map<String, dynamic>> carrinho = [];
  String? categoriaFiltro;

  List<MarmitaFit> get marmitasFiltradas {
    if (categoriaFiltro == null) return marmitas;
    return marmitas.where((m) => m.categoria == categoriaFiltro).toList();
  }

  void adicionarCarrinho(MarmitaFit marmita) {
    setState(() {
      final index = carrinho.indexWhere((item) => item['marmita'].nome == marmita.nome);
      if (index >= 0) {
        carrinho[index]['quantidade']++;
      } else {
        carrinho.add({'marmita': marmita, 'quantidade': 1});
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${marmita.nome} adicionada ao carrinho')),
    );
  }

  double get totalCarrinho {
    return carrinho.fold(0.0, (total, item) => total + (item['marmita'].preco * item['quantidade']));
  }

  void verCarrinho() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Carrinho', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(
              child: carrinho.isEmpty
                  ? const Center(child: Text('Carrinho vazio'))
                  : ListView.builder(
                      itemCount: carrinho.length,
                      itemBuilder: (context, index) {
                        final item = carrinho[index];
                        final marmita = item['marmita'] as MarmitaFit;
                        return ListTile(
                          title: Text(marmita.nome),
                          subtitle: Text('R\$ ${marmita.preco.toStringAsFixed(2)}'),
                          trailing: Text('${item['quantidade']}x'),
                        );
                      },
                    ),
            ),
            if (carrinho.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'Total: R\$ ${totalCarrinho.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FitMarmitas'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.shopping_cart),
                if (carrinho.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: Text('${carrinho.length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  ),
              ],
            ),
            onPressed: verCarrinho,
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.licenseStatus == LicenseStatus.trial)
            TrialBanner(daysRemaining: widget.remainingDays),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                FilterChip(
                  label: const Text('Todos'),
                  selected: categoriaFiltro == null,
                  onSelected: (selected) => setState(() => categoriaFiltro = null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Proteína'),
                  selected: categoriaFiltro == 'Proteína',
                  onSelected: (selected) => setState(() => categoriaFiltro = selected ? 'Proteína' : null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Peixe'),
                  selected: categoriaFiltro == 'Peixe',
                  onSelected: (selected) => setState(() => categoriaFiltro = selected ? 'Peixe' : null),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Vegano'),
                  selected: categoriaFiltro == 'Vegano',
                  onSelected: (selected) => setState(() => categoriaFiltro = selected ? 'Vegano' : null),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: marmitasFiltradas.length,
              itemBuilder: (context, index) {
                final marmita = marmitasFiltradas[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(marmita.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
                              child: Text(marmita.categoria, style: TextStyle(fontSize: 12, color: Colors.green.shade800)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(marmita.descricao, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.local_fire_department, color: Colors.orange.shade600, size: 16),
                            Text(' ${marmita.calorias} cal', style: const TextStyle(fontSize: 12)),
                            const Spacer(),
                            Text('R\$ ${marmita.preco.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => adicionarCarrinho(marmita),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('Adicionar', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}