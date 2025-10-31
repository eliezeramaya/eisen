import 'package:flutter/material.dart';
import '../../domain/models.dart';
import 'donut_balance.dart';

class CardBalance extends StatelessWidget {
  const CardBalance({super.key, this.balance});
  final BalanceBreakdown? balance;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Balance Eisenhower',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            DonutBalance(balance: balance),
          ],
        ),
      ),
    );
  }
}
