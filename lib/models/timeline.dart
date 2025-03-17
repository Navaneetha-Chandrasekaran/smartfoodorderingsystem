import 'package:bitetimenew/models/constants.dart';
import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../animations/timeline_animation.dart';
import 'event_card.dart';

class Timeline extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isPast;
  final EventCard eventCard;

  const Timeline({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.isPast,
    required this.eventCard,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: screenWidth * 0.45,
      child: TimelineTile(
        isFirst: isFirst,
        isLast: isLast,

        beforeLineStyle: LineStyle(
          color: isPast ? secondaryColor : Colors.grey,
          thickness: isPast ? 4 : 2,
        ),

        indicatorStyle: IndicatorStyle(
          width: screenWidth * 0.08,
          color: isPast ? secondaryColor : Colors.grey,
          iconStyle: IconStyle(
            iconData: isPast ? Icons.check : Icons.circle,
            color: Colors.white,
          ),
        ),

        endChild: TimelineAnimation(
          isPast: isPast,
          child: eventCard,
        ),
      ),
    );
  }
}
