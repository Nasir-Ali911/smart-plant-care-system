import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:smart_plant_care/models/plant_model.dart';
import 'package:smart_plant_care/services/plant_service.dart';

class EditPlantScreen extends StatefulWidget {
  final PlantModel plant;

  const EditPlantScreen({
    super.key,
    required this.plant,
  });

  @override
  State<EditPlantScreen> createState() =>
      _EditPlantScreenState();
}

class _EditPlantScreenState extends State<EditPlantScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  late TextEditingController _nameController;
  late TextEditingController _speciesController;
  late TextEditingController _locationController;

  // ============================================================
  // DROPDOWN VALUES
  // ============================================================

  String? _selectedCategory;
  String? _selectedSchedule;

  final List<String> _categories = [
    'Indoor',
    'Outdoor',
    'Vegetable',
    'Flower',
    'Herb',
    'Fruit',
  ];

  final List<String> _schedules = [
    'Daily',
    'Every 2 Days',
    'Weekly',
    'Custom',
  ];

  // ============================================================
  // IMAGE
  // ============================================================

  final ImagePicker _imagePicker = ImagePicker();

  XFile? _selectedImage;

  // True when the user wants to remove the existing Firebase
  // imageUrl.
  bool _removeExistingImage = false;

  // ============================================================
  // SAVING STATE
  // ============================================================

  bool _saving = false;

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.plant.name,
    );

    _speciesController = TextEditingController(
      text: widget.plant.species,
    );

    _locationController = TextEditingController(
      text: widget.plant.location,
    );

    // ----------------------------------------------------------
    // CATEGORY
    // ----------------------------------------------------------

    _selectedCategory =
        _categories.contains(widget.plant.status)
            ? widget.plant.status
            : null;

    // ----------------------------------------------------------
    // WATERING SCHEDULE
    // ----------------------------------------------------------

    _selectedSchedule =
        _schedules.contains(widget.plant.moisture)
            ? widget.plant.moisture
            : null;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _locationController.dispose();

    super.dispose();
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage() async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

      setState(() {
        _selectedImage = image;

        // If a new image is selected, we don't want to
        // delete the imageUrl.
        _removeExistingImage = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not select image: $e',
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ============================================================
  // REMOVE IMAGE
  // ============================================================

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _removeExistingImage = true;
    });
  }

  // ============================================================
  // IMAGE STATUS
  // ============================================================

  bool get _hasExistingImage {
    return widget.plant.imageUrl.trim().isNotEmpty &&
        !_removeExistingImage;
  }

  bool get _hasNewImage {
    return _selectedImage != null;
  }

  // ============================================================
  // IMAGE PREVIEW
  // ============================================================

  Widget _buildImagePreview() {
    // ----------------------------------------------------------
    // NEWLY SELECTED IMAGE
    // ----------------------------------------------------------

    if (_hasNewImage) {
      return Image.file(
        File(_selectedImage!.path),
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
      );
    }

    // ----------------------------------------------------------
    // EXISTING CLOUDINARY IMAGE
    // ----------------------------------------------------------

    if (_hasExistingImage) {
      return Image.network(
        widget.plant.imageUrl,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        loadingBuilder:
            (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return const Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF134E39),
              ),
            ),
          );
        },
        errorBuilder:
            (context, error, stackTrace) {
          debugPrint(
            'Edit screen image failed: $error',
          );

          return const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 55,
              color: Color(0xFF5A7865),
            ),
          );
        },
      );
    }

    // ----------------------------------------------------------
    // NO IMAGE
    // ----------------------------------------------------------

    return const Center(
      child: Icon(
        Icons.eco,
        size: 60,
        color: Color(0xFF134E39),
      ),
    );
  }

  // ============================================================
  // IMAGE SECTION
  // ============================================================

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plant Image',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF134E39),
          ),
        ),

        const SizedBox(height: 12),

        // ------------------------------------------------------
        // IMAGE CONTAINER
        // ------------------------------------------------------

        Container(
          width: double.infinity,
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0EA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFD3E4D7),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildImagePreview(),
        ),

        const SizedBox(height: 12),

        // ------------------------------------------------------
        // IMAGE ACTIONS
        // ------------------------------------------------------

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _saving
                    ? null
                    : _pickImage,
                icon: const Icon(
                  Icons.image_outlined,
                ),
                label: Text(
                  (_hasExistingImage ||
                          _hasNewImage)
                      ? 'Change Image'
                      : 'Add Image',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      const Color(0xFF134E39),
                  side: const BorderSide(
                    color: Color(0xFF134E39),
                  ),
                  minimumSize:
                      const Size(0, 48),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
              ),
            ),

            // --------------------------------------------------
            // DELETE IMAGE BUTTON
            // --------------------------------------------------

            if (_hasExistingImage ||
                _hasNewImage) ...[
              const SizedBox(width: 10),

              SizedBox(
                height: 48,
                width: 52,
                child: OutlinedButton(
                  onPressed: _saving
                      ? null
                      : _removeImage,
                  style:
                      OutlinedButton.styleFrom(
                    foregroundColor:
                        Colors.redAccent,
                    side: const BorderSide(
                      color: Colors.redAccent,
                    ),
                    padding:
                        EdgeInsets.zero,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                  ),
                ),
              ),
            ],
          ],
        ),

        // ------------------------------------------------------
        // IMAGE STATUS TEXT
        // ------------------------------------------------------

        const SizedBox(height: 8),

        Text(
          _hasNewImage
              ? 'New image selected. Save changes to upload it.'
              : _hasExistingImage
                  ? 'Current plant image'
                  : 'No plant image selected.',
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SAVE CHANGES
  // ============================================================

  Future<void> _saveChanges() async {
    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (_nameController.text.trim().isEmpty ||
        _speciesController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _selectedCategory == null ||
        _selectedSchedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all required fields.',
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // START SAVING
    // ----------------------------------------------------------

    setState(() {
      _saving = true;
    });

    try {
      // --------------------------------------------------------
      // UPDATE PLANT
      // --------------------------------------------------------

      await PlantService().updatePlant(
        plantId: widget.plant.id,

        name: _nameController.text.trim(),

        species:
            _speciesController.text.trim(),

        location:
            _locationController.text.trim(),

        category: _selectedCategory!,

        wateringSchedule:
            _selectedSchedule!,

        // New image, if selected.
        imageFile: _selectedImage,

        // Remove image if requested.
        removeImage:
            _removeExistingImage,
      );

      if (!mounted) return;

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Plant updated successfully!',
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
          ),
          backgroundColor:
              const Color(0xFF134E39),
          behavior:
              SnackBarBehavior.floating,
        ),
      );

      // --------------------------------------------------------
      // RETURN TO PREVIOUS SCREEN
      // --------------------------------------------------------

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        'EDIT PLANT ERROR: $e',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update plant: $e',
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.redAccent,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration(
    String label,
  ) {
    return InputDecoration(
      labelText: label,

      labelStyle: GoogleFonts.poppins(
        color: const Color(0xFF5A7865),
      ),

      filled: true,

      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(12),
        borderSide:
            const BorderSide(
          color: Color(0xFF134E39),
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF4F7F5),

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF134E39),
          ),

          onPressed: _saving
              ? null
              : () {
                  Navigator.pop(context);
                },
        ),

        title: Text(
          'Edit Plant',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF134E39),
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            // ==================================================
            // IMAGE
            // ==================================================

            _buildImageSection(),

            const SizedBox(height: 28),

            // ==================================================
            // PLANT INFORMATION
            // ==================================================

            Text(
              'Plant Information',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color:
                    const Color(0xFF134E39),
              ),
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // NAME
            // --------------------------------------------------

            TextField(
              controller:
                  _nameController,

              style: GoogleFonts.poppins(
                color:
                    const Color(0xFF134E39),
              ),

              decoration:
                  _inputDecoration(
                'Plant Name *',
              ),
            ),

            const SizedBox(height: 14),

            // --------------------------------------------------
            // SPECIES
            // --------------------------------------------------

            TextField(
              controller:
                  _speciesController,

              style: GoogleFonts.poppins(
                color:
                    const Color(0xFF134E39),
              ),

              decoration:
                  _inputDecoration(
                'Species *',
              ),
            ),

            const SizedBox(height: 14),

            // --------------------------------------------------
            // LOCATION
            // --------------------------------------------------

            TextField(
              controller:
                  _locationController,

              style: GoogleFonts.poppins(
                color:
                    const Color(0xFF134E39),
              ),

              decoration:
                  _inputDecoration(
                'Location *',
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // CATEGORY
            // ==================================================

            Text(
              'Plant Category',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color:
                    const Color(0xFF134E39),
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<
                String>(
              value: _categories.contains(
                _selectedCategory,
              )
                  ? _selectedCategory
                  : null,

              decoration:
                  _inputDecoration(
                'Category *',
              ),

              items:
                  _categories.map(
                (category) {
                  return DropdownMenuItem<
                      String>(
                    value: category,

                    child: Text(
                      category,
                      style:
                          GoogleFonts.poppins(),
                    ),
                  );
                },
              ).toList(),

              onChanged: _saving
                  ? null
                  : (value) {
                      setState(() {
                        _selectedCategory =
                            value;
                      });
                    },
            ),

            const SizedBox(height: 24),

            // ==================================================
            // WATERING SCHEDULE
            // ==================================================

            Text(
              'Watering Schedule',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color:
                    const Color(0xFF134E39),
              ),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<
                String>(
              value: _schedules.contains(
                _selectedSchedule,
              )
                  ? _selectedSchedule
                  : null,

              decoration:
                  _inputDecoration(
                'Watering Schedule *',
              ),

              items:
                  _schedules.map(
                (schedule) {
                  return DropdownMenuItem<
                      String>(
                    value: schedule,

                    child: Text(
                      schedule,
                      style:
                          GoogleFonts.poppins(),
                    ),
                  );
                },
              ).toList(),

              onChanged: _saving
                  ? null
                  : (value) {
                      setState(() {
                        _selectedSchedule =
                            value;
                      });
                    },
            ),

            const SizedBox(height: 32),

            // ==================================================
            // SAVE BUTTON
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 52,

              child:
                  ElevatedButton(
                onPressed:
                    _saving
                        ? null
                        : _saveChanges,

                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF134E39,
                  ),

                  disabledBackgroundColor:
                      const Color(
                    0xFF9BB3A4,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),
                ),

                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,

                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style:
                            GoogleFonts
                                .poppins(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
