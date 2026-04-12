import 'package:flutter/material.dart';

class CodingScreen extends StatelessWidget {
  const CodingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coding Progress'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDSASection(),
          _buildAIMLSection(),
          _buildFullStackSection(),
        ],
      ),
    );
  }

  Widget _buildDSASection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.data_object, color: Colors.blue),
                SizedBox(width: 10),
                Text('Data Structures & Algorithms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Daily Goal: 2 Problems', style: TextStyle(color: Colors.grey)),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Log Problem'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAIMLSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.memory, color: Colors.purple),
                SizedBox(width: 10),
                Text('AI / Machine Learning', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Learning Hours: 0 / 2', style: TextStyle(color: Colors.grey)),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Log Hours'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFullStackSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.layers, color: Colors.orange),
                SizedBox(width: 10),
                Text('Full Stack Development', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Projects Progress: 40%', style: TextStyle(color: Colors.grey)),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Update'),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
