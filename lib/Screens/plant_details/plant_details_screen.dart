import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_plant_care/models/plant_model.dart';
import 'package:smart_plant_care/screens/plant_details/widgets/plant_header.dart';
import 'package:smart_plant_care/screens/plant_details/widgets/sensor_card.dart';
import 'package:smart_plant_care/screens/plant_details/widgets/irrigation_card.dart';
import 'package:smart_plant_care/screens/plant_details/widgets/info_tile.dart';
import 'package:smart_plant_care/screens/plant_details/widgets/section_title.dart';
import 'package:smart_plant_care/screens/edit_plant/edit_plant_screen.dart';

class PlantDetailsScreen extends StatelessWidget {
  final PlantModel plant; // Updated to PlantModel

  const PlantDetailsScreen({super.key, required this.plant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF134E39)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          plant.name,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF134E39),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF134E39)),
            onPressed: () async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditPlantScreen(
        plant: plant,
      ),
    ),
  );
},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Plant Header
            PlantHeader(plant: plant),
            const SizedBox(height: 20),

            // 2. Environmental Monitoring Grid
            const SectionTitle(title: 'Environmental Monitoring'),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                SensorCard(
                  icon: Icons.thermostat_outlined,
                  title: 'Temperature',
                  value: plant.temperature, // String value directly from model
                  status: 'Optimal',
                ),
                SensorCard(
                  icon: Icons.water_drop_outlined,
                  title: 'Soil Moisture',
                  value: plant.moisture, // String value directly from model
                  status: 'Optimal',
                ),
                const SensorCard(
                  icon: Icons.air_outlined,
                  title: 'Humidity',
                  value: '60%', // Static fallback for model property extension
                  status: 'Optimal',
                ),
                const SensorCard(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Light Intensity',
                  value: '800 lx', // Static fallback for model property extension
                  status: 'Optimal',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Smart Irrigation Section
            const SectionTitle(title: 'Smart Irrigation'),
            const SizedBox(height: 8),
            const IrrigationCard(),
            const SizedBox(height: 20),

            // 4. Plant Information List
            const SectionTitle(title: 'Plant Information'),
            const SizedBox(height: 8),
            InfoTile(label: 'Species', value: plant.species, icon: Icons.eco_outlined),
            InfoTile(label: 'Location', value: plant.location, icon: Icons.location_on_outlined),
            const InfoTile(label: 'Planting Date', value: '12 Jan 2026', icon: Icons.calendar_today_outlined),
            InfoTile(label: 'Last Watered', value: plant.lastUpdated, icon: Icons.access_time_outlined),
            const InfoTile(label: 'Growth Stage', value: 'Vegetative', icon: Icons.trending_up_outlined),
            const InfoTile(label: 'Sensor Status', value: 'Active', icon: Icons.sensors_outlined),
            const SizedBox(height: 20),

            // 5. Recent Logs Section
            const SectionTitle(title: 'Recent Logs'),
            const SizedBox(height: 8),
            Container(
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
              child: Column(
                children: const [
                  ListTile(
                    leading: Icon(Icons.water_drop, color: Color(0xFF134E39)),
                    title: Text('Moisture Updated'),
                    subtitle: Text('Soil moisture level stabilized'),
                    trailing: Text('10m ago', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.thermostat, color: Color(0xFF134E39)),
                    title: Text('Temperature Changed'),
                    subtitle: Text('Recorded ambient reading'),
                    trailing: Text('1h ago', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.power_settings_new, color: Color(0xFF134E39)),
                    title: Text('Irrigation Started'),
                    subtitle: Text('Automated cycle ran for 2 minutes'),
                    trailing: Text('2h ago', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 6. Bottom View History Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF134E39),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  // UI only action for now
                },
                child: Text(
                  'View History',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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