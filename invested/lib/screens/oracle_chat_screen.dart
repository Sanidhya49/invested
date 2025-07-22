import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OracleChatScreen extends StatefulWidget {
  const OracleChatScreen({super.key});
  @override
  State<OracleChatScreen> createState() => _OracleChatScreenState();
}

class _OracleChatScreenState extends State<OracleChatScreen> {
  final TextEditingController _textController = TextEditingController();
  bool isOracleLoading = false;
  List<Map<String, String>> oracleChat = [];
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> askOracle() async {
    final question = _textController.text;
    if (question.trim().isEmpty) return;
    _textController.clear();
    setState(() {
      isOracleLoading = true;
      oracleChat.add({'role': 'user', 'text': question});
    });
    _scrollToBottom();
    final user = FirebaseAuth.instance.currentUser;
    final idToken = await user?.getIdToken();
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/ask-oracle'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'question': question}),
      );
      if (mounted) {
        setState(() {
          final data = json.decode(response.body);
          oracleChat.add({
            'role': 'oracle',
            'text': data['answer'] ?? 'Error: No answer received.',
          });
        });
      }
    } catch (e) {
      if (mounted)
        setState(() => oracleChat.add({'role': 'oracle', 'text': 'Error: $e'}));
    } finally {
      if (mounted) setState(() => isOracleLoading = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8.0),
            itemCount: oracleChat.length,
            itemBuilder: (context, index) {
              final msg = oracleChat[index];
              final isUser = msg['role'] == 'user';
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Row(
                  mainAxisAlignment: isUser
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isUser)
                      const CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child: Icon(
                          Icons.smart_toy,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    if (!isUser) const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Colors.deepPurple.shade50
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: SelectableText(msg['text'] ?? ''),
                      ),
                    ),
                    if (isUser) const SizedBox(width: 8),
                    if (isUser)
                      CircleAvatar(
                        backgroundColor: Colors.green[200],
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12.0)),
                    ),
                    labelText: 'Ask Oracle a question...',
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onSubmitted: (_) => askOracle(),
                ),
              ),
              const SizedBox(width: 8),
              isOracleLoading
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    )
                  : FloatingActionButton(
                      backgroundColor: Colors.deepPurple,
                      onPressed: askOracle,
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
            ],
          ),
        ),
      ],
    );
  }
}
