import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:convert';

// ========== السيرفر ==========
const String serverUrl = 'http://192.168.1.239:3000';
Map<String, dynamic> currentUser = {};
IO.Socket socket = IO.io(serverUrl, <String, dynamic>{
  'transports': ['websocket'],
  'autoConnect': false,
});

void main() {
  socket.connect();
  runApp(const FoshaApp());
}

class FoshaApp extends StatelessWidget {
  const FoshaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'فسحة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFFF8C00),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashScreen(),
    );
  }
}

// ========== Splash Screen ==========
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF8C00),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/toktok.png', width: 250, height: 250),
                const SizedBox(height: 24),
                const Text('فسحة',
                    style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('وصلك في ثواني',
                    style: TextStyle(fontSize: 18, color: Colors.white70)),
                const SizedBox(height: 48),
                const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ========== مناطق طنطا ==========
const List<String> tantaAreas = [
  'الاستاد', 'شارع البحر', 'سيجر', 'الأحمدي', 'الجلاء', 'كفر عصام',
  'سبرباي', 'شارع النحاس', 'قحافة', 'محلة مرحوم', 'العجيزي', 'القرشي',
  'السلخانة', 'البوريفاج', 'نادي الصيد', 'شارع سعيد', 'شارع المديرية',
  'شارع توت عنخ آمون', 'شارع حسن رضوان', 'شارع الحكمة', 'شارع الجلاء الجديد',
  'منطقة الاستراحة', 'منطقة الأحوال المدنية', 'منطقة التجنيد', 'منطقة المحطة',
  'مساكن البترول', 'مساكن الشباب', 'مساكن سليمان', 'منطقة المرشحة',
  'شارع عمر زعفان', 'شارع علي مبارك', 'شارع محب', 'شارع الجيش', 'شارع بطرس',
  'شارع المدارس', 'شارع النادي', 'شارع المعاهدة', 'شارع الفاتح',
  'منطقة كوبري القرشي', 'منطقة المعرض', 'منطقة السكة الجديدة',
  'منطقة ترعة القاصد', 'منطقة الاستاد الجديد', 'منطقة نادي طنطا',
  'شارع الجملة', 'شارع السكة الحديد', 'شارع الخان', 'شارع الحلو',
  'كورنيش الجلاء', 'كورنيش نايف', 'كورنيش حسن رضوان', 'كورنيش قحافة',
  'كوبري فاروق', 'موقف سبرباي', 'موقف الجلاء', 'موقف السلخانة',
  'الموقف القديم', '25 الجلاء', '25 الكاكولا', 'سكة المحلة', 'ترعة سنارة',
  'كنيسة ماري جرجس', 'شارع نايف عماد', 'السلخانة القديمة', 'شارع السلخانة',
  'مسجد عوارة', 'مسجد السلام', 'مسجد السيد البدوي', 'مسجد الدماطي',
  'قهوة صابر', 'الجانبية', 'مساكن الجلاء',
];

// ========== شاشة الدخول ==========
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': _phoneController.text,
          'password': _passwordController.text,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final user = data['user'];
        if (mounted) {
          if (user['type'] == 'سائق') {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const DriverScreen()));
          } else {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const RiderScreen()));
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message']), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('مش قادر يتصل بالسيرفر'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF8C00),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/toktok.png', width: 120, height: 120),
              const SizedBox(height: 8),
              const Text('فسحة',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              const Text('وصلك في ثواني',
                  style: TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 40),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  hintText: 'رقم التليفون',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                textAlign: TextAlign.right,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  hintText: 'كلمة السر',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.lock),
                ),
                textAlign: TextAlign.right,
                obscureText: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('دخول', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()));
                },
                child: const Text(
                  'مش عندك حساب؟ سجل دلوقتي',
                  style: TextStyle(fontSize: 15, color: Colors.white,
                      decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========== شاشة التسجيل ==========
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String _userType = 'راكب';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _register() async {
    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'password': _passwordController.text,
          'type': _userType,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم التسجيل بنجاح! 🎉'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message']), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('مش قادر يتصل بالسيرفر'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFF8C00),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8C00),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('حساب جديد',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _userType = 'راكب'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _userType == 'راكب' ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('راكب',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold,
                                  color: _userType == 'راكب' ? Colors.white : Colors.black)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _userType = 'سائق'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: _userType == 'سائق' ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('سائق',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold,
                                  color: _userType == 'سائق' ? Colors.white : Colors.black)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildField('الاسم الكامل', Icons.person, _nameController),
              const SizedBox(height: 12),
              _buildField('رقم التليفون', Icons.phone, _phoneController, type: TextInputType.phone),
              const SizedBox(height: 12),
              _buildField('كلمة السر', Icons.lock, _passwordController, obscure: true),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('سجل دلوقتي',
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String hint, IconData icon, TextEditingController controller,
      {TextInputType type = TextInputType.text, bool obscure = false}) {
    return TextField(
      controller: controller,
      textAlign: TextAlign.right,
      keyboardType: type,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: Icon(icon),
      ),
    );
  }
}

