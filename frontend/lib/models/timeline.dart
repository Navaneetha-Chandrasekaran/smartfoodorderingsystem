import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';

import '../animations/timeline_animation.dart';
import 'constants.dart';
import 'event_card.dart';

class Timeline extends StatelessWidget {
  final bool isFirst;
  final bool isLast;
  final bool isPast;
  final EventCard eventCard;
  final String orderNumber;
  final Set<String> animatedOrders;
  final bool isRefreshing;

  const Timeline({
    super.key,
    required this.isFirst,
    required this.isLast,
    required this.isPast,
    required this.eventCard,
    required this.orderNumber,
    required this.animatedOrders,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: screenWidth * 0.25,
      child: TimelineTile(
        isFirst: isFirst,
        isLast: isLast,
        
        alignment: TimelineAlign.manual,
        lineXY: 0.1,

        beforeLineStyle: LineStyle(
          color: isPast ? const Color(0xFF4AE578) : Colors.grey.shade200,
          thickness: 2,
        ),

        indicatorStyle: IndicatorStyle(
          width: screenWidth * 0.05,
          height: screenWidth * 0.05,
          indicator: Container(
            decoration: BoxDecoration(
              color: isPast ? const Color(0xFF4AE578) : Colors.grey.shade300,
              shape: BoxShape.circle,
              border: Border.all(
                color: isPast ? Colors.white : Colors.grey.shade200,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isPast ? const Color(0xFF4AE578).withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: isPast 
              ? Icon(
                  Icons.check,
                  color: Colors.white,
                  size: screenWidth * 0.03,
                )
              : null,
          ),
          padding: EdgeInsets.zero,
        ),

        endChild: Padding(
          padding: EdgeInsets.only(left: screenWidth * 0.02),
          child: TimelineAnimation(
            key: ValueKey('timeline_${orderNumber}_${isPast}_${isRefreshing}'),
            isPast: isPast,
            child: eventCard,
            orderNumber: orderNumber,
            animatedOrders: animatedOrders,
            isRefreshing: isRefreshing,
          ),
        ),
      ),
    );
  }
}
