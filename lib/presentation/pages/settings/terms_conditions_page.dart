import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class TermsConditionsPage extends StatefulWidget {
  const TermsConditionsPage({super.key});

  @override
  State<TermsConditionsPage> createState() => _TermsConditionsPageState();
}

class _TermsConditionsPageState extends State<TermsConditionsPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: AppConstants.longAnimation,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(
                Symbols.arrow_back,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Términos y Condiciones',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _shareTerms(),
              icon: const Icon(
                Symbols.share,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de actualización
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Última actualización: 30 de agosto de 2025',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Al usar ${AppConstants.appName}, aceptas estos términos y condiciones.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Contenido de términos y condiciones
            _buildSection(
              '1. Aceptación de los Términos',
              'Al acceder y utilizar la aplicación ${AppConstants.appName}, usted acepta estar sujeto a estos Términos y Condiciones de Uso. Si no está de acuerdo con alguna parte de estos términos, no debe utilizar nuestra aplicación.',
            ),

            _buildSection(
              '2. Descripción del Servicio',
              '${AppConstants.appName} es una plataforma digital que conecta usuarios con proveedores de servicios locales en Colombia. Facilitamos la búsqueda, contratación y gestión de servicios profesionales en diversas categorías como limpieza, mantenimiento, belleza, y más.',
            ),

            _buildSection(
              '3. Registro y Cuenta de Usuario',
              '• Debe proporcionar información precisa y completa durante el registro\n'
              '• Es responsable de mantener la confidencialidad de su cuenta\n'
              '• Debe notificar inmediatamente cualquier uso no autorizado de su cuenta\n'
              '• Debe ser mayor de 18 años para crear una cuenta',
            ),

            _buildSection(
              '4. Uso Aceptable',
              'Se compromete a:\n'
              '• Usar la plataforma solo para fines legales\n'
              '• No interferir con el funcionamiento de la aplicación\n'
              '• No usar la plataforma para actividades fraudulentas\n'
              '• Tratar a todos los usuarios con respeto y cortesía\n'
              '• No crear múltiples cuentas para el mismo usuario',
            ),

            _buildSection(
              '5. Servicios y Proveedores',
              '• ${AppConstants.appName} no presta directamente los servicios listados\n'
              '• Los proveedores son contratistas independientes\n'
              '• No garantizamos la calidad de los servicios prestados\n'
              '• Los usuarios deben evaluar directamente a los proveedores\n'
              '• Las disputas se resuelven directamente entre usuarios y proveedores',
            ),

            _buildSection(
              '6. Pagos y Facturación',
              '• ${AppConstants.appName} actúa únicamente como intermediario digital entre clientes y proveedores\n'
              '• Todos los pagos, transacciones, facturación y reembolsos son responsabilidad directa entre el cliente y el proveedor de servicios\n'
              '• ${AppConstants.appName} no procesa, administra ni es responsable de ningún tipo de transacción económica\n'
              '• ${AppConstants.appName} se exonera completamente de cualquier responsabilidad relacionada con pagos, disputas económicas, reembolsos o problemas de facturación\n'
              '• Los precios, métodos de pago y políticas de reembolso son establecidos exclusivamente por cada proveedor\n'
              '• Cualquier disputa económica debe resolverse directamente entre el cliente y el proveedor, sin intervención de ${AppConstants.appName}',
            ),

            _buildSection(
              '7. Privacidad y Datos',
              'Su privacidad es importante para nosotros. El manejo de sus datos personales se rige por nuestra Política de Privacidad, que forma parte integral de estos términos.',
            ),

            _buildSection(
              '8. Limitación de Responsabilidad',
              '${AppConstants.appName} no será responsable por:\n'
              '• Daños directos o indirectos derivados del uso de la plataforma\n'
              '• Pérdidas económicas por servicios no prestados o deficientes\n'
              '• Interrupciones del servicio por mantenimiento o fallas técnicas\n'
              '• Acciones de terceros (proveedores o usuarios)',
            ),

            _buildSection(
              '9. Modificaciones',
              'Nos reservamos el derecho de modificar estos términos en cualquier momento. Los cambios entrarán en vigor inmediatamente después de su publicación en la aplicación.',
            ),

            _buildSection(
              '10. Terminación',
              'Podemos suspender o terminar su cuenta si:\n'
              '• Viola estos términos y condiciones\n'
              '• Usa la plataforma de manera fraudulenta\n'
              '• Su cuenta permanece inactiva por períodos prolongados',
            ),

            _buildSection(
              '11. Ley Aplicable',
              'Estos términos se rigen por las leyes de la República de Colombia. Cualquier disputa será resuelta en los tribunales competentes de Colombia.',
            ),

            _buildSection(
              '12. Contacto',
              'Para preguntas sobre estos términos y condiciones, puede contactarnos a través de los canales oficiales disponibles en la aplicación.',
            ),

            const SizedBox(height: 32),

            // Acciones adicionales
            Column(
              children: [
                _buildActionButton(
                  icon: Symbols.description,
                  title: 'Política de Privacidad',
                  onTap: () => _openPrivacyPolicy(),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Symbols.support_agent,
                  title: 'Contactar Soporte',
                  onTap: () => _contactSupport(),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  icon: Symbols.download,
                  title: 'Descargar PDF',
                  onTap: () => _downloadPDF(),
                ),
              ],
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.5,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Symbols.chevron_right,
                size: 20,
                color: AppTheme.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareTerms() async {
    try {
      const String shareText = '''
Términos y Condiciones - ${AppConstants.appName}

Al usar ${AppConstants.appName}, aceptas estos términos y condiciones.

${AppConstants.appName} es una plataforma digital que conecta usuarios con proveedores de servicios locales en Colombia.

Para ver los términos completos, descarga nuestra aplicación.

📱 Disponible en Google Play Store y App Store
🌐 www.prosavis.com
''';

      // ignore: deprecated_member_use
      await Share.share(shareText);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al compartir: ${e.toString()}',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openPrivacyPolicy() {
    // Navegar a la configuración de privacidad que contiene información relevante
    context.push('/settings/privacy');
  }

  void _contactSupport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'soporte@prosavis.com',
      query: 'subject=Consulta sobre Términos y Condiciones',
    );

    try {
      await launchUrl(emailUri);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo abrir el cliente de correo',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _downloadPDF() async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Crear el PDF
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Términos y Condiciones',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Paragraph(
                text: AppConstants.appName,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Paragraph(
                text: 'Última actualización: 30 de agosto de 2025',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              pw.Paragraph(
                text: 'Al usar ${AppConstants.appName}, aceptas estos términos y condiciones.',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              
              // Contenido de los términos
              _buildPDFSection('1. Aceptación de los Términos',
                'Al acceder y utilizar la aplicación ${AppConstants.appName}, usted acepta estar sujeto a estos Términos y Condiciones de Uso. Si no está de acuerdo con alguna parte de estos términos, no debe utilizar nuestra aplicación.'),
              
              _buildPDFSection('2. Descripción del Servicio',
                '${AppConstants.appName} es una plataforma digital que conecta usuarios con proveedores de servicios locales en Colombia. Facilitamos la búsqueda, contratación y gestión de servicios profesionales en diversas categorías como limpieza, mantenimiento, belleza, y más.'),
              
              _buildPDFSection('3. Registro y Cuenta de Usuario',
                '• Debe proporcionar información precisa y completa durante el registro\n• Es responsable de mantener la confidencialidad de su cuenta\n• Debe notificar inmediatamente cualquier uso no autorizado de su cuenta\n• Debe ser mayor de 18 años para crear una cuenta'),
              
              _buildPDFSection('4. Uso Aceptable',
                'Se compromete a:\n• Usar la plataforma solo para fines legales\n• No interferir con el funcionamiento de la aplicación\n• No usar la plataforma para actividades fraudulentas\n• Tratar a todos los usuarios con respeto y cortesía\n• No crear múltiples cuentas para el mismo usuario'),
              
              _buildPDFSection('5. Servicios y Proveedores',
                '• ${AppConstants.appName} no presta directamente los servicios listados\n• Los proveedores son contratistas independientes\n• No garantizamos la calidad de los servicios prestados\n• Los usuarios deben evaluar directamente a los proveedores\n• Las disputas se resuelven directamente entre usuarios y proveedores'),
              
              _buildPDFSection('6. Pagos y Facturación',
                '• ${AppConstants.appName} actúa únicamente como intermediario digital entre clientes y proveedores\n• Todos los pagos, transacciones, facturación y reembolsos son responsabilidad directa entre el cliente y el proveedor de servicios\n• ${AppConstants.appName} no procesa, administra ni es responsable de ningún tipo de transacción económica\n• ${AppConstants.appName} se exonera completamente de cualquier responsabilidad relacionada con pagos, disputas económicas, reembolsos o problemas de facturación\n• Los precios, métodos de pago y políticas de reembolso son establecidos exclusivamente por cada proveedor\n• Cualquier disputa económica debe resolverse directamente entre el cliente y el proveedor, sin intervención de ${AppConstants.appName}'),
              
              _buildPDFSection('7. Privacidad y Datos',
                'Su privacidad es importante para nosotros. El manejo de sus datos personales se rige por nuestra Política de Privacidad, que forma parte integral de estos términos.'),
              
              _buildPDFSection('8. Limitación de Responsabilidad',
                '${AppConstants.appName} no será responsable por:\n• Daños directos o indirectos derivados del uso de la plataforma\n• Pérdidas económicas por servicios no prestados o deficientes\n• Interrupciones del servicio por mantenimiento o fallas técnicas\n• Acciones de terceros (proveedores o usuarios)'),
              
              _buildPDFSection('9. Modificaciones',
                'Nos reservamos el derecho de modificar estos términos en cualquier momento. Los cambios entrarán en vigor inmediatamente después de su publicación en la aplicación.'),
              
              _buildPDFSection('10. Terminación',
                'Podemos suspender o terminar su cuenta si:\n• Viola estos términos y condiciones\n• Usa la plataforma de manera fraudulenta\n• Su cuenta permanece inactiva por períodos prolongados'),
              
              _buildPDFSection('11. Ley Aplicable',
                'Estos términos se rigen por las leyes de la República de Colombia. Cualquier disputa será resuelta en los tribunales competentes de Colombia.'),
              
              _buildPDFSection('12. Contacto',
                'Para preguntas sobre estos términos y condiciones, puede contactarnos a través de los canales oficiales disponibles en la aplicación.'),
            ];
          },
        ),
      );

      // Obtener directorio de descargas
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/terminos_condiciones_${AppConstants.appName}.pdf');
      
      // Guardar el archivo
      await file.writeAsBytes(await pdf.save());

      // Cerrar diálogo de carga
      if (mounted) {
        Navigator.pop(context);
      }

      // Compartir el archivo PDF
      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(file.path)]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF generado y compartido exitosamente',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al generar PDF: ${e.toString()}',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  pw.Widget _buildPDFSection(String title, String content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 15),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          content,
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}