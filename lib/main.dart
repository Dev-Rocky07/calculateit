import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('partyFunds');
  runApp(PartyFundsApp());
}

class PartyFundsApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Party Fund - Modern',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5FFF7),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),

      home: PartyListScreen(),
    );
  }
}

// ----------------------------- Party List ---------------------------------
class PartyListScreen extends StatefulWidget {
  @override
  _PartyListScreenState createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen>
    with SingleTickerProviderStateMixin {
  final box = Hive.box('partyFunds');
  final TextEditingController partyController = TextEditingController();
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    partyController.dispose();
    super.dispose();
  }

  void _addParty() {
    String name = partyController.text.trim();
    if (name.isNotEmpty) {
      // 👇 Clone the existing list safely
      List parties = List.from(box.get('parties', defaultValue: []));

      parties.add({"name": name, "members": []});
      box.put('parties', parties);

      partyController.clear();
      setState(() {}); // rebuild UI

      // nice button animation
      _fabController.forward().then((_) => _fabController.reverse());
    }
  }

  void _deleteParty(int index) {
    List parties = box.get('parties', defaultValue: []);
    parties.removeAt(index);
    box.put('parties', parties);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    List parties = box.get('parties', defaultValue: []);

    return Scaffold(
      appBar: AppBar(
        title: Text('🎉 Parties'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: partyController,
                      decoration: InputDecoration(
                        hintText: 'New party name (e.g. Goa Trip)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceVariant,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  AnimatedScale(
                    scale: 1,
                    duration: Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        shape: StadiumBorder(),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      icon: Icon(Icons.add),
                      label: Text('Add'),
                      onPressed: _addParty,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Expanded(
                child: parties.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.celebration,
                              size: 64,
                              color: Colors.deepPurple.shade200,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No parties yet',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Add a party above to get started',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: parties.length,
                        itemBuilder: (context, index) {
                          final party = parties[index];
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 450),
                            margin: EdgeInsets.symmetric(vertical: 8),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.deepPurple.shade50,
                                  Colors.white,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  party['name']
                                      .toString()
                                      .substring(0, 1)
                                      .toUpperCase(),
                                ),
                              ),
                              title: Text(
                                party['name'],
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${(party['members'] as List).length} member(s)',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _deleteParty(index),
                                  ),
                                  SizedBox(width: 6),
                                  Icon(Icons.chevron_right),
                                ],
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PartyDetailScreen(partyIndex: index),
                                ),
                              ).then((_) => setState(() {})),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------- Party Detail ---------------------------------
class PartyDetailScreen extends StatefulWidget {
  final int partyIndex;
  PartyDetailScreen({required this.partyIndex});

  @override
  _PartyDetailScreenState createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends State<PartyDetailScreen>
    with TickerProviderStateMixin {
  final box = Hive.box('partyFunds');
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  late AnimationController _summaryAnimController;

  @override
  void initState() {
    super.initState();
    _summaryAnimController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _summaryAnimController.dispose();
    nameController.dispose();
    amountController.dispose();
    super.dispose();
  }

  void _addMember() {
    String name = nameController.text.trim();
    double? amount = double.tryParse(amountController.text);
    if (name.isNotEmpty && amount != null) {
      List parties = box.get('parties', defaultValue: []);
      parties[widget.partyIndex]['members'].add({
        'name': name,
        'amount': amount,
      });
      box.put('parties', parties);
      nameController.clear();
      amountController.clear();
      setState(() {});
      _summaryAnimController.forward(from: 0);
    }
  }

  void _deleteMember(int index) {
    List parties = box.get('parties', defaultValue: []);
    parties[widget.partyIndex]['members'].removeAt(index);
    box.put('parties', parties);
    setState(() {});
    _summaryAnimController.forward(from: 0);
  }

  /// ✅ Fixed WhatsApp launcher with fallback support
  Future<void> _openWhatsApp(String message) async {
    final encodedMessage = Uri.encodeComponent(message);
    final whatsappUri = Uri.parse('whatsapp://send?text=$encodedMessage');
    final webUri = Uri.parse('https://wa.me/?text=$encodedMessage');

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('WhatsApp error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open WhatsApp')));
    }
  }

