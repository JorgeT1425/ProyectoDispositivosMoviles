

import 'package:flutter_application_2/Config/presentation/screen/home/home.dart';
import 'package:flutter_application_2/Config/presentation/screen/login/login.dart';
import 'package:flutter_application_2/Config/presentation/screen/materias/materias.dart';
import 'package:flutter_application_2/Config/presentation/screen/perfil/perfil.dart';
import 'package:flutter_application_2/Config/presentation/screen/progreso/progreso.dart';
import 'package:flutter_application_2/Config/presentation/screen/semestres/semestres.dart';
import 'package:go_router/go_router.dart' show GoRoute, GoRouter;

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [

    GoRoute(
      path: '/',
      name: Login.name,
      builder: (context, state) => const Login(),
    ),
    GoRoute(
      path: '/home',
      name: Home.name,
      builder: (context, state) => const Home(),
    ),
    GoRoute(
      path: '/materias',
      name: Materias.name,
      builder: (context, state) => const Materias(),
    ),
    GoRoute(
      path: '/semestres',
      name: Semestres.name,
      builder: (context, state) => const Semestres(),
    ),
    GoRoute(
      path: '/progreso',
      name: Progreso.name,
      builder: (context, state) => const Progreso(),
    ),
    GoRoute(
      path: '/perfil',
      name: Perfil.name,
      builder: (context, state) => const Perfil(),
    ),
  ],
);