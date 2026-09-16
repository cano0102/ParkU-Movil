import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/text_styles.dart';
import '../../../../app/widgets/widgets.dart';
import '../../../../core/data/parking_repository.dart';
import '../../../../core/network/api_exception.dart';

/// Tipos de novedad que admite Api-ParkU (ver novedades.controller.js).
/// QUEJA es el que usa el conductor para reportar una inconformidad; el
/// resto los usa también portería desde el mapa/escaneo.
enum TipoNovedadUi { queja, danio, malEstacionamiento, accidente, otro }

extension _TipoNovedadUiX on TipoNovedadUi {
  String get apiValue {
    switch (this) {
      case TipoNovedadUi.queja:
        return 'QUEJA';
      case TipoNovedadUi.danio:
        return 'DANIO';
      case TipoNovedadUi.malEstacionamiento:
        return 'MAL_ESTACIONAMIENTO';
      case TipoNovedadUi.accidente:
        return 'ACCIDENTE';
      case TipoNovedadUi.otro:
        return 'OTRO';
    }
  }

  String get label {
    switch (this) {
      case TipoNovedadUi.queja:
        return 'Queja';
      case TipoNovedadUi.danio:
        return 'Daño';
      case TipoNovedadUi.malEstacionamiento:
        return 'Mal estacionamiento';
      case TipoNovedadUi.accidente:
        return 'Accidente';
      case TipoNovedadUi.otro:
        return 'Otro';
    }
  }
}

/// Formulario para reportar una novedad/incidente/queja (Epic 07.1 y
/// alcance móvil "usuarios: consultas y quejas"). Se reutiliza tanto desde
/// portería (con el contexto de una celda o un vehículo escaneado) como
/// desde el conductor (queja general o sobre su propio vehículo).
class ReportIncidentPage extends StatefulWidget {
  final TipoNovedadUi tipoInicial;
  final String? placaContexto;
  final String? celdaContexto;
  final int? vehiculoId;
  final int? celdaId;

  const ReportIncidentPage({
    super.key,
    this.tipoInicial = TipoNovedadUi.otro,
    this.placaContexto,
    this.celdaContexto,
    this.vehiculoId,
    this.celdaId,
  });

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  late TipoNovedadUi _tipo = widget.tipoInicial;
  bool _enviando = false;

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);
    try {
      await ParkingRepository.instance.reportarNovedad(
        tipoNovedad: _tipo.apiValue,
        descripcion: _descripcionController.text.trim(),
        vehiculoId: widget.vehiculoId,
        celdaId: widget.celdaId,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte enviado. El equipo de vigilancia lo revisará pronto.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tieneContexto = widget.placaContexto != null || widget.celdaContexto != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IconBadge(icon: Icons.report_gmailerrorred_rounded, size: 52, iconSize: 26, color: AppColors.dangerDarker, background: AppColors.dangerSoft),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NUEVO REPORTE', style: AppTextStyles.overline.copyWith(color: AppColors.dangerDarker, fontSize: 11)),
                        const SizedBox(height: 4),
                        Text('Reportar novedad', style: AppTextStyles.heading3),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 16),
              if (tieneContexto) ...[
                AppCard(
                  color: AppColors.neutralSoft,
                  elevated: false,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          [
                            if (widget.placaContexto != null) 'Placa ${widget.placaContexto}',
                            if (widget.celdaContexto != null) 'Celda ${widget.celdaContexto}',
                          ].join(' · '),
                          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
              Text('Tipo de novedad *', style: AppTextStyles.bodyBold.copyWith(fontSize: 13.5)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tipo in TipoNovedadUi.values)
                    ChoiceChip(
                      label: Text(tipo.label),
                      selected: _tipo == tipo,
                      onSelected: (_) => setState(() => _tipo = tipo),
                      selectedColor: AppColors.primarySoft,
                      labelStyle: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _tipo == tipo ? AppColors.primaryDark : AppColors.textSecondary,
                      ),
                      backgroundColor: AppColors.surface,
                      side: BorderSide(color: _tipo == tipo ? AppColors.primarySoftBorder : AppColors.divider),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text('Descripción *', style: AppTextStyles.bodyBold.copyWith(fontSize: 13.5)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descripcionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Describe lo sucedido con el mayor detalle posible...',
                  hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textPlaceholder),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 10) return 'Describe con al menos 10 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancelar', style: AppTextStyles.bodyBold.copyWith(color: AppColors.textPrimary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _enviando ? null : _enviar,
                      icon: _enviando
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                          : const Icon(Icons.send_rounded, size: 18),
                      label: Text(_enviando ? 'Enviando...' : 'Enviar reporte'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
