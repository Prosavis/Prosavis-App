import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/provider.dart';
import '../../../domain/entities/booking.dart';

class ChatPage extends StatefulWidget {
  final Provider provider;
  final Booking? booking;

  const ChatPage({
    super.key,
    required this.provider,
    this.booking,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _typingAnimationController;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _loadInitialMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  void _loadInitialMessages() {
    // Simulated initial messages
    setState(() {
      _messages.addAll([
        ChatMessage(
          id: '1',
          senderId: widget.provider.id,
          message: '¡Hola! He recibido tu solicitud de ${widget.booking?.details.serviceType ?? 'servicio'}. ¿Podrías contarme más detalles sobre lo que necesitas?',
          sentAt: DateTime.now().subtract(const Duration(minutes: 5)),
          isFromClient: false,
          type: MessageType.text,
          senderName: widget.provider.name,
          senderImage: widget.provider.profileImage,
        ),
        ChatMessage(
          id: '2',
          senderId: 'client',
          message: 'Hola, necesito que revises la tubería de la cocina, está goteando.',
          sentAt: DateTime.now().subtract(const Duration(minutes: 3)),
          isFromClient: true,
          type: MessageType.text,
          senderName: 'Tú',
          senderImage: '',
        ),
        ChatMessage(
          id: '3',
          senderId: widget.provider.id,
          message: 'Perfecto, puedo ayudarte con eso. ¿El goteo es constante o solo cuando abres el grifo?',
          sentAt: DateTime.now().subtract(const Duration(minutes: 1)),
          isFromClient: false,
          type: MessageType.text,
          senderName: widget.provider.name,
          senderImage: widget.provider.profileImage,
        ),
      ]);
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (widget.booking != null) _buildBookingCard(),
          Expanded(
            child: _buildMessagesList(),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Symbols.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage(widget.provider.profileImage),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.provider.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    if (widget.provider.isOnline) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'En línea',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Responde en ${widget.provider.responseTime}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Symbols.call, color: Colors.black87),
          onPressed: () {
            _showCallDialog();
          },
        ),
        IconButton(
          icon: const Icon(Symbols.more_vert, color: Colors.black87),
          onPressed: () {
            _showMoreOptions();
          },
        ),
      ],
    );
  }

  Widget _buildBookingCard() {
    if (widget.booking == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Symbols.event,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Reserva activa',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.booking!.status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(widget.booking!.status),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(widget.booking!.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.booking!.details.title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatDate(widget.booking!.scheduledAt)} • \$${widget.booking!.payment.totalAmount.toInt()}',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isLastMessage = index == _messages.length - 1;
        final isFirstMessage = index == 0;
        
        bool showTimestamp = false;
        if (isFirstMessage) {
          showTimestamp = true;
        } else {
          final previousMessage = _messages[index - 1];
          final timeDiff = message.sentAt.difference(previousMessage.sentAt);
          if (timeDiff.inMinutes > 5) {
            showTimestamp = true;
          }
        }

        return Column(
          children: [
            if (showTimestamp) _buildTimestamp(message.sentAt),
            _buildMessageBubble(message),
            if (isLastMessage) const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildTimestamp(DateTime time) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _formatTime(time),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isFromClient = message.isFromClient;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isFromClient 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromClient) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(message.senderImage),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isFromClient 
                    ? Theme.of(context).primaryColor
                    : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isFromClient ? 16 : 4),
                  bottomRight: Radius.circular(isFromClient ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isFromClient ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message.sentAt),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isFromClient 
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromClient) const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(widget.provider.profileImage),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingAnimationController,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    return AnimatedBuilder(
                      animation: _typingAnimationController,
                      builder: (context, child) {
                        final animationValue = 
                            (_typingAnimationController.value - delay).clamp(0.0, 1.0);
                        final scale = 1.0 + 0.5 * 
                            (1.0 - (animationValue - 0.5).abs() * 2).clamp(0.0, 1.0);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Symbols.add,
                color: Colors.grey[600],
              ),
              onPressed: () {
                _showAttachmentOptions();
              },
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    hintStyle: GoogleFonts.inter(
                      color: Colors.grey[500],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.inter(fontSize: 14),
                  maxLines: null,
                  onChanged: (text) {
                    // Handle typing indicator
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Symbols.send,
                  color: Colors.white,
                ),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'client',
      message: message,
      sentAt: DateTime.now(),
      isFromClient: true,
      type: MessageType.text,
      senderName: 'Tú',
      senderImage: '',
    );

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
    });

    _scrollToBottom();

    // Simulate provider response
    _simulateProviderResponse();
  }

  void _simulateProviderResponse() {
    setState(() {
      _isTyping = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      final responses = [
        'Entiendo, puedo ayudarte con eso.',
        'Te puedo dar una cotización más precisa cuando vea el problema.',
        '¿Tienes alguna foto del área afectada?',
        'Perfecto, podemos agendar la visita.',
      ];

      final response = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: widget.provider.id,
        message: responses[DateTime.now().second % responses.length],
        sentAt: DateTime.now(),
        isFromClient: false,
        type: MessageType.text,
        senderName: widget.provider.name,
        senderImage: widget.provider.profileImage,
      );

      setState(() {
        _isTyping = false;
        _messages.add(response);
      });

      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showCallDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Llamar a ${widget.provider.name}',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          '¿Deseas llamar a ${widget.provider.name}?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle call
            },
            child: const Text('Llamar'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Symbols.person),
              title: const Text('Ver perfil'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to provider profile
              },
            ),
            ListTile(
              leading: const Icon(Symbols.event),
              title: const Text('Ver reserva'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to booking details
              },
            ),
            ListTile(
              leading: const Icon(Symbols.report),
              title: const Text('Reportar problema'),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Symbols.camera_alt, color: Colors.blue),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                // Handle camera
              },
            ),
            ListTile(
              leading: const Icon(Symbols.photo_library, color: Colors.green),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                // Handle gallery
              },
            ),
            ListTile(
              leading: const Icon(Symbols.location_on, color: Colors.red),
              title: const Text('Ubicación'),
              onTap: () {
                Navigator.pop(context);
                // Handle location
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reportar problema',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          '¿Hay algún problema con este proveedor que quieras reportar?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle report
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reportar'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return Colors.orange;
      case BookingStatus.confirmed:
        return Colors.blue;
      case BookingStatus.inProgress:
        return Colors.purple;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelled:
        return Colors.red;
      case BookingStatus.disputed:
        return Colors.grey;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Pendiente';
      case BookingStatus.confirmed:
        return 'Confirmada';
      case BookingStatus.inProgress:
        return 'En progreso';
      case BookingStatus.completed:
        return 'Completada';
      case BookingStatus.cancelled:
        return 'Cancelada';
      case BookingStatus.disputed:
        return 'En disputa';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    if (messageDate == today) {
      return 'Hoy ${_formatMessageTime(date)}';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Ayer ${_formatMessageTime(date)}';
    } else {
      return '${date.day}/${date.month} ${_formatMessageTime(date)}';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate == today) {
      return 'Hoy';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Ayer';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  String _formatMessageTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String message;
  final DateTime sentAt;
  final bool isFromClient;
  final MessageType type;
  final String senderName;
  final String senderImage;
  final List<String>? attachments;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.message,
    required this.sentAt,
    required this.isFromClient,
    required this.type,
    required this.senderName,
    required this.senderImage,
    this.attachments,
  });
} 