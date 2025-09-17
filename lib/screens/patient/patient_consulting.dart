import 'package:flutter/material.dart';
import '../../models/patient_model.dart';

class PatientConsultingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consult a Practitioner',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          SizedBox(height: 16),
          
          // Search Box
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search practitioners',
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          SizedBox(height: 24),
          
          // Filter Chips
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: Text('All'),
                selected: true,
                onSelected: (selected) {},
                backgroundColor: Colors.grey.shade200,
                selectedColor: Colors.green.shade100,
                checkmarkColor: Colors.green.shade700,
              ),
              FilterChip(
                label: Text('Vamana'),
                selected: false,
                onSelected: (selected) {},
                backgroundColor: Colors.grey.shade200,
                selectedColor: Colors.green.shade100,
                checkmarkColor: Colors.green.shade700,
              ),
              FilterChip(
                label: Text('Virechana'),
                selected: false,
                onSelected: (selected) {},
                backgroundColor: Colors.grey.shade200,
                selectedColor: Colors.green.shade100,
                checkmarkColor: Colors.green.shade700,
              ),
              FilterChip(
                label: Text('Basti'),
                selected: false,
                onSelected: (selected) {},
                backgroundColor: Colors.grey.shade200,
                selectedColor: Colors.green.shade100,
                checkmarkColor: Colors.green.shade700,
              ),
              FilterChip(
                label: Text('Nasya'),
                selected: false,
                onSelected: (selected) {},
                backgroundColor: Colors.grey.shade200,
                selectedColor: Colors.green.shade100,
                checkmarkColor: Colors.green.shade700,
              ),
            ],
          ),
          SizedBox(height: 24),
          
          // Practitioner List
          Text(
            'Available Practitioners',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          SizedBox(height: 16),
          
          // Empty State
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 40),
                Icon(
                  Icons.medical_services_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                SizedBox(height: 16),
                Text(
                  'No practitioners available',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Practitioners will be available soon',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Request a Practitioner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
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