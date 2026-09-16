import 'package:flutter/material.dart';
import '../../core/models/vehicle.dart';
import '../theme/colors.dart';

/// Selector de tipo de vehículo (carro / moto) en dos tarjetas.
class VehicleTypeSelector extends StatelessWidget {
  final VehicleType selected;
  final ValueChanged<VehicleType> onChanged;
  final double height;

  const VehicleTypeSelector({super.key, required this.selected, required this.onChanged, this.height = 68});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: VehicleType.values.map((tipo) {
        final seleccionado = tipo == selected;
        final icon = tipo == VehicleType.carro ? Icons.directions_car_rounded : Icons.two_wheeler_rounded;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: tipo != VehicleType.values.last ? 10 : 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: height,
              decoration: BoxDecoration(
                gradient: seleccionado ? AppColors.primaryGradient : null,
                color: seleccionado ? null : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: seleccionado ? null : Border.all(color: AppColors.border, width: 1.5),
                boxShadow: seleccionado ? AppColors.primaryShadow : null,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onChanged(tipo),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 24, color: seleccionado ? Colors.white : AppColors.textSecondary),
                      const SizedBox(height: 4),
                      Text(
                        tipo.label,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: seleccionado ? Colors.white : AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
