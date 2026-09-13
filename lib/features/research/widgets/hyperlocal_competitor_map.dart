import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mappls_gl/mappls_gl.dart';
import '../../../core/maps/mappls_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../models/competitor_poi.dart';

/// Interactive Hyperlocal Competitor Map widget.
/// On Android/iOS hardware with Mappls licenses: renders hardware-accelerated Mappls GL map.
/// On desktop or test environments: renders an interactive tactile radar map with live selection.
class HyperlocalCompetitorMap extends StatefulWidget {
  final List<CompetitorPoi> competitors;
  final LatLng center;
  final CompetitorPoi? selectedCompetitor;
  final ValueChanged<CompetitorPoi>? onCompetitorSelected;
  final double height;
  final double radiusKm;

  const HyperlocalCompetitorMap({
    super.key,
    required this.competitors,
    this.center = MapplsService.defaultCenter,
    this.selectedCompetitor,
    this.onCompetitorSelected,
    this.height = 360,
    this.radiusKm = 5.0,
  });

  @override
  State<HyperlocalCompetitorMap> createState() => _HyperlocalCompetitorMapState();
}

class _HyperlocalCompetitorMapState extends State<HyperlocalCompetitorMap> {
  MapplsMapController? _mapController;
  final Map<String, CompetitorPoi> _circleToPoi = {};

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Map Display
          MapplsService.isNativeMapSupported
              ? _buildMapplsNativeMap()
              : _buildTactileInteractiveMap(),

