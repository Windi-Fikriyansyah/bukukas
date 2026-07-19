import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buku Kas'),
      ),
      body: const Center(
        child: Text('Daftar Transaksi akan tampil di sini'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to Add Transaction Screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
