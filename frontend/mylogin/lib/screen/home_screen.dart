import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _currentQueue = 1;
  final int _myQueue = 127;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("สวัสดีตอนเช้า,",
                            style: GoogleFonts.kanit(fontSize: 18, color: Colors.grey[600])),
                        Text("คุณ มนต์แคน",
                            style: GoogleFonts.kanit(
                                fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
                      ],
                    ),
                    _buildProfileAvatar(),
                  ],
                ),
                
                const SizedBox(height: 25),

                // 2. Blue Queue Card
                _buildQueueCard(),

                const SizedBox(height: 30),

                // 3. Search Bar
                _buildSearchBar(),

                const SizedBox(height: 30),

                const Text("รายชื่อทันตแพทย์",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                
                const SizedBox(height: 15),

                // 4. Doctor List
                _buildDoctorCard(
                  name: "Dr. Joseph Brostito",
                  specialty: "Dental Specialist",
                  image: "https://i.pravatar.cc/150?img=68",
                  distance: "1.2 KM",
                ),
                const SizedBox(height: 15),
                _buildDoctorCard(
                  name: "Dr. Imran Syahir",
                  specialty: "General Dentist",
                  image: "https://i.pravatar.cc/150?img=12",
                  distance: "2.5 KM",
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Widget ย่อยต่างๆ ---

  Widget _buildProfileAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: const CircleAvatar(
        radius: 28,
        backgroundColor: Colors.orangeAccent,
        child: Icon(Icons.face, color: Colors.white, size: 35),
      ),
    );
  }

  Widget _buildQueueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF448AFF), Color(0xFF2979FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
                radius: 22,
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("คุณ มนต์แคน",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  Text("บริการ: ถอนฟัน",
                      style: TextStyle(color: ColorUtils.whiteCC, fontSize: 13)),
                ],
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18)
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(color: Colors.white24),
          ),
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQueueInfo("คิวของคุณ", "$_myQueue"),
                const VerticalDivider(color: Colors.white24, thickness: 1),
                _buildQueueInfo("คิวปัจจุบัน", "$_currentQueue"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: "ค้นหาทันตแพทย์...",
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }

  Widget _buildQueueInfo(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: ColorUtils.whiteB8, fontSize: 14)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildDoctorCard({required String name, required String specialty, required String image, required String distance}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(image, width: 60, height: 60, fit: BoxFit.cover),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    Text(specialty, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  ],
                ),
              ),
              _buildDistanceTag(distance),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("จองนัดหมาย", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDistanceTag(String distance) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(Icons.location_on, size: 14, color: Colors.blue[700]),
          const SizedBox(width: 4),
          Text(distance, style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class ColorUtils {
  static const Color whiteCC = Color(0xCCFFFFFF);
  static const Color whiteB8 = Color(0xB8FFFFFF);
}