import 'package:flutter/material.dart';

class NotificationScreenMock extends StatelessWidget {
  const NotificationScreenMock({super.key});

  // ===============================
  // 🔹 Mock Data (ข้อมูลปลอม)
  // ===============================
  final List<Map<String, String>> notifications = const [
    {
      "title": "แจ้งเตือนวันนัดหมาย",
      "date": "18.02.2569",
      "start": "13.00",
      "end": "14.00",
    },
    {
      "title": "แจ้งเตือนวันนัดหมาย",
      "date": "17.01.2569",
      "start": "11.00",
      "end": "12.00",
    },
    {
      "title": "เลื่อนวันนัดหมาย",
      "date": "17.01.2569",
      "start": "11.00",
      "end": "12.00",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ===== Header =====
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

      // ===== List Mock =====
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final item = notifications[index];

          return NotificationCard(
            title: item["title"]!,
            date: item["date"]!,
            start: item["start"]!,
            end: item["end"]!,
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
                  "$date เวลา $start - $end น.",
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
