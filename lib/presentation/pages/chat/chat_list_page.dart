import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/provider.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final List<ChatConversation> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  void _loadConversations() {
    // Simulated conversations
    setState(() {
      _conversations.addAll([
        ChatConversation(
          id: '1',
          provider: Provider(
            id: 'p1',
            name: 'Carlos Rodríguez',
            email: 'carlos@example.com',
            phone: '+57 300 123 4567',
            profileImage: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
            description: 'Plomero certificado con 10 años de experiencia',
            services: const ['Plomería', 'Reparaciones'],
            coverPhotos: const [],
            workSamples: const [],
            verification: ProviderVerification(
              identityVerified: true,
              phoneVerified: true,
              emailVerified: true,
              backgroundCheckVerified: true,
              documents: const [],
              verificationLevel: 'standard',
              verifiedAt: DateTime.now(),
            ),
            rating: const ProviderRating(
              overall: 4.8,
              totalReviews: 124,
              starDistribution: {},
              quality: 4.9,
              punctuality: 4.7,
              communication: 4.8,
              value: 4.6,
              recentReviews: [],
            ),
            availability: const ProviderAvailability(
              weeklySchedule: {},
              unavailableDates: [],
              instantBooking: true,
              advanceBookingDays: 3,
            ),
            location: const Location(
              latitude: 4.7110,
              longitude: -74.0721,
              address: 'Bogotá, Colombia',
              city: 'Bogotá',
              state: 'Cundinamarca',
              zipCode: '110111',
              serviceRadius: 20,
            ),
            certifications: const [],
            experienceYears: 10,
            hourlyRate: 35.0,
            isOnline: true,
            isVerified: true,
            joinedAt: DateTime.now(),
            completedJobs: 89,
            responseTime: '< 5 min',
          ),
          lastMessage: 'Perfecto, puedo ayudarte con eso.',
          lastMessageTime: DateTime.now().subtract(const Duration(minutes: 2)),
          unreadCount: 2,
          hasActiveBooking: true,
          isOnline: true,
        ),
        ChatConversation(
          id: '2',
          provider: Provider(
            id: 'p2',
            name: 'Ana García',
            email: 'ana@example.com',
            phone: '+57 301 234 5678',
            profileImage: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150',
            description: 'Especialista en limpieza del hogar',
            services: const ['Limpieza', 'Organización'],
            coverPhotos: const [],
            workSamples: const [],
            verification: ProviderVerification(
              identityVerified: true,
              phoneVerified: true,
              emailVerified: true,
              backgroundCheckVerified: false,
              documents: const [],
              verificationLevel: 'basic',
              verifiedAt: DateTime.now(),
            ),
            rating: const ProviderRating(
              overall: 4.9,
              totalReviews: 78,
              starDistribution: {},
              quality: 5.0,
              punctuality: 4.8,
              communication: 4.9,
              value: 4.8,
              recentReviews: [],
            ),
            availability: const ProviderAvailability(
              weeklySchedule: {},
              unavailableDates: [],
              instantBooking: false,
              advanceBookingDays: 1,
            ),
            location: const Location(
              latitude: 4.7110,
              longitude: -74.0721,
              address: 'Bogotá, Colombia',
              city: 'Bogotá',
              state: 'Cundinamarca',
              zipCode: '110111',
              serviceRadius: 15,
            ),
            certifications: const [],
            experienceYears: 5,
            hourlyRate: 25.0,
            isOnline: false,
            isVerified: true,
            joinedAt: DateTime.now(),
            completedJobs: 67,
            responseTime: '< 15 min',
          ),
          lastMessage: 'Muchas gracias por la calificación!',
          lastMessageTime: DateTime.now().subtract(const Duration(hours: 2)),
          unreadCount: 0,
          hasActiveBooking: false,
          isOnline: false,
        ),
        ChatConversation(
          id: '3',
          provider: Provider(
            id: 'p3',
            name: 'Miguel Torres',
            email: 'miguel@example.com',
            phone: '+57 302 345 6789',
            profileImage: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
            description: 'Electricista certificado',
            services: const ['Electricidad', 'Instalaciones'],
            coverPhotos: const [],
            workSamples: const [],
            verification: ProviderVerification(
              identityVerified: true,
              phoneVerified: true,
              emailVerified: true,
              backgroundCheckVerified: true,
              documents: const [],
              verificationLevel: 'premium',
              verifiedAt: DateTime.now(),
            ),
            rating: const ProviderRating(
              overall: 4.7,
              totalReviews: 156,
              starDistribution: {},
              quality: 4.8,
              punctuality: 4.6,
              communication: 4.7,
              value: 4.7,
              recentReviews: [],
            ),
            availability: const ProviderAvailability(
              weeklySchedule: {},
              unavailableDates: [],
              instantBooking: true,
              advanceBookingDays: 2,
            ),
            location: const Location(
              latitude: 4.7110,
              longitude: -74.0721,
              address: 'Bogotá, Colombia',
              city: 'Bogotá',
              state: 'Cundinamarca',
              zipCode: '110111',
              serviceRadius: 25,
            ),
            certifications: const [],
            experienceYears: 8,
            hourlyRate: 40.0,
            isOnline: true,
            isVerified: true,
            joinedAt: DateTime.now(),
            completedJobs: 134,
            responseTime: '< 10 min',
          ),
          lastMessage: 'El trabajo estará listo mañana',
          lastMessageTime: DateTime.now().subtract(const Duration(hours: 8)),
          unreadCount: 1,
          hasActiveBooking: true,
          isOnline: true,
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _conversations.isEmpty 
          ? _buildEmptyState() 
          : _buildConversationsList(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        'Mensajes',
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Symbols.search, color: Colors.black87),
          onPressed: () {
            _showSearchDialog();
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No tienes conversaciones',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando contactes a un proveedor,\nlas conversaciones aparecerán aquí',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        return _buildConversationTile(conversation);
      },
    );
  }

  Widget _buildConversationTile(ChatConversation conversation) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                provider: conversation.provider,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(conversation.provider.profileImage),
                  ),
                  if (conversation.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.provider.name,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (conversation.hasActiveBooking)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Activa',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conversation.lastMessage,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: conversation.unreadCount > 0 
                            ? Colors.black87 
                            : Colors.grey[600],
                        fontWeight: conversation.unreadCount > 0 
                            ? FontWeight.w500 
                            : FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTime(conversation.lastMessageTime),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: conversation.unreadCount > 0 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey[500],
                      fontWeight: conversation.unreadCount > 0 
                          ? FontWeight.w600 
                          : FontWeight.normal,
                    ),
                  ),
                  if (conversation.unreadCount > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        conversation.unreadCount.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Buscar conversaciones',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Buscar por nombre...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            // Handle search
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${time.day}/${time.month}';
    }
  }
}

class ChatConversation {
  final String id;
  final Provider provider;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool hasActiveBooking;
  final bool isOnline;

  ChatConversation({
    required this.id,
    required this.provider,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.hasActiveBooking,
    required this.isOnline,
  });
} 