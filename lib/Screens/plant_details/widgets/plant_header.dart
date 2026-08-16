import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_plant_care/models/plant_model.dart';

class PlantHeader extends StatelessWidget {
  final PlantModel plant;

  const PlantHeader({
    super.key,
    required this.plant,
  });

  @override
  Widget build(BuildContext context) {
    final String imageUrl =
        plant.imageUrl.trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // =====================================================
          // PLANT IMAGE
          // =====================================================

          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80,
              height: 80,
              color: const Color(0xFFD0E2D4),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,

                      // ------------------------------------------------
                      // IMAGE LOADING
                      // ------------------------------------------------

                      loadingBuilder:
                          (
                        context,
                        child,
                        loadingProgress,
                      ) {
                        if (loadingProgress == null) {
                          return child;
                        }

                        return const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF134E39),
                            ),
                          ),
                        );
                      },

                      // ------------------------------------------------
                      // IMAGE ERROR
                      // ------------------------------------------------

                      errorBuilder:
                          (
                        context,
                        error,
                        stackTrace,
                      ) {
                        debugPrint(
                          'PlantHeader image failed: $error',
                        );

                        return const Center(
                          child: Icon(
                            Icons.eco_outlined,
                            size: 40,
                            color: Color(0xFF134E39),
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(
                        Icons.eco_outlined,
                        size: 40,
                        color: Color(0xFF134E39),
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 16),

          // =====================================================
          // PLANT DETAILS
          // =====================================================

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // -------------------------------------------------
                // LOCATION + HEALTH STATUS
                // -------------------------------------------------

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // Location Badge
                    Flexible(
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(0xFFE8F0EC),
                          borderRadius:
                              BorderRadius.circular(6),
                        ),
                        child: Text(
                          plant.location.isNotEmpty
                              ? plant.location
                              : 'Unknown',
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w500,
                            color:
                                const Color(0xFF134E39),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Health Status Badge
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(0xFFD4EDDA),
                        borderRadius:
                            BorderRadius.circular(6),
                      ),
                      child: Text(
                        plant.status.isNotEmpty
                            ? plant.status
                            : 'Optimal',
                        style:
                            GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              const Color(0xFF155724),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // -------------------------------------------------
                // SPECIES
                // -------------------------------------------------

                Text(
                  plant.species.isNotEmpty
                      ? plant.species
                      : 'Unknown species',
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      GoogleFonts.poppins(
                    fontSize: 14,
                    fontStyle:
                        FontStyle.italic,
                    color:
                        const Color(0xFF5A7865),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}