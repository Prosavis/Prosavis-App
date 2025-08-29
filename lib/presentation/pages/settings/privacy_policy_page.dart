import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';

import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import '../../../core/themes/app_theme.dart';
import '../../../core/constants/app_constants.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage>
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
                'Política de Privacidad',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _sharePrivacyPolicy(),
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
                    'Esta política describe cómo ${AppConstants.appName} recopila, usa y protege su información personal.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Contenido de política de privacidad
            _buildSection(
              '1. Información que Recopilamos',
              'Recopilamos la siguiente información cuando usa ${AppConstants.appName}:\n\n'
              '• Información de registro: nombre, correo electrónico, número de teléfono\n'
              '• Información de perfil: fotografía, ubicación, preferencias de servicios\n'
              '• Información de uso: interacciones con la aplicación, búsquedas realizadas\n'
              '• Información técnica: dirección IP, tipo de dispositivo, sistema operativo\n'
              '• Información de ubicación: cuando acepta compartir su ubicación para encontrar servicios cercanos',
            ),

            _buildSection(
              '2. Cómo Usamos su Información',
              'Utilizamos su información personal para:\n\n'
              '• Proporcionar y mejorar nuestros servicios de conexión entre usuarios y proveedores\n'
              '• Facilitar la comunicación entre clientes y proveedores de servicios\n'
              '• Personalizar su experiencia en la aplicación\n'
              '• Enviar notificaciones importantes sobre su cuenta y servicios\n'
              '• Cumplir con obligaciones legales y prevenir fraudes\n'
              '• Realizar análisis para mejorar la funcionalidad de la plataforma',
            ),

            _buildSection(
              '3. Compartir Información',
              '${AppConstants.appName} no vende, alquila ni comparte su información personal con terceros, excepto en los siguientes casos:\n\n'
              '• Con proveedores de servicios que usted elige contactar a través de nuestra plataforma\n'
              '• Con prestadores de servicios técnicos que nos ayudan a operar la plataforma (bajo estrictos acuerdos de confidencialidad)\n'
              '• Cuando sea requerido por ley o para proteger nuestros derechos legales\n'
              '• En caso de fusión, adquisición o venta de activos (con notificación previa)',
            ),

            _buildSection(
              '4. Protección de Datos',
              'Implementamos medidas de seguridad técnicas y organizativas para proteger su información:\n\n'
              '• Cifrado de datos en tránsito y en reposo\n'
              '• Acceso restringido a información personal solo a personal autorizado\n'
              '• Monitoreo regular de sistemas para detectar vulnerabilidades\n'
              '• Respaldo seguro de datos en servidores protegidos\n'
              '• Auditorías periódicas de seguridad',
            ),

            _buildSection(
              '5. Sus Derechos',
              'Usted tiene los siguientes derechos sobre su información personal:\n\n'
              '• Acceso: solicitar una copia de la información que tenemos sobre usted\n'
              '• Rectificación: corregir información inexacta o incompleta\n'
              '• Eliminación: solicitar la eliminación de su información personal\n'
              '• Portabilidad: recibir sus datos en un formato estructurado\n'
              '• Oposición: oponerse al procesamiento de sus datos para ciertos fines\n'
              '• Limitación: solicitar la restricción del procesamiento de sus datos',
            ),

            _buildSection(
              '6. Cookies y Tecnologías Similares',
              'Utilizamos cookies y tecnologías similares para:\n\n'
              '• Mantener su sesión activa en la aplicación\n'
              '• Recordar sus preferencias y configuraciones\n'
              '• Analizar el uso de la aplicación para mejoras\n'
              '• Proporcionar funcionalidades personalizadas\n\n'
              'Puede gestionar las cookies a través de la configuración de su dispositivo o navegador.',
            ),

            _buildSection(
              '7. Retención de Datos',
              'Conservamos su información personal durante el tiempo necesario para:\n\n'
              '• Proporcionar nuestros servicios mientras mantenga una cuenta activa\n'
              '• Cumplir con obligaciones legales (típicamente 5 años después de la inactividad)\n'
              '• Resolver disputas y hacer cumplir nuestros acuerdos\n'
              '• Prevenir fraudes y abusos de la plataforma\n\n'
              'Puede solicitar la eliminación de sus datos en cualquier momento contactándonos.',
            ),

            _buildSection(
              '8. Transferencias Internacionales',
              'Su información puede ser transferida y procesada en países fuera de Colombia. En estos casos:\n\n'
              '• Garantizamos que se mantengan estándares adecuados de protección de datos\n'
              '• Utilizamos cláusulas contractuales estándar aprobadas por autoridades de protección de datos\n'
              '• Solo transferimos datos a países con niveles adecuados de protección\n'
              '• Le notificaremos sobre cualquier transferencia significativa de datos',
            ),

            _buildSection(
              '9. Menores de Edad',
              '${AppConstants.appName} no está dirigido a menores de 18 años:\n\n'
              '• No recopilamos intencionalmente información de menores de 18 años\n'
              '• Si descubrimos que hemos recopilado información de un menor, la eliminaremos inmediatamente\n'
              '• Los padres o tutores pueden contactarnos para solicitar la eliminación de información de menores\n'
              '• Requerimos verificación de edad durante el registro',
            ),

            _buildSection(
              '10. Cambios en esta Política',
              'Podemos actualizar esta Política de Privacidad ocasionalmente:\n\n'
              '• Le notificaremos sobre cambios significativos a través de la aplicación o por correo electrónico\n'
              '• Los cambios entrarán en vigor 30 días después de la notificación\n'
              '• Su uso continuado de la aplicación constituye aceptación de los cambios\n'
              '• Mantendremos versiones anteriores disponibles para su revisión',
            ),

            _buildSection(
              '11. Base Legal para el Procesamiento',
              'Procesamos su información personal basándose en:\n\n'
              '• Consentimiento: cuando usted nos da permiso explícito\n'
              '• Ejecución de contrato: para proporcionar los servicios solicitados\n'
              '• Interés legítimo: para mejorar nuestros servicios y prevenir fraudes\n'
              '• Obligación legal: para cumplir con requisitos legales aplicables\n\n'
              'Puede retirar su consentimiento en cualquier momento cuando sea la base legal del procesamiento.',
            ),

            _buildSection(
              '12. Contacto',
              'Para preguntas sobre esta Política de Privacidad o ejercer sus derechos, contáctenos:\n\n'
              '• Correo electrónico: privacidad@prosavis.com\n'
              '• Teléfono: +57 (1) 234-5678\n'
              '• Dirección: Carrera 7 #123-45, Bogotá, Colombia\n'
              '• A través de los canales de soporte en la aplicación\n\n'
              'Responderemos a su solicitud dentro de 30 días hábiles.',
            ),

            const SizedBox(height: 32),

            // Acciones adicionales
            Column(
              children: [
                _buildActionButton(
                  icon: Symbols.description,
                  title: 'Términos y Condiciones',
                  onTap: () => context.pop(),
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

  void _sharePrivacyPolicy() async {
    try {
      const String shareText = '''
Política de Privacidad - ${AppConstants.appName}

En ${AppConstants.appName} protegemos su privacidad y datos personales.

Esta política describe cómo recopilamos, usamos y protegemos su información personal cuando utiliza nuestra plataforma de servicios.

📱 Para ver la política completa, descarga nuestra aplicación.
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

  void _contactSupport() {
    context.push('/support');
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
                  'Política de Privacidad',
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
                text: 'Esta política describe cómo ${AppConstants.appName} recopila, usa y protege su información personal.',
                style: const pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 20),
              
              // Contenido de la política de privacidad
              _buildPDFSection('1. Información que Recopilamos',
                'Recopilamos la siguiente información cuando usa ${AppConstants.appName}:\n\n• Información de registro: nombre, correo electrónico, número de teléfono\n• Información de perfil: fotografía, ubicación, preferencias de servicios\n• Información de uso: interacciones con la aplicación, búsquedas realizadas\n• Información técnica: dirección IP, tipo de dispositivo, sistema operativo\n• Información de ubicación: cuando acepta compartir su ubicación para encontrar servicios cercanos'),
              
              _buildPDFSection('2. Cómo Usamos su Información',
                'Utilizamos su información personal para:\n\n• Proporcionar y mejorar nuestros servicios de conexión entre usuarios y proveedores\n• Facilitar la comunicación entre clientes y proveedores de servicios\n• Personalizar su experiencia en la aplicación\n• Enviar notificaciones importantes sobre su cuenta y servicios\n• Cumplir con obligaciones legales y prevenir fraudes\n• Realizar análisis para mejorar la funcionalidad de la plataforma'),
              
              _buildPDFSection('3. Compartir Información',
                '${AppConstants.appName} no vende, alquila ni comparte su información personal con terceros, excepto en los siguientes casos:\n\n• Con proveedores de servicios que usted elige contactar a través de nuestra plataforma\n• Con prestadores de servicios técnicos que nos ayudan a operar la plataforma (bajo estrictos acuerdos de confidencialidad)\n• Cuando sea requerido por ley o para proteger nuestros derechos legales\n• En caso de fusión, adquisición o venta de activos (con notificación previa)'),
              
              _buildPDFSection('4. Protección de Datos',
                'Implementamos medidas de seguridad técnicas y organizativas para proteger su información:\n\n• Cifrado de datos en tránsito y en reposo\n• Acceso restringido a información personal solo a personal autorizado\n• Monitoreo regular de sistemas para detectar vulnerabilidades\n• Respaldo seguro de datos en servidores protegidos\n• Auditorías periódicas de seguridad'),
              
              _buildPDFSection('5. Sus Derechos',
                'Usted tiene los siguientes derechos sobre su información personal:\n\n• Acceso: solicitar una copia de la información que tenemos sobre usted\n• Rectificación: corregir información inexacta o incompleta\n• Eliminación: solicitar la eliminación de su información personal\n• Portabilidad: recibir sus datos en un formato estructurado\n• Oposición: oponerse al procesamiento de sus datos para ciertos fines\n• Limitación: solicitar la restricción del procesamiento de sus datos'),
              
              _buildPDFSection('6. Cookies y Tecnologías Similares',
                'Utilizamos cookies y tecnologías similares para:\n\n• Mantener su sesión activa en la aplicación\n• Recordar sus preferencias y configuraciones\n• Analizar el uso de la aplicación para mejoras\n• Proporcionar funcionalidades personalizadas\n\nPuede gestionar las cookies a través de la configuración de su dispositivo o navegador.'),
              
              _buildPDFSection('7. Retención de Datos',
                'Conservamos su información personal durante el tiempo necesario para:\n\n• Proporcionar nuestros servicios mientras mantenga una cuenta activa\n• Cumplir con obligaciones legales (típicamente 5 años después de la inactividad)\n• Resolver disputas y hacer cumplir nuestros acuerdos\n• Prevenir fraudes y abusos de la plataforma\n\nPuede solicitar la eliminación de sus datos en cualquier momento contactándonos.'),
              
              _buildPDFSection('8. Transferencias Internacionales',
                'Su información puede ser transferida y procesada en países fuera de Colombia. En estos casos:\n\n• Garantizamos que se mantengan estándares adecuados de protección de datos\n• Utilizamos cláusulas contractuales estándar aprobadas por autoridades de protección de datos\n• Solo transferimos datos a países con niveles adecuados de protección\n• Le notificaremos sobre cualquier transferencia significativa de datos'),
              
              _buildPDFSection('9. Menores de Edad',
                '${AppConstants.appName} no está dirigido a menores de 18 años:\n\n• No recopilamos intencionalmente información de menores de 18 años\n• Si descubrimos que hemos recopilado información de un menor, la eliminaremos inmediatamente\n• Los padres o tutores pueden contactarnos para solicitar la eliminación de información de menores\n• Requerimos verificación de edad durante el registro'),
              
              _buildPDFSection('10. Cambios en esta Política',
                'Podemos actualizar esta Política de Privacidad ocasionalmente:\n\n• Le notificaremos sobre cambios significativos a través de la aplicación o por correo electrónico\n• Los cambios entrarán en vigor 30 días después de la notificación\n• Su uso continuado de la aplicación constituye aceptación de los cambios\n• Mantendremos versiones anteriores disponibles para su revisión'),
              
              _buildPDFSection('11. Base Legal para el Procesamiento',
                'Procesamos su información personal basándose en:\n\n• Consentimiento: cuando usted nos da permiso explícito\n• Ejecución de contrato: para proporcionar los servicios solicitados\n• Interés legítimo: para mejorar nuestros servicios y prevenir fraudes\n• Obligación legal: para cumplir con requisitos legales aplicables\n\nPuede retirar su consentimiento en cualquier momento cuando sea la base legal del procesamiento.'),
              
              _buildPDFSection('12. Contacto',
                'Para preguntas sobre esta Política de Privacidad o ejercer sus derechos, contáctenos:\n\n• Correo electrónico: privacidad@prosavis.com\n• Teléfono: +57 (1) 234-5678\n• Dirección: Carrera 7 #123-45, Bogotá, Colombia\n• A través de los canales de soporte en la aplicación\n\nResponderemos a su solicitud dentro de 30 días hábiles.'),
            ];
          },
        ),
      );

      // Obtener directorio de descargas
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/politica_privacidad_${AppConstants.appName}.pdf');
      
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
