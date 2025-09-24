// test_search_widget.dart
import 'package:flutter/material.dart';

class TestSearchWidget extends StatefulWidget {
  @override
  State<TestSearchWidget> createState() => _TestSearchWidgetState();
}

class _TestSearchWidgetState extends State<TestSearchWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          SizedBox(width: 16),
          Icon(Icons.search, color: Colors.grey[600]),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Test search - type here',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(0),
              ),
              onChanged: (value) {
                print('Text changed: $value');
                setState(() {});
              },
              onSubmitted: (value) {
                print('Search submitted: $value');
              },
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                setState(() {});
              },
              child: Icon(Icons.close, color: Colors.grey[600]),
            ),
          SizedBox(width: 16),
        ],
      ),
    );
  }
}
