import 'package:flutter/material.dart';

class Biblioteca extends StatefulWidget {
  const Biblioteca({super.key});

  @override
  State<Biblioteca> createState() => _BibliotecaState();
}

class _BibliotecaState extends State<Biblioteca> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Biblioteca Central'),
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Catalogo Academico',
              style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 6, 
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.book),
                  title: Text('Libro ${index + 1}'),
                  subtitle: Text('Autor ${index + 1}'),
                  onTap: () {
                    
                  },
                );
              },
            ),
          ),
        ],
        
      ),
    );
  }
}

