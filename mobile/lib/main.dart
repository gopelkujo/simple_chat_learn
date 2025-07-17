import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: ChatRoomList());
  }
}

class ChatRoomList extends StatefulWidget {
  const ChatRoomList({super.key});

  @override
  State<ChatRoomList> createState() => _ChatRoomListState();
}

class _ChatRoomListState extends State<ChatRoomList> {
  late final int currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = Random().nextInt(1000);
    print('🚩 Current registered id: $currentUserId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Whadapp'), centerTitle: false),
      body: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          ChatPage(currentUserId: currentUserId, roomId: index),
                ),
              );
            },
            style: TextButton.styleFrom(shape: BeveledRectangleBorder(), alignment: Alignment.centerLeft),
            child: Text('Room chat $index'),
          );
        },
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final int currentUserId;
  final int roomId;

  const ChatPage({
    super.key,
    required this.currentUserId,
    required this.roomId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late io.Socket socket;
  final List<String> messages = [];
  final TextEditingController _controller = TextEditingController();
  late final String roomId;

  @override
  void initState() {
    super.initState();
    roomId = generateRoomId();
    connectToSocket();
  }

  String generateRoomId() {
    return 'chat_${widget.roomId}';
  }

  void connectToSocket() {
    final baseUrl = dotenv.env['BASE_URL'];

    if (baseUrl == null) {
      print('❌ baseUrl not found. Set up it first in your .env (check .env.example)');
      return;
    }

    socket = io.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('✅ Connected to socket server');
      socket.emit('join_room', {'roomId': roomId});
    });

    socket.on('receive_message', (data) {
      print('📨 Reveived message: ${data['message']}');
      setState(() {
        messages.add("${data['senderId']}: ${data['message']}");
      });
    });

    socket.onDisconnect((_) {
      print('❌ Disconnected from socket server');
    });
  }

  void sendMessage() {
    final message = _controller.text.trim();
    if (message.isNotEmpty) {
      socket.emit('send_message', {
        'roomId': roomId,
        'message': message,
        'senderId': widget.currentUserId,
      });

      setState(() {
        messages.add("Me: $message");
        _controller.clear();
      });
    }
  }

  @override
  void dispose() {
    socket.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Private Room Chat ${widget.roomId}')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (_, index) => ListTile(title: Text(messages[index])),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