// ========== شاشة الراكب ==========
class RiderScreen extends StatefulWidget {
  const RiderScreen({super.key});

  @override
  State<RiderScreen> createState() => _RiderScreenState();
}

class _RiderScreenState extends State<RiderScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  List<String> _fromSuggestions = [];
  List<String> _toSuggestions = [];
  bool _showFromSuggestions = false;
  bool _showToSuggestions = false;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    socket.on('trip_accepted', (data) {
      setState(() => _searching = false);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TripScreen(
              from: _fromController.text,
              to: _toController.text,
              price: _priceController.text,
              driver: data['driverName'] ?? 'السائق',
            ),
          ),
        );
      }
    });

    socket.on('trip_rejected', (data) {
      setState(() => _searching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('السائق رفض الطلب'), backgroundColor: Colors.red),
        );
      }
    });
  }

  void _filterFrom(String query) {
    setState(() {
      _fromSuggestions = tantaAreas.where((area) => area.contains(query)).toList();
      _showFromSuggestions = query.isNotEmpty;
    });
  }

  void _filterTo(String query) {
    setState(() {
      _toSuggestions = tantaAreas.where((area) => area.contains(query)).toList();
      _showToSuggestions = query.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8C00),
        title: const Text('طلب فسحة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen(isDriver: false)));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 220,
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(30.7865, 31.0004),
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.fosha.app',
                ),
                const MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(30.7865, 31.0004),
                      child: Icon(Icons.electric_rickshaw, color: Color(0xFFFF8C00), size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _fromController,
                    textAlign: TextAlign.right,
                    onChanged: _filterFrom,
                    decoration: InputDecoration(
                      hintText: 'من فين؟',
                      prefixIcon: const Icon(Icons.location_on, color: Colors.green),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (_showFromSuggestions && _fromSuggestions.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: _fromSuggestions.map((area) {
                          return ListTile(
                            title: Text(area, textAlign: TextAlign.right),
                            leading: const Icon(Icons.location_on, color: Colors.green, size: 18),
                            onTap: () {
                              setState(() {
                                _fromController.text = area;
                                _showFromSuggestions = false;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _toController,
                    textAlign: TextAlign.right,
                    onChanged: _filterTo,
                    decoration: InputDecoration(
                      hintText: 'فين رايح؟',
                      prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (_showToSuggestions && _toSuggestions.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: _toSuggestions.map((area) {
                          return ListTile(
                            title: Text(area, textAlign: TextAlign.right),
                            leading: const Icon(Icons.location_on, color: Colors.red, size: 18),
                            onTap: () {
                              setState(() {
                                _toController.text = area;
                                _showToSuggestions = false;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _priceController,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'السعر اللي عايزه (جنيه)',
                      prefixIcon: const Icon(Icons.attach_money, color: Color(0xFFFF8C00)),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _searching ? null : () {
                        if (_fromController.text.isEmpty ||
                            _toController.text.isEmpty ||
                            _priceController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('من فضلك اكمل كل البيانات'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        setState(() => _searching = true);
                        socket.emit('request_trip', {
                          'from': _fromController.text,
                          'to': _toController.text,
                          'price': _priceController.text,
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('جاري البحث عن سائق...'),
                            backgroundColor: Color(0xFFFF8C00),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8C00),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: _searching
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          : const Icon(Icons.electric_rickshaw, color: Colors.white, size: 28),
                      label: Text(_searching ? 'بيدور على سائق...' : 'دور على فسحة',
                          style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== شاشة تتبع الرحلة ==========
class TripScreen extends StatefulWidget {
  final String from;
  final String to;
  final String price;
  final String driver;

  const TripScreen({
    super.key,
    required this.from,
    required this.to,
    required this.price,
    required this.driver,
  });

  @override
  State<TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<TripScreen> {
  int _status = 0;

  final List<String> _statusText = [
    'السائق في الطريق إليك...',
    'أنت في الفسحة...',
    'وصلت بالسلامة! 🎉',
  ];

  final List<Color> _statusColors = [
    Colors.orange,
    Colors.blue,
    Colors.green,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8C00),
        title: const Text('تتبع الرحلة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 250,
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(30.7865, 31.0004),
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.fosha.app',
                ),
                const MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(30.7865, 31.0004),
                      child: Icon(Icons.electric_rickshaw, color: Color(0xFFFF8C00), size: 40),
                    ),
                    Marker(
                      point: LatLng(30.7900, 31.0050),
                      child: Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _statusColors[_status].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _statusColors[_status]),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.circle, color: _statusColors[_status], size: 12),
                        const SizedBox(width: 8),
                        Text(_statusText[_status],
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                                color: _statusColors[_status])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(widget.from, style: const TextStyle(fontSize: 15)),
                          const Icon(Icons.location_on, color: Colors.green),
                        ]),
                        const Divider(),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(widget.to, style: const TextStyle(fontSize: 15)),
                          const Icon(Icons.location_on, color: Colors.red),
                        ]),
                        const Divider(),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('${widget.price} جنيه',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          const Icon(Icons.attach_money, color: Color(0xFFFF8C00)),
                        ]),
                        const Divider(),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(widget.driver, style: const TextStyle(fontSize: 15)),
                          const Icon(Icons.person, color: Colors.grey),
                        ]),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (_status < 2)
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => setState(() => _status++),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8C00),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('تحديث الحالة',
                            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (_status == 2)
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RatingScreen(driver: widget.driver)),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('تم — قيّم السائق',
                            style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========== شاشة التقييم ==========
class RatingScreen extends StatefulWidget {
  final String driver;
  const RatingScreen({super.key, required this.driver});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8C00),
        title: const Text('قيّم الرحلة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              backgroundColor: Color(0xFFFF8C00),
              radius: 40,
              child: Icon(Icons.person, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 16),
            Text(widget.driver,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('كيف كانت رحلتك؟',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFF8C00),
                    size: 48,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _commentController,
              textAlign: TextAlign.right,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'اكتب تعليقك هنا...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('شكراً على تقييمك! 🌟'), backgroundColor: Colors.green),
                  );
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8C00),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ابعت التقييم',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== شاشة البروفايل ==========
class ProfileScreen extends StatelessWidget {
  final bool isDriver;
  const ProfileScreen({super.key, required this.isDriver});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8C00),
        title: const Text('البروفايل',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFFFF8C00),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 60, color: Color(0xFFFF8C00)),
                  ),
                  const SizedBox(height: 12),
                  Text(currentUser['name'] ?? 'اسم المستخدم',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(isDriver ? 'سائق فسحة' : 'راكب فسحة',
                      style: const TextStyle(fontSize: 16, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _infoTile(Icons.phone, 'رقم التليفون', currentUser['phone'] ?? currentUser['phone'] ?? currentUser['phone'] ?? currentUser['phone'] ?? currentUser['phone'] ?? '01012345678'),
                  _infoTile(Icons.location_on, 'المنطقة', 'طنطا'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        socket.disconnect();
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text('تسجيل الخروج',
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFF8C00)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

// ========== شاشة السائق ==========
class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  final List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    socket.emit('driver_online', {'name': 'محمد السائق'});
    socket.on('new_trip_request', (data) {
      setState(() {
        _requests.add(Map<String, dynamic>.from(data));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF8C00),
        title: const Text('الطلبات الجديدة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen(isDriver: true)));
            },
          ),
        ],
      ),
      body: _requests.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.electric_rickshaw, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('مفيش طلبات دلوقتي',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _requests.length,
              itemBuilder: (context, index) {
                final req = _requests[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8C00),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('${req['price']} جنيه',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            ),
                            const Row(
                              children: [
                                Text('راكب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                SizedBox(width: 8),
                                CircleAvatar(
                                  backgroundColor: Color(0xFFFF8C00),
                                  radius: 20,
                                  child: Icon(Icons.person, color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          Text(req['from'] ?? '', style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on, color: Colors.green, size: 18),
                        ]),
                        const SizedBox(height: 4),
                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          Text(req['to'] ?? '', style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          const Icon(Icons.location_on, color: Colors.red, size: 18),
                        ]),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  socket.emit('reject_trip', {'riderSocketId': req['riderSocketId']});
                                  setState(() => _requests.removeAt(index));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم رفض الطلب'), backgroundColor: Colors.red),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade50,
                                  foregroundColor: Colors.red,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('رفض', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  socket.emit('accept_trip', {
                                    'riderSocketId': req['riderSocketId'],
                                    'driverName': 'محمد السائق',
                                  });
                                  setState(() => _requests.removeAt(index));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('تم قبول الطلب! 🎉'), backgroundColor: Colors.green),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('قبول', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}