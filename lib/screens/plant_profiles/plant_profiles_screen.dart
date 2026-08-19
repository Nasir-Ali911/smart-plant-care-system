import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../../services/plant_service.dart';
import '../../models/plant_model.dart';
import '../add_plant/add_plant_screen.dart';

// Change this path if PlantCard is stored somewhere else.
import '../../widgets/plant_card.dart';

class PlantProfilesScreen extends StatefulWidget {
  const PlantProfilesScreen({Key? key}) : super(key: key);

  @override
  State<PlantProfilesScreen> createState() =>
      _PlantProfilesScreenState();
}

class _PlantProfilesScreenState
    extends State<PlantProfilesScreen> {
  final PlantService _plantService = PlantService();

  String _searchQuery = '';
  String _selectedCategory = 'All';

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================

  Future<void> _confirmDeletePlant(
    BuildContext context,
    PlantModel plant,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Delete Plant?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B3A2B),
            ),
          ),
          content: Text(
            'Are you sure you want to delete '
            '"${plant.name}"?\n\n'
            'This action cannot be undone.',
            style: const TextStyle(
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF1B3A2B),
                ),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    // User pressed Cancel.
    if (confirmed != true) {
      return;
    }

    // ==========================================================
    // DELETE FROM FIREBASE
    // ==========================================================

    try {
      await _plantService.deletePlant(plant.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${plant.name} deleted successfully.',
          ),
          backgroundColor: const Color(0xFF1B3A2B),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete ${plant.name}.',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );

      debugPrint(
        'DELETE PLANT ERROR: $e',
      );
    }
  }

  // ============================================================
  // ADD PLANT
  // ============================================================

  void _openAddPlantScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddPlantScreen(),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0EA),

      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ====================================================
            // HEADER
            // ====================================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [

                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'My Plants',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B3A2B),
                        ),
                      ),

                      SizedBox(height: 2),

                      Text(
                        'Manage all your smart plants.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),

                  Row(
                    children: [

                      IconButton(
                        tooltip: 'Search',
                        icon: const Icon(
                          Icons.search,
                          color: Color(0xFF1B3A2B),
                        ),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                        },
                      ),

                      IconButton(
                        tooltip: 'Add Plant',
                        icon: const Icon(
                          Icons.add,
                          color: Color(0xFF1B3A2B),
                        ),
                        onPressed: _openAddPlantScreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ====================================================
            // SEARCH BAR
            // ====================================================

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery =
                        value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search plants...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.grey,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // ====================================================
            // CATEGORY CHIPS
            // ====================================================

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  'All',
                  'Indoor',
                  'Outdoor',
                  'Vegetables',
                  'Flowers',
                ].map((category) {
                  final bool isSelected =
                      _selectedCategory == category;

                  return Padding(
                    padding:
                        const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      selectedColor:
                          const Color(0xFF1B3A2B),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (!selected) return;

                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // ====================================================
            // FIREBASE PLANTS
            // ====================================================

            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _plantService.getPlantsStream(),

                builder: (context, snapshot) {
                  // ------------------------------------------------
                  // LOADING
                  // ------------------------------------------------

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1B3A2B),
                      ),
                    );
                  }

                  // ------------------------------------------------
                  // ERROR
                  // ------------------------------------------------

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(20),
                        child: Text(
                          'Error loading plants:\n'
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    );
                  }

                  // ------------------------------------------------
                  // SNAPSHOT
                  // ------------------------------------------------

                  final DataSnapshot?
                      dataSnapshot =
                      snapshot.data?.snapshot;

                  if (dataSnapshot == null ||
                      !dataSnapshot.exists ||
                      dataSnapshot.value == null) {
                    return const Center(
                      child: Padding(
                        padding:
                            EdgeInsets.all(20),
                        child: Text(
                          'No plants added yet.\n'
                          'Tap + to add your first plant!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    );
                  }

                  // ------------------------------------------------
                  // CONVERT FIREBASE DATA
                  // TO PLANT MODEL
                  // ------------------------------------------------

                  final Map<dynamic, dynamic>
                      plantsMap =
                      Map<dynamic, dynamic>.from(
                    dataSnapshot.value
                        as Map<dynamic, dynamic>,
                  );

                  final List<PlantModel> plants = [];

                  plantsMap.forEach(
                    (key, value) {
                      if (value is Map) {
                        final plant =
                            PlantModel.fromMap(
                          key.toString(),
                          value,
                        );

                        plants.add(plant);

                        debugPrint(
                          '====================================',
                        );
                        debugPrint(
                          'PLANT NAME: ${plant.name}',
                        );
                        debugPrint(
                          'PLANT ID: ${plant.id}',
                        );
                        debugPrint(
                          'IMAGE URL: ${plant.imageUrl}',
                        );
                        debugPrint(
                          '====================================',
                        );
                      }
                    },
                  );

                  // =================================================
                  // SEARCH FILTER
                  // =================================================

                  final List<PlantModel>
                      filteredPlants =
                      plants.where((plant) {
                    final String name =
                        plant.name.toLowerCase();

                    final String species =
                        plant.species.toLowerCase();

                    final String location =
                        plant.location.toLowerCase();

                    final bool matchesSearch =
                        name.contains(
                              _searchQuery,
                            ) ||
                            species.contains(
                              _searchQuery,
                            ) ||
                            location.contains(
                              _searchQuery,
                            );

                    // ------------------------------------------------
                    // CATEGORY FILTER
                    // ------------------------------------------------
                    //
                    // Currently your Firebase PlantService does not
                    // save a dedicated "category" field.
                    //
                    // Therefore we only apply category filtering
                    // when a suitable value exists in the plant data.
                    //
                    // For now, "All" displays everything.
                    //
                    // The remaining category chips are kept in the UI
                    // for your future category implementation.
                    // ------------------------------------------------

                    bool matchesCategory = true;

                    if (_selectedCategory != 'All') {
                      matchesCategory =
                          location ==
                              _selectedCategory
                                  .toLowerCase() ||
                          species.contains(
                            _selectedCategory
                                .toLowerCase(),
                          );
                    }

                    return matchesSearch &&
                        matchesCategory;
                  }).toList();

                  // ------------------------------------------------
                  // NO MATCHES
                  // ------------------------------------------------

                  if (filteredPlants.isEmpty) {
                    return const Center(
                      child: Text(
                        'No matching plants found.',
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),
                    );
                  }

                  // =================================================
                  // PLANT LIST
                  // =================================================

                  return ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 20.0,
                    ),
                    itemCount:
                        filteredPlants.length,
                    itemBuilder:
                        (context, index) {
                      final PlantModel plant =
                          filteredPlants[index];

                      return PlantCard(
                        plant: plant,

                        // ------------------------------------------------
                        // CARD TAP
                        // ------------------------------------------------

                        onTap: () {
                          // We can connect this to the plant details /
                          // edit screen next.
                          debugPrint(
                            'Selected plant: ${plant.name}',
                          );
                        },

                        // ------------------------------------------------
                        // DELETE
                        // ------------------------------------------------

                        onDelete: () {
                          _confirmDeletePlant(
                            context,
                            plant,
                          );
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

      // ============================================================
      // FLOATING ADD BUTTON
      // ============================================================

      floatingActionButton:
          FloatingActionButton(
        backgroundColor:
            const Color(0xFF1B3A2B),

        tooltip: 'Add Plant',

        onPressed: _openAddPlantScreen,

        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}