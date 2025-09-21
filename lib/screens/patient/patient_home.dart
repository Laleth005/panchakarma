import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({Key? key}) : super(key: key);

  @override
  _PatientHomeScreenState createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  final List<Map<String, dynamic>> _panchakarmaInfo = [
    {
      'title': 'Vamana',
      'description':
          'A therapeutic emesis that removes excess Kapha dosha from the body.',
      'image': 'assets/images/vamana.jpg',
      'benefits': [
        'Helps in respiratory disorders',
        'Alleviates skin disorders',
        'Reduces heaviness in the body',
        'Clears congestion',
      ],
    },
    {
      'title': 'Virechana',
      'description':
          'A therapeutic purgation that eliminates excess Pitta dosha from the body.',
      'image': 'assets/images/virechana.jpg',
      'benefits': [
        'Helps in digestive disorders',
        'Purifies blood',
        'Reduces skin inflammations',
        'Detoxifies the liver',
      ],
    },
    {
      'title': 'Basti',
      'description':
          'A therapeutic enema that balances Vata dosha and supports overall health.',
      'image': 'assets/images/basti.jpg',
      'benefits': [
        'Relieves joint pain',
        'Improves bowel movements',
        'Strengthens the tissues',
        'Balances nervous system',
      ],
    },
    {
      'title': 'Nasya',
      'description':
          'Administration of herbal oils through the nasal passage to treat disorders of the head.',
      'image': 'assets/images/nasya.jpg',
      'benefits': [
        'Clears sinus congestion',
        'Improves vision and hearing',
        'Enhances memory',
        'Reduces headaches',
      ],
    },
    {
      'title': 'Raktamokshana',
      'description':
          'A therapeutic bloodletting that purifies the blood and removes toxins.',
      'image': 'assets/images/raktamokshana.jpg',
      'benefits': [
        'Helps in skin diseases',
        'Reduces inflammation',
        'Improves circulation',
        'Detoxifies blood',
      ],
    },
  ];

  final List<Map<String, dynamic>> _recentUpdates = [
    {
      'title': 'New Practitioner Added',
      'description':
          'Dr. Sharma, a specialist in Panchakarma, has joined our team.',
      'date': '2 days ago',
      'icon': Icons.person_add,
    },
    {
      'title': 'Ayurveda Workshop',
      'description':
          'Join our weekend workshop on understanding your body constitution.',
      'date': '1 week ago',
      'icon': Icons.event,
    },
    {
      'title': 'App Update',
      'description': 'AyurSutra v1.2.0 is now available with new features.',
      'date': '2 weeks ago',
      'icon': Icons.system_update,
    },
  ];

  int _currentCarouselIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to AyurSutra',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your journey to holistic wellness begins here',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Quick Actions
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
          ),
          SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _buildQuickActionCard(
                  title: 'Book Appointment',
                  icon: Icons.calendar_today,
                  color: Colors.blue.shade700,
                  onTap: () {
                    // Navigate to appointment booking
                  },
                ),
                _buildQuickActionCard(
                  title: 'Find Practitioner',
                  icon: Icons.person_search,
                  color: Colors.purple.shade700,
                  onTap: () {
                    // Navigate to practitioner search
                  },
                ),
                _buildQuickActionCard(
                  title: 'View Reports',
                  icon: Icons.description,
                  color: Colors.orange.shade700,
                  onTap: () {
                    // Navigate to reports section
                  },
                ),
                _buildQuickActionCard(
                  title: 'Dosha Quiz',
                  icon: Icons.quiz,
                  color: Colors.green.shade700,
                  onTap: () {
                    // Navigate to dosha quiz
                  },
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Upcoming Appointment
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.green.shade100),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Upcoming Appointment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          color: Colors.green.shade700,
                          size: 18,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // If there's an upcoming appointment
                    // Uncomment and modify the code below
                    /*
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '15',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              Text(
                                'Jun',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Abhyanga Therapy',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '10:00 AM - 11:30 AM',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Dr. Aditya Sharma',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // Reschedule appointment
                            },
                            child: Text('Reschedule'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green.shade700,
                              side: BorderSide(color: Colors.green.shade700),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // View appointment details
                            },
                            child: Text('View Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    */
                    // If there's no upcoming appointment
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No upcoming appointments',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                // Navigate to appointment booking
                              },
                              child: Text('Book an Appointment'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 24),

          // Panchakarma Treatments Carousel
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Panchakarma Treatments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  '${_currentCarouselIndex + 1}/${_panchakarmaInfo.length}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          CarouselSlider.builder(
            itemCount: _panchakarmaInfo.length,
            options: CarouselOptions(
              height: 350,
              viewportFraction: 0.85,
              enlargeCenterPage: true,
              onPageChanged: (index, reason) {
                setState(() {
                  _currentCarouselIndex = index;
                });
              },
            ),
            itemBuilder: (context, index, realIndex) {
              final info = _panchakarmaInfo[index];
              return _buildPanchakarmaCard(info);
            },
          ),

          SizedBox(height: 24),

          // Recent Updates
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Recent Updates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
          ),
          SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentUpdates.length,
            itemBuilder: (context, index) {
              final update = _recentUpdates[index];
              return Card(
                elevation: 1,
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(update['icon'], color: Colors.green.shade700),
                  ),
                  title: Text(
                    update['title'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(update['description']),
                      SizedBox(height: 4),
                      Text(
                        update['date'],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 100,
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanchakarmaCard(Map<String, dynamic> info) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder (replace with actual images)
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.green.shade200,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              image: DecorationImage(
                image: AssetImage('assets/images/placeholder.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              info['title'],
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: Offset(1, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info['description'],
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                ),
                SizedBox(height: 16),
                Text(
                  'Benefits:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                SizedBox(height: 8),
                ...List.generate(
                  (info['benefits'] as List).length,
                  (index) => Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade700,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(child: Text(info['benefits'][index])),
                      ],
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
