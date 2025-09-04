import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../domain/entities/provider.dart';
import '../../widgets/rating_stars.dart';
import '../../widgets/verification_badge.dart';
import '../../widgets/service_chip.dart';

class ProviderProfilePage extends StatefulWidget {
  final Provider provider;

  const ProviderProfilePage({
    super.key,
    required this.provider,
  });

  @override
  State<ProviderProfilePage> createState() => _ProviderProfilePageState();
}

class _ProviderProfilePageState extends State<ProviderProfilePage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isFollowing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProviderInfo(),
                _buildQuickStats(),
                _buildTabBar(),
                _buildTabContent(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Cover photos carousel
            PageView.builder(
              itemCount: widget.provider.coverPhotos.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(widget.provider.coverPhotos[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black45,
                  ],
                ),
              ),
            ),
            // Online status indicator
            if (widget.provider.isOnline)
              Positioned(
                top: 100,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Symbols.circle,
                        color: Colors.white,
                        size: 8,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'En línea',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(
            Symbols.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              _isFollowing ? Symbols.favorite : Symbols.favorite_border,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isFollowing = !_isFollowing;
              });
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Symbols.share,
              color: Colors.white,
            ),
            onPressed: () {
              // Implementar compartir
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProviderInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Profile image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    widget.provider.profileImage,
                    fit: BoxFit.cover,
                    // 🚀 OPTIMIZACIÓN: cacheWidth reduce memoria para thumbnails
                    cacheWidth: 200,
                    cacheHeight: 200,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.provider.name,
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w600, // Corporativo
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (widget.provider.isVerified)
                          const VerificationBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        RatingStars(
                          rating: widget.provider.rating.overall,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.provider.rating.overall}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          ' (${widget.provider.rating.totalReviews} reseñas)',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.provider.completedJobs} trabajos completados',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            widget.provider.description,
            style: GoogleFonts.inter(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 20),
          // Services chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.provider.services
                .map((service) => ServiceChip(label: service))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Symbols.schedule,
            label: 'Respuesta',
            value: widget.provider.responseTime,
          ),
          _buildStatItem(
            icon: Symbols.work,
            label: 'Experiencia',
            value: '${widget.provider.experienceYears} años',
          ),
          _buildStatItem(
            icon: Symbols.location_on,
            label: 'Radio',
            value: '${widget.provider.location.serviceRadius.toInt()} km',
          ),
          _buildStatItem(
            icon: Symbols.payments,
            label: 'Desde',
            value: '\$${widget.provider.hourlyRate.toInt()}/h',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).primaryColor,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: Theme.of(context).primaryColor,
        indicatorWeight: 3,
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Trabajos'),
          Tab(text: 'Reseñas'),
          Tab(text: 'Disponibilidad'),
          Tab(text: 'Verificación'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return SizedBox(
      height: 600,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildWorkSamplesTab(),
          _buildReviewsTab(),
          _buildAvailabilityTab(),
          _buildVerificationTab(),
        ],
      ),
    );
  }

  Widget _buildWorkSamplesTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: widget.provider.workSamples.length,
        itemBuilder: (context, index) {
          final sample = widget.provider.workSamples[index];
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      sample.images.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      // 🚀 OPTIMIZACIÓN: cacheWidth reduce memoria para thumbnails
                      cacheWidth: 300,
                      cacheHeight: 200,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sample.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          RatingStars(
                            rating: sample.rating,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            sample.rating.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Rating overview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      widget.provider.rating.overall.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w600, // Corporativo
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    RatingStars(
                      rating: widget.provider.rating.overall,
                      size: 16,
                    ),
                    Text(
                      '${widget.provider.rating.totalReviews} reseñas',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _buildRatingBar('Calidad', widget.provider.rating.quality),
                      _buildRatingBar('Puntualidad', widget.provider.rating.punctuality),
                      _buildRatingBar('Comunicación', widget.provider.rating.communication),
                      _buildRatingBar('Valor', widget.provider.rating.value),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Recent reviews
          Expanded(
            child: ListView.builder(
              itemCount: widget.provider.rating.recentReviews.length,
              itemBuilder: (context, index) {
                final review = widget.provider.rating.recentReviews[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(review.clientImage),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.clientName,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Row(
                                  children: [
                                    RatingStars(
                                      rating: review.rating.toDouble(),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      review.serviceType,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        review.comment,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (review.images.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: review.images.length,
                            itemBuilder: (context, imgIndex) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(review.images[imgIndex]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String label, double rating) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: rating / 5,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            rating.toString(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick booking info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.provider.availability.instantBooking
                  ? Colors.green[50]
                  : Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.provider.availability.instantBooking
                    ? Colors.green[200]!
                    : Colors.orange[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.provider.availability.instantBooking
                      ? Symbols.flash_on
                      : Symbols.schedule,
                  color: widget.provider.availability.instantBooking
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.provider.availability.instantBooking
                        ? 'Reserva instantánea disponible'
                        : 'Requiere confirmación (${widget.provider.availability.advanceBookingDays} días de anticipación)',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.provider.availability.instantBooking
                          ? Colors.green[700]
                          : Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Horarios de disponibilidad',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // Weekly schedule
          ...widget.provider.availability.weeklySchedule.entries
              .map((entry) => _buildDaySchedule(entry.key, entry.value)),
        ],
      ),
    );
  }

  Widget _buildDaySchedule(String day, List<TimeSlot> slots) {
    final dayNames = {
      'monday': 'Lunes',
      'tuesday': 'Martes',
      'wednesday': 'Miércoles',
      'thursday': 'Jueves',
      'friday': 'Viernes',
      'saturday': 'Sábado',
      'sunday': 'Domingo',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              dayNames[day] ?? day,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: slots.isEmpty
                ? Text(
                    'No disponible',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  )
                : Wrap(
                    spacing: 8,
                    children: slots
                        .map((slot) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: slot.isAvailable
                                    ? Colors.green[100]
                                    : Colors.red[100],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${slot.startTime} - ${slot.endTime}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: slot.isAvailable
                                      ? Colors.green[700]
                                      : Colors.red[700],
                                ),
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationTab() {
    final verification = widget.provider.verification;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verification level badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: _getVerificationColor(verification.verificationLevel),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getVerificationLabel(verification.verificationLevel),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Verificaciones completadas',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildVerificationItem(
            'Identidad verificada',
            verification.identityVerified,
            Symbols.verified_user,
          ),
          _buildVerificationItem(
            'Teléfono verificado',
            verification.phoneVerified,
            Symbols.phone,
          ),
          _buildVerificationItem(
            'Email verificado',
            verification.emailVerified,
            Symbols.mark_email_read,
          ),
          _buildVerificationItem(
            'Antecedentes verificados',
            verification.backgroundCheckVerified,
            Symbols.security,
          ),
          if (verification.verifiedAt != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Symbols.verified,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Verificado por Prosavis el ${_formatDate(verification.verifiedAt!)}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationItem(String title, bool isVerified, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified ? Colors.green[200]! : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isVerified ? Colors.green[600] : Colors.grey[500],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isVerified ? Colors.green[700] : Colors.grey[600],
              ),
            ),
          ),
          Icon(
            isVerified ? Symbols.check_circle : Symbols.cancel,
            color: isVerified ? Colors.green[600] : Colors.grey[500],
            size: 20,
          ),
        ],
      ),
    );
  }

  Color _getVerificationColor(String level) {
    switch (level) {
      case 'premium':
        return Colors.purple;
      case 'standard':
        return Colors.blue;
      case 'basic':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getVerificationLabel(String level) {
    switch (level) {
      case 'premium':
        return 'Verificación Premium';
      case 'standard':
        return 'Verificación Estándar';
      case 'basic':
        return 'Verificación Básica';
      default:
        return 'Sin verificar';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Chat button
          Expanded(
            flex: 1,
            child: OutlinedButton.icon(
              onPressed: () {
                // Navigate to chat
              },
              icon: const Icon(Symbols.chat),
              label: const Text('Chat'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Book now button
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to booking
              },
              icon: const Icon(Symbols.event),
              label: const Text('Reservar ahora'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 