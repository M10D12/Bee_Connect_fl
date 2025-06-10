import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:beeconnect_flutter/db/database_helper.dart';

class StatisticsScreen extends StatefulWidget {
  final String apiaryId;
  final String apiaryName;

  const StatisticsScreen({
    Key? key,
    required this.apiaryId,
    required this.apiaryName,
  }) : super(key: key);

  @override
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final db = DatabaseHelper();
  bool isLoading = true;
  String? errorMessage;
  DateTime selectedDate = DateTime.now();
  List<HoneyHarvest> harvests = [];
  String newHarvestAmount = "";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // We'll need to create a new table for honey harvests in DatabaseHelper
      final harvestsData = await db.getHoneyHarvestsByApiary(widget.apiaryId);
      
      setState(() {
        harvests = harvestsData.map((data) => HoneyHarvest(
          apiaryId: data['apiary_id'].toString(),
          apiaryName: widget.apiaryName,
          amount: data['amount'] ?? 0.0,
          date: DateTime.parse(data['date']),
        )).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Error: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  Future<void> _addHarvest() async {
    final amount = double.tryParse(newHarvestAmount) ?? 0.0;
    if (amount > 0) {
      try {
        await db.insertHoneyHarvest(
          apiaryId: widget.apiaryId,
          amount: amount,
          date: selectedDate,
        );

        setState(() {
          harvests.add(HoneyHarvest(
            apiaryId: widget.apiaryId,
            apiaryName: widget.apiaryName,
            amount: amount,
            date: selectedDate,
          ));
          newHarvestAmount = "";
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add harvest: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text("Estatísticas de ${widget.apiaryName}"),
        backgroundColor: const Color(0xFFFFC107),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Voltar"),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Date and Add Harvest Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Data:", style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(formattedDate),
                            ],
                          ),
                          OutlinedButton(
                            onPressed: () => _selectDate(context),
                            child: const Text("Alterar Data"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Add Harvest Section
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(text: newHarvestAmount),
                              onChanged: (value) => newHarvestAmount = value,
                              decoration: const InputDecoration(
                                labelText: "Quantidade (kg)",
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addHarvest,
                            child: const Text("Adicionar"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Chart
                      const Text("Produção de Mel por dia", style: TextStyle(fontWeight: FontWeight.bold)),
                      HoneyProductionChart(harvests: harvests),
                      const SizedBox(height: 16),

                      // Harvest List
                      const Text("Registros de Colheita:", style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: ListView.separated(
                          itemCount: harvests.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final harvest = harvests[index];
                            return HarvestItem(harvest: harvest);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

// Rest of the classes remain the same (HoneyProductionChart, HarvestItem, HoneyHarvest, ChartData)
class HoneyProductionChart extends StatelessWidget {
  final List<HoneyHarvest> harvests;

  const HoneyProductionChart({Key? key, required this.harvests}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Group by date and sum amounts
    final dailyHarvests = <String, double>{};
    for (final harvest in harvests) {
      final date = DateFormat('dd/MM').format(harvest.date);
      dailyHarvests[date] = (dailyHarvests[date] ?? 0) + harvest.amount;
    }

    final chartData = dailyHarvests.entries
        .map((e) => ChartData(e.key, e.value))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return SizedBox(
      height: 200,
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        series: <LineSeries<ChartData, String>>[ 
          LineSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.date,
            yValueMapper: (ChartData data, _) => data.amount,
            color: const Color(0xFFFFA000),
            markerSettings: const MarkerSettings(isVisible: true),
          ),
        ],
      ),
    );
  }
}

class ChartData {
  final String date;
  final double amount;

  ChartData(this.date, this.amount);
}

class HarvestItem extends StatelessWidget {
  final HoneyHarvest harvest;

  const HarvestItem({Key? key, required this.harvest}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(harvest.apiaryName, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                DateFormat('dd/MM/yyyy').format(harvest.date),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          Text("${harvest.amount} kg", style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class HoneyHarvest {
  final String apiaryId;
  final String apiaryName;
  final double amount;
  final DateTime date;

  HoneyHarvest({
    required this.apiaryId,
    required this.apiaryName,
    required this.amount,
    required this.date,
  });
}