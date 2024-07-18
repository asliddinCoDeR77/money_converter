import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/currency_bloc.dart';
import '../bloc/currency_event.dart';
import '../bloc/currency_state.dart';
import '../models/currency.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CONVERTER"),
        centerTitle: true,
      ),
      body: BlocBuilder<CurrencyBloc, CurrencyState>(
        builder: (context, state) {
          if (state is CurrencyInitial) {
            context.read<CurrencyBloc>().add(FetchCurrencies());
            return const Center(child: CircularProgressIndicator());
          } else if (state is CurrencyLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CurrencyLoaded) {
            return CurrencyConverter(currencies: state.currencies);
          } else if (state is CurrencyError) {
            return Center(child: Text(state.message));
          } else {
            return const Center(child: Text("Unknown state"));
          }
        },
      ),
    );
  }
}

class CurrencyConverter extends StatefulWidget {
  final List<Currency> currencies;

  const CurrencyConverter({super.key, required this.currencies});

  @override
  _CurrencyConverterState createState() => _CurrencyConverterState();
}

class _CurrencyConverterState extends State<CurrencyConverter> {
  String?  _selectedCurrency;
  double _inputAmount = 1.0;
  double? _convertedAmount;
  final TextEditingController _searchController = TextEditingController();
  List<Currency> _filteredCurrencies = [];

  @override
  void initState() {
    super.initState();
    _filteredCurrencies = widget.currencies;
    _searchController.addListener(_filterCurrencies);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCurrencies() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCurrencies = widget.currencies.where((currency) {
        return currency.code.toLowerCase().contains(query);
      }).toList();

      if (query.isNotEmpty) {
        final exactMatch = _filteredCurrencies.firstWhere(
          (currency) => currency.code.toLowerCase() == query,
        );
        _selectedCurrency = exactMatch.code;
      }
    });
  }

  void _convertCurrency() {
    if (_selectedCurrency == null) {
      return;
    }

    final selectedCurrencyRate = widget.currencies
        .firstWhere((currency) => currency.code == _selectedCurrency)
        .rate;

    setState(() {
      _convertedAmount = _inputAmount * selectedCurrencyRate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextField( 
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search Currency ...",
              
                suffixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCurrency,
              hint: const Text("Select Currency"),
              onChanged: (value) {
                setState(() {
                  _selectedCurrency = value;
                });
              },
              items: _filteredCurrencies
                  .map((currency) => DropdownMenuItem(
                        value: currency.code,
                        child: Text(currency.code),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                  hintText: "Amount", border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _inputAmount = double.tryParse(value) ?? 1.0;
                });
              },
            ),
            const SizedBox(height: 10),
            if (_convertedAmount != null)
              Text(
                "Converted Amount: $_convertedAmount UZS",
                style: const TextStyle(fontSize: 20),
              ),
            const SizedBox(height: 200),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: _convertCurrency,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.change_circle,
                    color: Colors.white,
                  ),
                  Text(
                    "Convert",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
