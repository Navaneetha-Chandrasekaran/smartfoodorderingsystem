import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // ✅ Import for date formatting

class TimeSelector extends StatefulWidget {
  final TimeOfDay? selectedTime;
  final Function(TimeOfDay) onTimeSelected;

  const TimeSelector({
    super.key,
    required this.selectedTime,
    required this.onTimeSelected,
  });

  @override
  State<TimeSelector> createState() => _TimeSelectorState();
}

class _TimeSelectorState extends State<TimeSelector> {
  TimeOfDay? _selectedTime;
  String _currentDate = ""; // ✅ Store current date

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.selectedTime;
    _currentDate = _getCurrentDate(); // ✅ Get current date on init
  }

  Future<void> _pickTime(BuildContext context) async {
    // ✅ Get current time
    DateTime now = DateTime.now();

    // ✅ Show time picker
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );

    if (picked != null) {
      DateTime pickedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        picked.hour,
        picked.minute,
      );

      // ✅ Ensure selected time is at least 10 minutes ahead
      if (pickedDateTime.isAfter(now.add(const Duration(minutes: 10)))) {
        setState(() {
          _selectedTime = picked;
        });

        widget.onTimeSelected(picked); // ✅ Notify parent widget
      } else {
        // ✅ Show error message **ONLY IF time is invalid**
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select a time at least 10 minutes from now."),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ✅ Formats Time in AM/PM format
  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  // ✅ Get Current Date
  String _getCurrentDate() {
    return DateFormat("EEEE, MMM d, yyyy").format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        // ✅ Display Current Date
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "Date: $_currentDate",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        const SizedBox(height: 8),

        // ✅ Time Selector
        InkWell(
          onTap: () => _pickTime(context),
          child: Container(
            width: screenWidth * 0.9,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, color: Colors.blue, size: 18),
                const SizedBox(width: 6),
                Text(
                  _selectedTime != null
                      ? _formatTime(_selectedTime!)
                      : "Select Time",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
