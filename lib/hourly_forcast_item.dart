import 'package:flutter/material.dart';

class HourlyForcastItem extends StatelessWidget {
  final String hour;
  final IconData icon;
  final String value;

  const HourlyForcastItem(
      {super.key, required this.hour, required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color.fromARGB(31, 161, 131, 131),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SizedBox(
            width: 100,
            child: Column(
              children: [
                Text(hour,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(
                  height: 10,
                ),
                Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(value,
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
