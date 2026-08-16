import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_plant_care/models/plant_model.dart';
import 'package:smart_plant_care/screens/plants/widgets/plant_card.dart';
import 'package:smart_plant_care/screens/plants/widgets/plant_search_bar.dart';
import 'package:smart_plant_care/screens/plants/widgets/filter_chip.dart';
import 'package:smart_plant_care/screens/plants/widgets/empty_state.dart';
import 'package:smart_plant_care/screens/plant_details/plant_details_screen.dart';
import 'package:smart_plant_care/screens/add_plant/add_plant_screen.dart';
import 'package:smart_plant_care/services/plant_service.dart';

class PlantsScreen extends StatefulWidget {
  const PlantsScreen({super.key});

  @override
  State<PlantsScreen> createState() => _PlantsScreenState();
}

class _PlantsScreenState extends State<PlantsScreen> {
  int _selectedFilterIndex = 0;

  String _searchQuery = '';

  final List<String> _filters = [
    'All',
    'Indoor',
    'Outdoor',
    'Vegetables',
    'Flowers',
  ];

  final PlantService _plantService = PlantService();

  // ---------------------------------------------------------
  // DELETE CONFIRMATION
  // ---------------------------------------------------------

  Future<void> _confirmDelete(PlantModel plant) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Delete Plant?',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF134E39),
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${plant.name}"?',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF134E39),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _plantService.deletePlant(plant.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${plant.name} deleted successfully.',
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF134E39),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete plant: $e',
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ---------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4EDE6),

      // -----------------------------------------------------
      // APP BAR
      // -----------------------------------------------------

      appBar: AppBar(
        backgroundColor: const Color(0xFFE4EDE6),
        elevation: 0,
        automaticallyImplyLeading: false,

        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Plants',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF134E39),
              ),
            ),
            Text(
              'Manage all your smart plants.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5A7865),
              ),
            ),
          ],
        ),

        // IMPORTANT:
        // No search icon and no add icon here.
        actions: const [],
      ),

      // -----------------------------------------------------
      // BODY
      // -----------------------------------------------------

      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 12.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------
            // SEARCH BAR
            // -------------------------------------------------

            PlantSearchBar(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim().toLowerCase();
                });
              },
            ),

            const SizedBox(height: 16),

            // -------------------------------------------------
            // FILTER CHIPS
            // -------------------------------------------------

            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  return PlantFilterChip(
                    label: _filters[index],
                    isSelected:
                        _selectedFilterIndex == index,
                    onTap: () {
                      setState(() {
                        _selectedFilterIndex = index;
                      });
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // -------------------------------------------------
            // FIREBASE PLANT LIST
            // -------------------------------------------------

            Expanded(
              child: StreamBuilder(
                stream: _plantService.getPlantsStream(),

                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading plants:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.red,
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF134E39),
                      ),
                    );
                  }

                  final dataSnapshot =
                      snapshot.data?.snapshot;

                  if (dataSnapshot == null ||
                      !dataSnapshot.exists ||
                      dataSnapshot.value == null) {
                    return const PlantEmptyState();
                  }

                  final rawData = dataSnapshot.value;

                  if (rawData is! Map) {
                    return const Center(
                      child: Text(
                        'Invalid plant data received.',
                      ),
                    );
                  }

                  // Convert Firebase data to PlantModel
                  final List<PlantModel> plants = [];

                  rawData.forEach((key, value) {
                    if (value is Map) {
                      try {
                        final plant = PlantModel.fromMap(
                          key.toString(),
                          Map<dynamic, dynamic>.from(value),
                        );

                        plants.add(plant);
                      } catch (e) {
                        debugPrint(
                          'Error converting plant $key: $e',
                        );
                      }
                    }
                  });

                  // -------------------------------------------------
                  // SEARCH FILTER
                  // -------------------------------------------------

                  List<PlantModel> filteredPlants =
                      plants.where((plant) {
                    if (_searchQuery.isEmpty) {
                      return true;
                    }

                    final name =
                        plant.name.toLowerCase();

                    final species =
                        plant.species.toLowerCase();

                    final location =
                        plant.location.toLowerCase();

                    return name.contains(_searchQuery) ||
                        species.contains(_searchQuery) ||
                        location.contains(_searchQuery);
                  }).toList();

                  // -------------------------------------------------
                  // CATEGORY FILTER
                  // -------------------------------------------------

                  if (_selectedFilterIndex != 0) {
                    final selectedFilter =
                        _filters[_selectedFilterIndex]
                            .toLowerCase();

                    filteredPlants =
                        filteredPlants.where((plant) {
                      final category =
                          plant.status.toLowerCase();

                      if (selectedFilter == 'vegetables') {
                        return category == 'vegetable' ||
                            category == 'vegetables';
                      }

                      if (selectedFilter == 'flowers') {
                        return category == 'flower' ||
                            category == 'flowers';
                      }

                      return category == selectedFilter;
                    }).toList();
                  }

                  // -------------------------------------------------
                  // NO SEARCH/FILTER RESULTS
                  // -------------------------------------------------

                  if (filteredPlants.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? 'No plants match your search.'
                            : 'No plants found.',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF5A7865),
                        ),
                      ),
                    );
                  }

                  // -------------------------------------------------
                  // PLANT CARDS
                  // -------------------------------------------------

                  return ListView.builder(
                    itemCount: filteredPlants.length,
                    itemBuilder: (context, index) {
                      final plant =
                          filteredPlants[index];

                      return PlantCard(
                        plant: plant,

                        // Open plant details
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PlantDetailsScreen(
                                plant: plant,
                              ),
                            ),
                          );
                        },

                        // Delete plant
                        onDelete: () {
                          _confirmDelete(plant);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // -------------------------------------------------------
      // SINGLE ADD PLANT BUTTON
      // -------------------------------------------------------

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF134E39),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const AddPlantScreen(),
            ),
          );
        },
      ),
    );
  }
}