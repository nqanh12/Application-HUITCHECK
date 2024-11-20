  import 'package:flutter/material.dart';

  class LanguageSettingsScreen extends StatelessWidget {
    const LanguageSettingsScreen({super.key});

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Cài đặt ngôn ngữ", style: TextStyle(color: Colors.black, fontSize: 24,fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: const Color.fromARGB(255, 25, 117, 215),
          elevation: 0,
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 197, 216, 236),
                Color.fromARGB(255, 25, 117, 215),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 80),
                const SizedBox(height: 20),
                ListTile(
                  title: const Text("Tiếng Việt", style: TextStyle(fontSize: 20,color: Colors.black)),
                  trailing: Radio(
                    value: true,
                    groupValue: true,
                    onChanged: (value) {
                      // Xử lý logic chọn ngôn ngữ ở đây
                    },
                  ),
                ),
                ListTile(
                  title: const Text("English", style: TextStyle(fontSize: 20,color: Colors.black)),
                  trailing: Radio(
                    value: false,
                    groupValue: true,
                    onChanged: (value) {
                      // Xử lý logic chọn ngôn ngữ ở đây
                    },
                  ),
                ),
                // Thêm các tùy chọn ngôn ngữ khác nếu cần
              ],
            ),
          ),
        ),
      );
    }
  }