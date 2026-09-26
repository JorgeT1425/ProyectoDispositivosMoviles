import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MenuInferior extends StatelessWidget {
  final int indiceActual;

  const MenuInferior({
    super.key,
    required this.indiceActual,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: indiceActual,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF4252B5),
      unselectedItemColor: Colors.grey,
      backgroundColor: Colors.white,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      onTap: (index) {
        if (index == 0) {
          context.go('/home');
        }
        if (index == 1) {
          context.go('/semestres');
        }
        if (index == 2) {
          context.go('/materias');
        }
        if (index == 3) {
          context.go('/progreso');
        }
        if (index == 4) {
          context.go('/perfil');
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view_outlined),
          activeIcon: Icon(Icons.grid_view_rounded),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today_outlined),
          activeIcon: Icon(Icons.calendar_today),
          label: 'Semestres',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined),
          activeIcon: Icon(Icons.menu_book),
          label: 'Materias',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.show_chart_outlined),
          activeIcon: Icon(Icons.show_chart),
          label: 'Progreso',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}