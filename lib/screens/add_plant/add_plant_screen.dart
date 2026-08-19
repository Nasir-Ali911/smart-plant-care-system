import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:smart_plant_care/screens/add_plant/widgets/custom_text_field.dart';
import 'package:smart_plant_care/screens/add_plant/widgets/dropdown_field.dart';
import 'package:smart_plant_care/screens/add_plant/widgets/save_button.dart';
import 'package:smart_plant_care/screens/add_plant/widgets/section_title.dart';
import 'package:smart_plant_care/services/plant_service.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _speciesController =
      TextEditingController();

  final TextEditingController _locationController =
      TextEditingController();

  final TextEditingController _potController =
      TextEditingController();

  final TextEditingController _dateController =
      TextEditingController();

  final TextEditingController _notesController =
      TextEditingController();

  // Controller for custom watering schedule
  final TextEditingController _customScheduleController =
      TextEditingController();

  // ============================================================
  // DROPDOWNS
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

  // ============================================================
  // SAVE STATE
  // ============================================================

  bool _isSaving = false;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _locationController.dispose();
    _potController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    _customScheduleController.dispose();

    super.dispose();
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile == null) {
        return;
      }

      setState(() {
        _selectedImage = pickedFile;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to select image: $e',
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
    });
  }

  // ============================================================
  // IMAGE PICKER CARD
  // ============================================================

  Widget _buildImagePickerCard() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 190,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD7E2DC),
            width: 1.2,
          ),
        ),
        child: _selectedImage == null
            ? _buildEmptyImageCard()
            : _buildSelectedImageCard(),
      ),
    );
  }

  // ============================================================
  // EMPTY IMAGE CARD
  // ============================================================

  Widget _buildEmptyImageCard() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F3ED),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(
            Icons.add_a_photo_outlined,
            size: 28,
            color: Color(0xFF134E39),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to add plant image',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF134E39),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Optional',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SELECTED IMAGE CARD
  // ============================================================

  Widget _buildSelectedImageCard() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: FutureBuilder<List<int>>(
              future: _selectedImage!.readAsBytes(),
              builder: (
                context,
                snapshot,
              ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF134E39),
                    ),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 45,
                      color: Colors.grey,
                    ),
                  );
                }

                return Image.memory(
                  Uint8List.fromList(snapshot.data!),
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
        ),

        // Bottom overlay
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: 0.55,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.photo_camera_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap to change image',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Remove button
        Positioned(
          top: 10,
          right: 10,
          child: GestureDetector(
            onTap: _removeImage,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.15,
                    ),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close,
                size: 20,
                color: Colors.redAccent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DATE PICKER
  // ============================================================

  Future<void> _selectDate(
    BuildContext context,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (
        context,
        child,
      ) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF134E39),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text =
            "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  // ============================================================
  // CUSTOM WATERING SCHEDULE
  // ============================================================

  Future<void> _showCustomScheduleDialog() async {
    _customScheduleController.clear();

    final String? customSchedule = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'Custom Watering Schedule',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF134E39),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose how often this plant should be watered.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 18),

              TextField(
                controller: _customScheduleController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Water every',
                  hintText: 'e.g. 3',
                  suffixText: 'days',
                  prefixIcon: const Icon(
                    Icons.water_drop_outlined,
                    color: Color(0xFF134E39),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFD0E2D4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF134E39),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                ),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF134E39),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final String input =
                    _customScheduleController.text.trim();

                final int? days = int.tryParse(input);

                if (days == null || days <= 0) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please enter a valid number of days.',
                      ),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  'Every $days Days',
                );
              },
              child: Text(
                'Save',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (customSchedule != null) {
      setState(() {
        _selectedSchedule = customSchedule;
      });
    }
  }

  // ============================================================
  // SAVE PLANT
  // ============================================================

  Future<void> _handleSave() async {
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
    // PREVENT DOUBLE CLICK
    // ----------------------------------------------------------

    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // ----------------------------------------------------------
    // SAVE TO FIREBASE
    // ----------------------------------------------------------

    try {
      await PlantService().addPlant(
        name: _nameController.text.trim(),
        species: _speciesController.text.trim(),
        location: _locationController.text.trim(),
        moisture: _selectedSchedule!,
        temperature: '25°C',
        status: _selectedCategory!,
        imageFile: _selectedImage,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Plant added successfully!',
            style: GoogleFonts.poppins(
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color(0xFF134E39),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add plant: $e',
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
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),

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
          onPressed: () {
            if (!_isSaving) {
              Navigator.pop(context);
            }
          },
        ),

        title: Text(
          'Add New Plant',
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ====================================================
            // IMAGE
            // ====================================================

            _buildImagePickerCard(),

            const SizedBox(height: 18),

            // ====================================================
            // PLANT INFORMATION
            // ====================================================

            const SectionTitle(
              title: 'Plant Information',
            ),

            CustomTextField(
              label: 'Plant Name *',
              hintText: 'e.g., Monstera Deliciosa',
              controller: _nameController,
            ),

            const SizedBox(height: 14),

            CustomTextField(
              label: 'Species *',
              hintText: 'e.g., Monstera',
              controller: _speciesController,
            ),

            const SizedBox(height: 14),

            CustomTextField(
              label: 'Location *',
              hintText: 'e.g., Living Room Balcony',
              controller: _locationController,
            ),

            const SizedBox(height: 14),

            CustomTextField(
              label: 'Pot Number (Optional)',
              hintText: 'e.g., Pot #4',
              controller: _potController,
            ),

            const SizedBox(height: 10),

            // ====================================================
            // CATEGORY
            // ====================================================

            const SectionTitle(
              title: 'Plant Category',
            ),

            DropdownField(
              label: 'Category *',
              hintText: 'Select category',
              value: _selectedCategory,
              items: _categories,
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
            ),

            const SizedBox(height: 10),

            // ====================================================
            // SCHEDULE
            // ====================================================

            const SectionTitle(
              title: 'Schedule & Timing',
            ),

            CustomTextField(
              label: 'Planting Date',
              hintText: 'DD/MM/YYYY',
              controller: _dateController,
              readOnly: true,
              onTap: () => _selectDate(context),
              suffixIcon: const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF134E39),
              ),
            ),

            const SizedBox(height: 14),

            // ====================================================
            // WATERING SCHEDULE
            // ====================================================

            DropdownField(
              label: 'Watering Schedule *',
              hintText: 'Select schedule frequency',

              // Important:
              // This allows a custom value such as
              // "Every 3 Days" to remain visible in the dropdown.
              value: _selectedSchedule,

              items: [
                ..._schedules,

                if (_selectedSchedule != null &&
                    !_schedules.contains(_selectedSchedule))
                  _selectedSchedule!,
              ],

              onChanged: (value) async {
                if (value == 'Custom') {
                  await _showCustomScheduleDialog();
                } else {
                  setState(() {
                    _selectedSchedule = value;
                  });
                }
              },
            ),

            const SizedBox(height: 10),

            // ====================================================
            // NOTES
            // ====================================================

            const SectionTitle(
              title: 'Additional Notes',
            ),

            CustomTextField(
              label: 'Notes',
              hintText: 'Add notes about this plant...',
              controller: _notesController,
              maxLines: 4,
            ),

            const SizedBox(height: 30),

            // ====================================================
            // SAVE BUTTON
            // ====================================================

            SaveButton(
              onPressed: () {
                if (!_isSaving) {
                  _handleSave();
                }
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}