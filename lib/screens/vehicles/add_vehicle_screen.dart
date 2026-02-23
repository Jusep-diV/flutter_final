import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/vehicle_service.dart';

class AddVehicleScreen extends StatefulWidget {

  final String? vehicleId;

  /// Datos iniciales (cuando editas)
  final Map<String, dynamic>? initialData;

  const AddVehicleScreen({
    super.key,
    this.vehicleId,
    this.initialData,
  });

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _plateCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _fuelCtrl = TextEditingController();
  final _lastRevisionCtrl = TextEditingController();
  final _nextItvCtrl = TextEditingController();

  final _vehicleService = VehicleService();

  bool _saving = false;

  bool get _isEdit => widget.vehicleId != null;

  @override
  void initState() {
    super.initState();

    final data = widget.initialData;
    if (data != null) {
      _plateCtrl.text = (data['plate'] ?? '').toString();
      _brandCtrl.text = (data['brand'] ?? '').toString();
      _modelCtrl.text = (data['model'] ?? '').toString();
      _fuelCtrl.text = (data['fuelType'] ?? '').toString();

      _lastRevisionCtrl.text = _formatTimestampToDdMmYyyy(data['lastRevision']);
      _nextItvCtrl.text = _formatTimestampToDdMmYyyy(data['nextItv']);
    }
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _fuelCtrl.dispose();
    _lastRevisionCtrl.dispose();
    _nextItvCtrl.dispose();
    super.dispose();
  }

  String _formatTimestampToDdMmYyyy(dynamic value) {
    if (value == null) return '';
    if (value is Timestamp) {
      final d = value.toDate();
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      final yyyy = d.year.toString();
      return '$dd/$mm/$yyyy';
    }
    return '';
  }

  DateTime? _parseDdMmYyyy(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;

    final parts = t.split('/');
    if (parts.length != 3) return null;

    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;

    return DateTime(y, m, d);
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _parseDdMmYyyy(ctrl.text) ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    final dd = picked.day.toString().padLeft(2, '0');
    final mm = picked.month.toString().padLeft(2, '0');
    final yyyy = picked.year.toString();
    ctrl.text = '$dd/$mm/$yyyy';
  }

  InputDecoration _dec({
    required String hint,
    IconData? icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF6B7280)) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.orange),
      ),
    );
  }

  Future<void> _save() async {
    if (_plateCtrl.text.trim().isEmpty ||
        _brandCtrl.text.trim().isEmpty ||
        _modelCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa Matrícula, Marca y Modelo')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final lastRev = _parseDdMmYyyy(_lastRevisionCtrl.text);
      final nextItv = _parseDdMmYyyy(_nextItvCtrl.text);

      if (_isEdit) {
        await _vehicleService.updateVehicle(
          vehicleId: widget.vehicleId!,
          plate: _plateCtrl.text,
          brand: _brandCtrl.text,
          model: _modelCtrl.text,
          fuelType: _fuelCtrl.text,
          lastRevision: lastRev,
          nextItv: nextItv,
        );
      } else {
        await _vehicleService.addVehicle(
          plate: _plateCtrl.text,
          brand: _brandCtrl.text,
          model: _modelCtrl.text,
          fuelType: _fuelCtrl.text,
          lastRevision: lastRev,
          nextItv: nextItv,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Cambios guardados' : 'Vehículo guardado')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteVehicle() async {
    if (!_isEdit) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar vehículo'),
          content: const Text('¿Seguro que quieres eliminar este vehículo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    setState(() => _saving = true);

    try {
      await _vehicleService.deleteVehicle(vehicleId: widget.vehicleId!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehículo eliminado')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        title: Text(
          _isEdit ? 'Editar Vehículo' : 'Añadir Vehículo',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Foto del Vehículo',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    height: 170,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.photo_camera_outlined,
                            size: 42, color: Color(0xFF9CA3AF)),
                        SizedBox(height: 10),
                        Text(
                          'Haz clic para subir una foto',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'PNG, JPG o JPEG',
                          style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1DF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD6A8)),
                    ),
                    child: const Text(
                      'Información Básica',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text('Matrícula *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _plateCtrl,
                    decoration: _dec(hint: '1234 ABC'),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Marca *',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _brandCtrl,
                              decoration: _dec(hint: 'Mercedes'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Modelo *',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _modelCtrl,
                              decoration: _dec(hint: 'Vito'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  const Text('Tipo de Combustible',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _fuelCtrl,
                    decoration: _dec(
                      hint: 'Gasolina / Diésel / Eléctrico...',
                      icon: Icons.local_gas_station_outlined,
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text('Fecha última revisión',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _lastRevisionCtrl,
                    readOnly: true,
                    onTap: () => _pickDate(_lastRevisionCtrl),
                    decoration: _dec(
                      hint: 'DD/MM/AAAA',
                      icon: Icons.event_outlined,
                      suffix: const Icon(Icons.calendar_month_outlined,
                          color: Color(0xFF6B7280)),
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text('Próxima ITV',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nextItvCtrl,
                    readOnly: true,
                    onTap: () => _pickDate(_nextItvCtrl),
                    decoration: _dec(
                      hint: 'DD/MM/AAAA',
                      icon: Icons.event_available_outlined,
                      suffix: const Icon(Icons.calendar_month_outlined,
                          color: Color(0xFF6B7280)),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom actions con eliminar en edición
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 14,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_isEdit) ...[
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _deleteVehicle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Eliminar',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],

                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 6,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEdit ? 'Guardar cambios' : 'Guardar Vehículo',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
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