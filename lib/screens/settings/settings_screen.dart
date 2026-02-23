import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../routes.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_nav.dart';
import '../vehicles/home_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  bool _savingName = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>>? get _userDoc {
    final u = _user;
    if (u == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(u.uid);
  }

  Future<void> _logout(BuildContext context) async {
    await _authService.logout();
    if (!context.mounted) return;

    // Volver a Login y limpiar el stack
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  Future<void> _editName(BuildContext context, {required String currentName}) async {
    final ctrl = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cambiar nombre'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Ej. Jose Manuel',
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => Navigator.of(ctx).pop(ctrl.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (newName == null) return;

    final clean = newName.trim();
    if (clean.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío')),
      );
      return;
    }

    setState(() => _savingName = true);
    try {
      await _authService.updateUserName(clean);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre actualizado')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final userDoc = _userDoc;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.12),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                children: [
                  if (user == null || userDoc == null)
                    _card(
                      child: const Text('No hay sesión iniciada.', style: TextStyle(fontSize: 13)),
                    )
                  else
                    StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: userDoc.snapshots(),
                      builder: (context, snap) {
                        final data = snap.data?.data();
                        final name = (data?['name'] as String?)?.trim();
                        final email = user.email ?? (data?['email'] as String?) ?? '';

                        return _card(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: const BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.person_outline, color: Colors.white, size: 28),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                (name == null || name.isEmpty) ? 'Sin nombre' : name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Editar nombre',
                                              onPressed: _savingName
                                                  ? null
                                                  : () => _editName(
                                                        context,
                                                        currentName: (name == null || name.isEmpty) ? '' : name,
                                                      ),
                                              icon: _savingName
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child: CircularProgressIndicator(strokeWidth: 2),
                                                    )
                                                  : const Icon(Icons.edit, size: 20),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'Conductor',
                                          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(color: Color(0xFFE5E7EB), height: 1),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.mail_outline, color: Color(0xFF6B7280)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      email.isEmpty ? '—' : email,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Row(
                                children: [
                                  Icon(Icons.lock_outline, color: Color(0xFF6B7280)),
                                  SizedBox(width: 10),
                                  Expanded(child: Text('Contraseña', style: TextStyle(fontSize: 13))),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 14),

                  _card(
                    title: 'CRÉDITOS',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF6B7280)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Aplicación creada por Jose Manuel Román Gómez.',
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14),
                        Divider(color: Color(0xFFE5E7EB), height: 1),
                        SizedBox(height: 14),
                        Text(
                          'Herramientas utilizadas:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text('• Flutter (UI multiplataforma)', style: TextStyle(fontSize: 13)),
                        SizedBox(height: 4),
                        Text('• Firebase (autenticación y base de datos)', style: TextStyle(fontSize: 13)),
                        SizedBox(height: 4),
                        Text('• Visual Studio Code (entorno de desarrollo)', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: user == null ? null : () => _logout(context),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        disabledBackgroundColor: Colors.orange,
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  const Text(
                    'FleetManager v1.0.0',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ),

          BottomNav(
            onHomeTap: () {
              Navigator.of(context).pushReplacement(_slideRoute(const HomeScreen()));
            },
            onSettingsTap: () {},
          ),
        ],
      ),
    );
  }

  static Widget _card({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

Route _slideRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final tween = Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}