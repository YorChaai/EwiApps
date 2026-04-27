import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class DeadlineManagerScreen extends StatefulWidget {
  const DeadlineManagerScreen({super.key});

  @override
  State<DeadlineManagerScreen> createState() => _DeadlineManagerScreenState();
}

class _DeadlineManagerScreenState extends State<DeadlineManagerScreen> {
  final ApiService _api = ApiService();
  bool _loading = true;
  Map<String, dynamic> _deadlineSettings = {};

  // Controllers untuk SETTLEMENT_SUBMISSION
  late List<TextEditingController> _submissionControllers;

  // Controllers untuk SETTLEMENT_APPROVAL
  late List<TextEditingController> _approvalControllers;

  @override
  void initState() {
    super.initState();
    _submissionControllers = [];
    _approvalControllers = [];
    _loadDeadlineSettings();
  }

  @override
  void dispose() {
    for (var c in _submissionControllers) {
      c.dispose();
    }
    for (var c in _approvalControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDeadlineSettings() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    _api.setToken(auth.token!);

    try {
      final res = await _api.getDeadlineSettings();
      if (mounted) {
        setState(() {
          _deadlineSettings = res;
          _initializeControllers();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _initializeControllers() {
    // Clear existing controllers
    for (var c in _submissionControllers) {
      c.dispose();
    }
    for (var c in _approvalControllers) {
      c.dispose();
    }
    _submissionControllers.clear();
    _approvalControllers.clear();

    // Initialize SETTLEMENT_SUBMISSION
    if (_deadlineSettings.containsKey('SETTLEMENT_SUBMISSION')) {
      final data = _deadlineSettings['SETTLEMENT_SUBMISSION'];
      final days = (data['days'] ?? []) as List;
      for (final day in days) {
        _submissionControllers.add(
          TextEditingController(text: day.toString()),
        );
      }
    }

    // Initialize SETTLEMENT_APPROVAL
    if (_deadlineSettings.containsKey('SETTLEMENT_APPROVAL')) {
      final data = _deadlineSettings['SETTLEMENT_APPROVAL'];
      final days = (data['days'] ?? []) as List;
      for (final day in days) {
        _approvalControllers.add(
          TextEditingController(text: day.toString()),
        );
      }
    }
  }

  String _getOrdinal(int index) {
    const ordinals = [
      'Pertama',
      'Kedua',
      'Ketiga',
      'Keempat',
      'Kelima',
      'Keenam',
      'Ketujuh',
      'Kedelapan',
      'Kesembilan',
      'Kesepuluh',
      'Kesebelas',
      'Kedua Belas',
      'Ketiga Belas',
      'Keempat Belas',
      'Kelima Belas',
      'Keenam Belas',
      'Ketujuh Belas',
      'Kedelapan Belas',
      'Kesembilan Belas',
      'Kedua Puluh',
    ];
    if (index >= 0 && index < ordinals.length) {
      return ordinals[index];
    }
    return 'Ke ${index + 1}';
  }

  Future<void> _saveSetting(
    String ruleKey,
    List<TextEditingController> controllers,
  ) async {
    // Filter empty inputs and convert to int
    final daysList = <int>[];

    for (final controller in controllers) {
      final text = controller.text.trim();
      if (text.isEmpty) continue; // Skip empty fields

      final parsed = int.tryParse(text);
      if (parsed == null || parsed <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua hari yang diisi harus berupa angka positif.'),
            backgroundColor: AppTheme.danger,
          ),
        );
        return;
      }
      daysList.add(parsed);
    }

    setState(() => _loading = true);
    try {
      final res = await _api.updateDeadlineSetting(ruleKey, daysList);
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Setting berhasil disimpan.'),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadDeadlineSettings();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  void _addDayField(List<TextEditingController> controllers) {
    if (controllers.length >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 20 deadline.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }
    setState(() {
      controllers.add(TextEditingController());
    });
  }

  void _removeDayField(List<TextEditingController> controllers, int index) {
    setState(() {
      controllers[index].dispose();
      controllers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Deadline Notifikasi'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info, color: AppTheme.primary),
                            SizedBox(width: 8),
                            Text(
                              'Pengaturan Deadline',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Atur berapa hari notifikasi akan muncul untuk setiap status dokumen. '
                          'Notifikasi akan dikirim setiap tengah malam (00:00). '
                          'Kosongkan input jika tidak ingin menggunakan slot deadline tersebut.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // SETTLEMENT_SUBMISSION Section
                  Text(
                    'Deadline Kasbon → Settlement',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Notifikasi untuk Staff jika Kasbon sudah disetujui namun belum membuat Settlement.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  _buildDeadlineSection(
                    _submissionControllers,
                    'Tentukan urutan deadline notifikasi:',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          _saveSetting('SETTLEMENT_SUBMISSION', _submissionControllers),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Simpan Setting Kasbon → Settlement',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // SETTLEMENT_APPROVAL Section
                  Text(
                    'Deadline Settlement → Approval',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Notifikasi untuk Manager jika Settlement sudah dikirim namun belum disetujui.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  _buildDeadlineSection(
                    _approvalControllers,
                    'Tentukan urutan deadline notifikasi:',
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          _saveSetting('SETTLEMENT_APPROVAL', _approvalControllers),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Simpan Setting Settlement → Approval',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildDeadlineSection(
    List<TextEditingController> controllers,
    String label,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...List.generate(
          controllers.length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controllers[index],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Deadline ${_getOrdinal(index)}',
                      hintText: 'Contoh: ${index * 5 + 2}',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.timer_outlined, size: 20),
                      suffixText: 'hari',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (controllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                    onPressed: () => _removeDayField(controllers, index),
                    tooltip: 'Hapus slot ini',
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        if (controllers.length < 20)
          OutlinedButton.icon(
            onPressed: () => _addDayField(controllers),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Tambah Slot Deadline'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }
}
