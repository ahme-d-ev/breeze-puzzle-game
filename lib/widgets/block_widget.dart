import 'package:flutter/material.dart';

class BlockWidget extends StatelessWidget {
  const BlockWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(3, (int index) {
        return Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}