  List<String> _calculateSettlements(List members) {
    double total = members.fold(
      0.0,
      (s, m) => s + (m['amount'] as num).toDouble(),
    );
    double average = members.isEmpty ? 0 : total / members.length;

    List<Map<String, dynamic>> balances = members
        .map(
          (m) => {
            'name': m['name'],
            'balance': (m['amount'] as num).toDouble() - average,
          },
        )
        .toList();

    List<Map<String, dynamic>> debtors = balances
        .where((b) => b['balance'] < -0.0001)
        .map((b) => {'name': b['name'], 'amt': -b['balance']})
        .toList();
    List<Map<String, dynamic>> creditors = balances
        .where((b) => b['balance'] > 0.0001)
        .map((b) => {'name': b['name'], 'amt': b['balance']})
        .toList();

    List<String> settles = [];
    int i = 0, j = 0;
    while (i < debtors.length && j < creditors.length) {
      double pay = debtors[i]['amt'] < creditors[j]['amt']
          ? debtors[i]['amt']
          : creditors[j]['amt'];
      settles.add(
        '${debtors[i]['name']} pays ${creditors[j]['name']} ₹${pay.toStringAsFixed(2)}',
      );
      debtors[i]['amt'] -= pay;
      creditors[j]['amt'] -= pay;
      if ((debtors[i]['amt'] as double) <= 0.0001) i++;
      if ((creditors[j]['amt'] as double) <= 0.0001) j++;
    }
    return settles;
  }

  @override
  Widget build(BuildContext context) {
    List parties = box.get('parties', defaultValue: []);
    final party = parties[widget.partyIndex];
    List members = party['members'];

    double total = members.fold(
      0.0,
      (s, m) => s + (m['amount'] as num).toDouble(),
    );
    double average = members.isEmpty ? 0 : total / members.length;

    List<Map<String, dynamic>> balances = members
        .map(
          (m) => {
            'name': m['name'],
            'balance': (m['amount'] as num).toDouble() - average,
          },
        )
        .toList();

    List<String> settlements = _calculateSettlements(members);

    String summaryText =
        '🎉 ${party['name']} Summary\nTotal: ₹${total.toStringAsFixed(2)}\nAverage: ₹${average.toStringAsFixed(2)}\n\n';
    for (var s in settlements) summaryText += '$s\n';

    return Scaffold(
      appBar: AppBar(
        title: Text(party['name']),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.share),
        //     onPressed: () => _openWhatsApp(summaryText),
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'Member name',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: amountController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Amount (₹)',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addMember,
                      icon: Icon(Icons.add),
                      label: Text('Add'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            if (members.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Name',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Contributed',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Balance',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 40),
                  ],
                ),
              ),
            SizedBox(height: 6),
            if (members.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No members yet'),
                ),
              )
            else
              Column(
                children: balances.asMap().entries.map((entry) {
                  int index = entry.key;
                  var it = entry.value;
                  double balance = it['balance'];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      child: Text(it['name'][0].toUpperCase()),
                    ),
                    title: Text(
                      it['name'],
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Contributed: ₹${members[index]['amount']}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    trailing: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: balance >= 0
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${balance >= 0 ? '+' : '-'} ₹${balance.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              color: balance >= 0
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteMember(index),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            SizedBox(height: 8),
            Row(
              children: [
                _summaryCard('Total', total.toStringAsFixed(2)),
                SizedBox(width: 8),
                _summaryCard('Average', average.toStringAsFixed(2)),
              ],
            ),
            SizedBox(height: 12),
            _settlementSummary(settlements, summaryText),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade700)),
              SizedBox(height: 6),
              Text(
                '₹$value',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settlementSummary(List<String> settlements, String summaryText) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade400],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Settlement Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: () => _openWhatsApp(summaryText),
                icon: Icon(Icons.send, color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (settlements.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: Colors.white70,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'All settled ✅',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            )
          else
            Column(
              children: settlements.asMap().entries.map((entry) {
                int idx = entry.key;
                String text = entry.value;
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 400 + (idx * 80)),
                  builder: (context, val, child) => Opacity(
                    opacity: val,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - val)),
                      child: child,
                    ),
                  ),
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 6),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.swap_horiz,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),

                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            text,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.white24,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
