import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_vehicle_screen.dart';
import '../../routes.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controla el texto del buscador
  final _searchCtrl = TextEditingController();
  // Texto actual para filtrar resultados
  String _query = '';

  Stream<QuerySnapshot<Map<String, dynamic>>> _vehiclesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty(); // Si no hay sesión, no escuchamos nada

    // Stream en tiempo real de los vehículos del usuario
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('vehicles')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _searchCtrl.dispose(); // Liberar el controller
    super.dispose();
  }

  bool _matchesQuery(Map<String, dynamic> data) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true; // Sin búsqueda => mostrar todo

    // Normalizamos a minúsculas para comparar sin importar mayúsculas
    final brand = (data['brand'] ?? '').toString().toLowerCase();
    final model = (data['model'] ?? '').toString().toLowerCase();

    // Coincide si aparece en marca o modelo
    return brand.contains(q) || model.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          //TOP BAR
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  // Avatar del usuario (por ahora imagen local)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD1D5DB),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/user.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Buscador (filtra por marca o modelo)
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Color(0xFF6B7280)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              // Actualiza el filtro en cada cambio
                              onChanged: (v) => setState(() => _query = v),
                              decoration: const InputDecoration(
                                hintText: 'Buscar marca o modelo',
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          // Botón para limpiar búsqueda
                          if (_query.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                              child: const Icon(Icons.close, size: 18, color: Color(0xFF6B7280)),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Botón + para ir a pantalla de añadir vehículo
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.addVehicle);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.add, color: Colors.white, size: 26),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _vehiclesStream(),
              builder: (context, snapshot) {
                // Si no hay sesión iniciada
                if (FirebaseAuth.instance.currentUser == null) {
                  return const Center(child: Text('Inicia sesión para ver tus vehículos'));
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error cargando vehículos: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                // Estado vacío (sin vehículos)
                if (docs.isEmpty) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/coche.png',
                        width: 90,
                        height: 90,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Añade tu primer vehiculo',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  );
                }

                // Filtrado local por búsqueda
                final filtered = docs.where((d) => _matchesQuery(d.data())).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay resultados para "${_query.trim()}"',
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }

                // Lista de tarjetas de vehículos
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final doc = filtered[index];
                    final data = doc.data();

                    // Campos principales
                    final brand = (data['brand'] ?? '').toString();
                    final model = (data['model'] ?? '').toString();
                    final plate = (data['plate'] ?? '').toString();

                    final title = '${brand.trim()} ${model.trim()}'.trim();

                    return VehicleCard(
                      title: title.isEmpty ? 'Vehículo' : title,
                      plate: plate.isEmpty ? 'Sin matrícula' : plate,
                      onView: () {
                        // Abrir pantalla de ver/editar pasando id y datos actuales
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddVehicleScreen(
                              vehicleId: doc.id,
                              initialData: data,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // navegador inferior
          Container(
            height: 70,
            width: double.infinity,
            decoration: const BoxDecoration(color: Colors.orange),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {}, // Ya estás en Home
                    child: Center(
                      child: Image.asset(
                        'assets/images/home.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      // Ir a Settings 
                      Navigator.of(context).pushReplacement(
                        slideRoute(const SettingsScreen(), fromRight: true),
                      );
                    },
                    child: Center(
                      child: Image.asset(
                        'assets/images/settings.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
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

// CARD

class VehicleCard extends StatelessWidget {
  final String title;
  final String plate;
  final VoidCallback onView;

  const VehicleCard({
    super.key,
    required this.title,
    required this.plate,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5E5),
        border: Border.all(color: Colors.black.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
   
          Container(
            width: 125,
            height: double.infinity,
            decoration: const BoxDecoration(color: Colors.white),
            child: Image.asset('assets/images/coche.png', fit: BoxFit.cover),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Container(height: 1, color: Colors.black.withOpacity(0.4)),
                  const Spacer(),
                  Row(
                    children: [
                      // Matrícula
                      Expanded(
                        child: Container(
                          height: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.black.withOpacity(0.25)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.confirmation_number_outlined,
                                size: 14,
                                color: Color(0xFF6B7280),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  plate,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Botón ver
                      SizedBox(
                        width: 72,
                        height: 26,
                        child: ElevatedButton(
                          onPressed: onView,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          child: const Text(
                            'ver',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
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

// Slide route

Route slideRoute(Widget page, {required bool fromRight}) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final begin = Offset(fromRight ? 1 : -1, 0);
      final tween = Tween<Offset>(begin: begin, end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));

      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}