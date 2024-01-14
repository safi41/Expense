import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('Expense_data');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final Expensename = TextEditingController();
  final Expenseprice = TextEditingController();

  List<Map<String, dynamic>> _item = [];

  final Expensedata = Hive.box('Expense_data');

  @override
  void initState() {
    super.initState();
    _refrshItems();
  }

  //First letter Capitalize Function
  String capitalize(String input) {
    if (input.isEmpty) {
      return input;
    }
    return input[0].toUpperCase() + input.substring(1);
  }

  //Get function
  void _refrshItems() {
    final data = Expensedata.keys.map((key) {
      final item = Expensedata.get(key);
      print('item[\'datetime\']: ${item['datetime']}');
      DateTime parsedDate = DateTime.tryParse(item['datetime']) ?? DateTime.now();
      print('parsedDate: $parsedDate');
      String formattedDate = DateFormat('yyyy-MM-dd').format(parsedDate);
      print('formattedDate: $formattedDate');


      return {
        "key": key,
        "name": item["name"],
        "price": item["price"],
        "datetime": formattedDate
      };
    }).toList();


    setState(() {
      _item = data.reversed.toList();
      print(_item.length);
    });
  }

  //Update function
  Future<void> _updateItem(int itemkey, Map<String, dynamic> newitem) async {
    await Expensedata.put(itemkey, newitem);
    _refrshItems();
  }

  //Add  Data to Hive
  Future<void> _createItem(Map<String, dynamic> newitem) async {
    await Expensedata.add(newitem);
    _refrshItems();
  }

//delete function
  Future<void> _deleteitem(int newitem) async {
    await Expensedata.delete(newitem);
    _refrshItems();

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text(""
          "An Expense  has been deleted"),
      backgroundColor: Colors.red,
    ));
  }

//Add new expense
  addnewexpense(int? itemkey) async {
    if (itemkey != null) {
      final exsistingitem =
          _item.firstWhere((element) => element['key'] == itemkey);
      Expensename.text = exsistingitem['name'];
      Expenseprice.text = exsistingitem['price'];
    }
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Add new Expense"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //Name of exxpense
                  TextField(
                    controller: Expensename,
                    decoration: const InputDecoration(hintText: "Expense Name"),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  //Price
                  TextField(
                    controller: Expenseprice,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: "Expense Price"),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          // Check if either of the text fields is empty
                          if (Expensename.text.isEmpty ||
                              Expenseprice.text.isEmpty) {
                            // Show a SnackBar with an error message
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Expense name and price cannot be empty'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } else {
                            // Proceed with your existing logic
                            if (itemkey == null) {
                              _createItem({
                                "name": Expensename.text,
                                "price": Expenseprice.text,
                                "datetime": DateTime.now().toString()
                              });
                            } else if (itemkey != null) {
                              _updateItem(itemkey, {
                                'name': Expensename.text.trim(),
                                'price': Expenseprice.text.trim(),
                                "datetime": DateTime.now().toString()
                              });
                            }
                            clear();
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text(itemkey == null ? "Save" : "Update"),
                      ),
                      ElevatedButton(
                          onPressed: () async {
                            clear();
                            Navigator.of(context).pop();
                          },
                          child: const Text("Cancel")),
                    ],
                  )
                ],
              ),
            ));
  }

  //clear controllers
  void clear() {
    Expensename.clear();
    Expenseprice.clear();
  }

  Map<String, double> _aggregateDataByDay(List<Map<String, dynamic>> items) {
    Map<String, double> aggregatedData = {
      'Sun': 0,
      'Mon': 0,
      'Tue': 0,
      'Wed': 0,
      'Thu': 0,
      'Fri': 0,
      'Sat': 0,
    };

    for (var item in items) {
      DateTime parsedDate = DateTime.tryParse(item['datetime']) ?? DateTime.now();
      String dayOfWeek = DateFormat('E').format(parsedDate); // 'E' gives short day name

      double? price = double.tryParse(item['price']);
      double totalAmount = price ?? 0.0;

      aggregatedData[dayOfWeek] = (aggregatedData[dayOfWeek] ?? 0) + totalAmount;
    }

    return aggregatedData;
  }


  List<BarChartGroupData> _getBarChartData(Map<String, double> aggregatedData) {
    final  List<BarChartGroupData> barGroups = [];
    int barIndex = 0;

    aggregatedData.forEach((date, totalAmount) {
      barGroups.add(
        BarChartGroupData(
          x: barIndex++,
          barRods: [BarChartRodData(
              width:15 ,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.zero,
                topRight: Radius.zero,
              ),
              toY: totalAmount, color: Colors.deepPurple)],
        ),
      );
    });

    return barGroups;
  }
  bool _isChartDataEmpty(Map<String, double> aggregatedData) {
    // Check if all values in the aggregatedData map are zero
    return aggregatedData.values.every((value) => value == 0);
  }

  @override
  Widget build(BuildContext context) {
    Map<String, double> aggregatedData = _aggregateDataByDay(_item);
    bool hasChartData = !_isChartDataEmpty(aggregatedData);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Expense Manager",
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Colors.deepPurple,
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.deepPurple,
          onPressed: () {
            addnewexpense(null);
          },
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
        body: ListView(
          children: [
            SizedBox(height: 20,),
            if (hasChartData)
                Container(
              height: 200,
              child: BarChart(
                BarChartData(
                  gridData:FlGridData(show: false),
                  barGroups: _getBarChartData(_aggregateDataByDay(_item)),
                  titlesData: FlTitlesData(
                      rightTitles:const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles:const AxisTitles(sideTitles: SideTitles(showTitles: false)),

                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        getTitlesWidget: (value, meta) {
                          const daysOfWeek = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(daysOfWeek[value.toInt()], style: TextStyle(color: Colors.black, fontSize: 10)),
                          );
                        },
                        showTitles: true,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),

              ),
            )
                else Padding(
              padding: EdgeInsets.only(top: 200,left: 100),
              child: Text("Nothing to show",style: TextStyle(fontSize: 20),),
            ),

            SizedBox(height: 20,),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _item.length,
              itemBuilder: (context, index) {
                final currentitem = _item[index];
                return Dismissible(
                  key: Key(currentitem['key'].toString()),
                  onDismissed: (direction) {
                    _deleteitem(currentitem['key']);
                  },
                  background: Container(
                    color: Colors.red.shade100,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.all(10),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    color: Colors.purple.shade50,
                    margin: const EdgeInsets.all(10),
                    elevation: 0,
                    child: ListTile(
                      title: Text(capitalize(currentitem['name'])),
                      subtitle: Text(currentitem['datetime'].toString()),
                      trailing: Column(
                        children: [
                          Text(
                            'RS:${currentitem['price'].toString()}',
                            style: const TextStyle(fontSize: 15),
                          ),
                          Expanded(
                            child: IconButton(
                              onPressed: () {
                                addnewexpense(currentitem['key']);
                              },
                              icon: const Icon(Icons.edit),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }}
