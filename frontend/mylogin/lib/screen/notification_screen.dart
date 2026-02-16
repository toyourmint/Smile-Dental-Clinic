import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  ////////////////////////////////////////////////////////////
  /// 🔹 ดึงข้อมูลจาก API
  ////////////////////////////////////////////////////////////
  Future<void> fetchNotifications() async {
    try {
      // 🔥 เปลี่ยน URL เป็นของจริง
      final response =
          await http.get(Uri.parse("http://your-api.com/notifications"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          notifications = data is List ? data : [];
          isLoading = false;
        });
      } else {
        setState(() {
          notifications = [];
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() {
        notifications = [];
        isLoading = false;
      });
    }
  }

  ////////////////////////////////////////////////////////////
  /// 🔹 แปลงวันที่ ค.ศ. → พ.ศ.
  ////////////////////////////////////////////////////////////
  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "";

    try {
      DateTime d = DateTime.parse(date);
      int yearThai = d.year + 543;

      return "${d.day.toString().padLeft(2, '0')}."
          "${d.month.toString().padLeft(2, '0')}."
          "$yearThai";
    } catch (e) {
      return "";
    }
  }

  ////////////////////////////////////////////////////////////
  /// 🔹 UI
  ////////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: const Text(
          "แจ้งเตือน",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())

          /// 🔥 ถ้าไม่มีข้อมูล
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.notifications_none,
                        size: 60,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "ไม่มีการแจ้งเตือน",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )

              /// 🔥 ถ้ามีข้อมูล
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final item = notifications[index];

                    return NotificationCard(
                      title: item['title'] ?? "",
                      date: formatDate(item['date']),
                      start: item['start_time'] ?? "",
                      end: item['end_time'] ?? "",
                    );
                  },
                ),
    );
  }
}

////////////////////////////////////////////////////////
/// 🔔 Notification Card
////////////////////////////////////////////////////////
class NotificationCard extends StatelessWidget {
  final String title;
  final String date;
  final String start;
  final String end;

  const NotificationCard({
    super.key,
    required this.title,
    required this.date,
    required this.start,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications,
            color: Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date.isNotEmpty
                      ? "$date เวลา $start - $end น."
                      : "",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
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