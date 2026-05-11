import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:abonmu_app/services/api_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  // Filter values
  DateTime _startDate = DateTime(2026, 2, 1);
  DateTime _endDate = DateTime(2026, 2, 28);
  String _selectedCategory = 'Semua Kategori';
  String _selectedType = 'Semua Jenis';
  String _selectedProduct = 'Semua Produk';

  // Data for dropdowns
  List<String> _categories = ['Semua Kategori'];
  List<Map<String, dynamic>> _products = [
    {'id': 'Semua Produk', 'name': 'Semua Produk'}
  ];

  // Report data
  Map<String, dynamic>? _productionReport;
  Map<String, dynamic>? _financialReport;

  bool _loading = false;
  bool _loadingFilters = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFilters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFilters() async {
    setState(() {
      _loadingFilters = true;
      _errorMessage = null;
    });

    try {
      final categoriesData = await _api.get('/api/reports/categories');
      final productsData = await _api.get('/api/reports/products');

      setState(() {
        _categories = [
          'Semua Kategori',
          ...(categoriesData['data'] as List? ?? [])
        ];
        _products = [
          {'id': 'Semua Produk', 'name': 'Semua Produk'},
          ...(productsData['data'] as List? ?? []),
        ];
        _loadingFilters = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loadingFilters = false;
      });
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _loading = true;
      _productionReport = null;
      _financialReport = null;
      _errorMessage = null;
    });

    final startDateStr =
        '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}';
    final endDateStr =
        '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')}';

    try {
      if (_tabController.index == 0) {
        // Production Report
        final response = await _api.post('/api/reports/production', {
          'start_date': startDateStr,
          'end_date': endDateStr,
          'category': _selectedCategory,
          'type': _selectedType,
          'product_id': _selectedProduct != 'Semua Produk'
              ? int.parse(_selectedProduct)
              : null,
        });
        setState(() {
          _productionReport = response['data'];
          _loading = false;
        });
      } else {
        // Financial Report
        final response = await _api.post('/api/reports/financial', {
          'start_date': startDateStr,
          'end_date': endDateStr,
        });
        setState(() {
          _financialReport = response['data'];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  String formatRupiah(dynamic amount) {
    if (amount == null) return 'Rp 0';

    try {
      double value = 0;
      if (amount is String) {
        value = double.tryParse(amount) ?? 0;
      } else if (amount is int) {
        value = amount.toDouble();
      } else if (amount is double) {
        value = amount;
      } else {
        return 'Rp 0';
      }

      final formatter = NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      );
      return formatter.format(value);
    } catch (e) {
      return 'Rp 0';
    }
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Laporan'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '📊 Produksi'),
            Tab(text: '💰 Keuangan'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Panel
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child:
                          _buildDateButton('Tanggal Mulai', _startDate, true),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateButton('Tanggal Akhir', _endDate, false),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Category Filter (only for production tab)
                if (_tabController.index == 0) ...[
                  _buildDropdown('Kategori', _selectedCategory, _categories,
                      (value) {
                    setState(() => _selectedCategory = value!);
                  }),
                  const SizedBox(height: 12),
                  _buildDropdown('Jenis', _selectedType,
                      ['Semua Jenis', 'rutin', 'pesanan'], (value) {
                    setState(() => _selectedType = value!);
                  }),
                  const SizedBox(height: 12),
                  _buildProductDropdown(),
                ],

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _generateReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Tampilkan Laporan',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Result Area
          Expanded(
            child: _loadingFilters
                ? const Center(child: CircularProgressIndicator())
                : _buildResult(),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton(String label, DateTime date, bool isStart) {
    return GestureDetector(
      onTap: () => _selectDate(context, isStart),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  Text(formatDate(date), style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items,
      Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Text(label),
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildProductDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedProduct,
          isExpanded: true,
          hint: const Text('Produk'),
          items: _products.map((product) {
            return DropdownMenuItem(
              value: product['id'].toString(),
              child: Text(product['name']),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedProduct = value!),
        ),
      ),
    );
  }

  Widget _buildResult() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _generateReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_tabController.index == 0 && _productionReport != null) {
      return _buildProductionReport();
    } else if (_tabController.index == 1 && _financialReport != null) {
      return _buildFinancialReport();
    }

    return const Center(
      child: Text('Pilih filter dan tekan Tampilkan Laporan'),
    );
  }

  Widget _buildProductionReport() {
    final summary = _productionReport!['summary'] as Map<String, dynamic>;
    final products = _productionReport!['production_by_product'] as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Periode
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.date_range, size: 20, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Periode: ${formatDate(_startDate)} - ${formatDate(_endDate)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Summary Stats
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Ringkasan Produksi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Total Produksi',
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              '${summary['total_production']}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const Text('bungkus',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Produksi Rutin',
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              '${summary['routine_production']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Text('bungkus',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Produksi Pesanan',
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              '${summary['order_production']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const Text('bungkus',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Total Transaksi: ',
                            style: TextStyle(color: Colors.grey)),
                        Text(
                          '${summary['total_transactions']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Production by Product
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Ringkasan per Produk',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (products.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('Tidak ada data produksi')),
                    )
                  else
                    ...products.map((item) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['product_name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Total',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)),
                                        Text(
                                            '${item['total_production']} bungkus'),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Rutin',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)),
                                        Text(
                                            '${item['routine_production']} bungkus'),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('Pesanan',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey)),
                                        Text(
                                            '${item['order_production']} bungkus'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialReport() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Periode
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.date_range, size: 20, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Periode: ${formatDate(_startDate)} - ${formatDate(_endDate)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Financial Summary
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Ringkasan Keuangan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Penjualan',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          formatRupiah(_financialReport!['total_sales']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pengeluaran',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          formatRupiah(_financialReport!['total_expenses']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Laba Bersih',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          formatRupiah(_financialReport!['net_profit']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sales by Product
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🛒 Penjualan per Produk',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if ((_financialReport!['sales_by_product'] as List).isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('Tidak ada data penjualan')),
                    )
                  else
                    ...(_financialReport!['sales_by_product'] as List)
                        .map((item) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['product_name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Terjual',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey)),
                                            Text(
                                                '${item['total_sold']} bungkus'),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Pendapatan',
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey)),
                                            Text(
                                              formatRupiah(
                                                  item['total_revenue']),
                                              style: const TextStyle(
                                                  color: Colors.green),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Expenses by Category
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📝 Pengeluaran per Kategori',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if ((_financialReport!['expenses_by_category'] as List)
                      .isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('Tidak ada data pengeluaran')),
                    )
                  else
                    ...(_financialReport!['expenses_by_category'] as List)
                        .map((item) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['category'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '${item['transaction_count']} transaksi',
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    formatRupiah(item['total_amount']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