          // Compass / Map Overlay Badge
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.explore_rounded, size: 14, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Text(
                    'Mappls Hyperlocal • ${widget.radiusKm.toStringAsFixed(0)} km Radius',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Legend at bottom-left
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _legendDot(AppColors.tertiary, 'Your Site'),
                  const SizedBox(width: 10),
                  _legendDot(AppColors.secondary, 'Competitor'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMapplsNativeMap() {
    return MapplsMap(
      initialCameraPosition: CameraPosition(
        target: widget.center,
        zoom: 12.5,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        controller.onCircleTapped.add(_handleCircleTapped);
      },
      onStyleLoadedCallback: _populateMapMarkers,
      compassEnabled: true,
      myLocationEnabled: false,
    );
  }

  void _populateMapMarkers() async {
    final controller = _mapController;
    if (controller == null) return;

    try {
      await controller.clearCircles();
      _circleToPoi.clear();

      // 1. Add User's Business Location (Green Center Circle)
      await controller.addCircle(
        CircleOptions(
          geometry: widget.center,
          circleColor: '#166534',
          circleRadius: 11.0,
          circleStrokeWidth: 3.0,
          circleStrokeColor: '#FFFFFF',
          circleOpacity: 0.95,
        ),
      );

      // 2. Add Competitor Pins
      for (final comp in widget.competitors) {
        final circle = await controller.addCircle(
          CircleOptions(
            geometry: LatLng(comp.latitude, comp.longitude),
            circleColor: comp.id == widget.selectedCompetitor?.id ? '#BA1A1A' : '#E65100',
            circleRadius: comp.id == widget.selectedCompetitor?.id ? 11.0 : 8.5,
            circleStrokeWidth: 2.5,
            circleStrokeColor: '#FFFFFF',
            circleOpacity: 0.9,
          ),
        );
        _circleToPoi[circle.id] = comp;
      }
    } catch (e) {
      debugPrint('[MapplsNativeMap] Error plotting circles: $e');
    }
  }

  void _handleCircleTapped(Circle circle) {
    final comp = _circleToPoi[circle.id];
    if (comp != null && widget.onCompetitorSelected != null) {
      widget.onCompetitorSelected!(comp);
    }
  }

  Widget _buildTactileInteractiveMap() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final centerOffset = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
        final maxVisualRadius = math.min(constraints.maxWidth, constraints.maxHeight) * 0.42;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _TactileRadarPainter(
              competitors: widget.competitors,
              centerLat: widget.center.latitude,
              centerLon: widget.center.longitude,
              radiusKm: widget.radiusKm,
              selectedCompetitor: widget.selectedCompetitor,
            ),
            child: Stack(
              children: [
                // Center Point Marker (Entrepreneur's planned unit)
                Positioned(
                  left: centerOffset.dx - 14,
                  top: centerOffset.dy - 14,
                  child: Tooltip(
                    message: 'Your Planned Enterprise Location',
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.tertiary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: const [
                          BoxShadow(color: Colors.black38, blurRadius: 6),
                        ],
                      ),
                      child: const Icon(Icons.business_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ),

                // Competitor Interactive Tappable Pins
                ...widget.competitors.map((comp) {
                  final offset = _calculateScreenOffset(
                    comp: comp,
                    centerOffset: centerOffset,
                    maxVisualRadius: maxVisualRadius,
                  );
                  final isSelected = comp.id == widget.selectedCompetitor?.id;

                  return Positioned(
                    left: offset.dx - 16,
                    top: offset.dy - 16,
                    child: GestureDetector(
                      onTap: () {
                        if (widget.onCompetitorSelected != null) {
                          widget.onCompetitorSelected!(comp);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isSelected ? 34 : 28,
                        height: isSelected ? 34 : 28,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.error : AppColors.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: isSelected ? 2.5 : 2.0),
                          boxShadow: [
                            BoxShadow(
                              color: (isSelected ? AppColors.error : AppColors.secondary).withValues(alpha: 0.4),
                              blurRadius: isSelected ? 8 : 4,
                              spreadRadius: isSelected ? 2 : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: isSelected ? 18 : 14,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Offset _calculateScreenOffset({
    required CompetitorPoi comp,
    required Offset centerOffset,
    required double maxVisualRadius,
  }) {
    final latDiff = comp.latitude - widget.center.latitude;
    final lonDiff = comp.longitude - widget.center.longitude;

    // Relative angle and distance ratio
    final angle = math.atan2(latDiff, lonDiff);
    final ratio = (comp.distanceKm / widget.radiusKm).clamp(0.15, 0.95);
    final distancePx = ratio * maxVisualRadius;

    final dx = centerOffset.dx + distancePx * math.cos(angle);
    final dy = centerOffset.dy - distancePx * math.sin(angle); // Invert Y for screen coordinates
    return Offset(dx, dy);
  }
}

class _TactileRadarPainter extends CustomPainter {
  final List<CompetitorPoi> competitors;
  final double centerLat;
  final double centerLon;
  final double radiusKm;
  final CompetitorPoi? selectedCompetitor;

  _TactileRadarPainter({
    required this.competitors,
    required this.centerLat,
    required this.centerLon,
    required this.radiusKm,
    this.selectedCompetitor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxVisualRadius = math.min(size.width, size.height) * 0.42;

    // Background Canvas
    final bgPaint = Paint()..color = const Color(0xFFF7F3EB);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle Grid Lines
    final gridPaint = Paint()
      ..color = const Color(0xFFE8E0D2)
      ..strokeWidth = 1.0;
    for (double x = 0; x < size.width; x += 36) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 36) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Range Rings
    final ringPaint = Paint()
      ..color = const Color(0xFFD6C8B4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final ringFills = [0.33, 0.66, 1.0];
    final labels = ['${(radiusKm * 0.33).toStringAsFixed(1)} km', '${(radiusKm * 0.66).toStringAsFixed(1)} km', '${radiusKm.toStringAsFixed(0)} km'];

    for (int i = 0; i < ringFills.length; i++) {
      final r = maxVisualRadius * ringFills[i];
      canvas.drawCircle(center, r, ringPaint);

      // Draw Range Label
      final textSpan = TextSpan(
        text: labels[i],
        style: const TextStyle(
          color: Color(0xFF8C8275),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(center.dx + 4, center.dy - r + 3));
    }
  }

  @override
  bool shouldRepaint(covariant _TactileRadarPainter oldDelegate) {
    return oldDelegate.selectedCompetitor != selectedCompetitor ||
        oldDelegate.radiusKm != radiusKm ||
        oldDelegate.competitors.length != competitors.length;
  }
}
