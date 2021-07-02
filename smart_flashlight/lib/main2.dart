// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_ble_lib/flutter_ble_lib.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
//
// final bleManagerProvider = FutureProvider<BleManager>((_) async {
//   final bleManager = BleManager();
//   await bleManager.createClient();
//   return bleManager;
// });
//
// final scanResultProvider = StreamProvider<ScanResult>((ref) async* {
//   final bleManager = await ref.watch(bleManagerProvider.future);
//   yield* bleManager.startPeripheralScan(allowDuplicates: false);
// });
//
// final connectionStateProvider = StreamProvider.family<PeripheralConnectionState, Peripheral>(
//   (ref, peripheral) => peripheral.observeConnectionState(
//     emitCurrentValue: true,
//     completeOnDisconnect: true,
//   ),
// );
//
// final scanResultsProvider = StateProvider<List<ScanResult>>((ref) => []);
//
// void main() async {
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return ProviderScope(
//       child: MaterialApp(
//         debugShowCheckedModeBanner: false,
//         title: 'Flutter Demo',
//         theme: ThemeData(
//           primarySwatch: Colors.blue,
//         ),
//         home: HomeScreenWrapper(),
//       ),
//     );
//   }
// }
//
// class HomeScreenWrapper extends StatefulWidget {
//   @override
//   _HomeScreenWrapperState createState() => _HomeScreenWrapperState();
// }
//
// class _HomeScreenWrapperState extends State<HomeScreenWrapper> {
//   StreamSubscription _scanSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//     _scanSubscription = context.read(scanResultProvider.stream).listen((scanResult) async {
//       if (scanResult.peripheral?.name == 'Smart Flashlight') {
//         if (!await scanResult.peripheral.isConnected()) {
//           scanResult.peripheral.connect();
//         }
//         final currentState = context.read(scanResultsProvider).state;
//         final equalConnections =
//             currentState.where((e) => e.peripheral.identifier == scanResult.peripheral.identifier);
//         if (equalConnections.isEmpty) {
//           context.read(scanResultsProvider).state = currentState..add(scanResult);
//         } else {
//           context.read(scanResultsProvider).state = currentState
//             ..removeWhere((e) => e.peripheral.identifier == scanResult.peripheral.identifier)
//             ..add(scanResult);
//         }
//       }
//     });
//   }
//
//   @override
//   void dispose() {
//     _scanSubscription?.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return HomeScreen2();
//   }
// }
//
// class HomeScreen2 extends ConsumerWidget {
//   const HomeScreen2({Key key}) : super(key: key);
//
//   Widget build(BuildContext context, ScopedReader watch) {
//     final scanResults = watch(scanResultsProvider).state;
//
//     final body = ScanResultScreen(scanResults: scanResults);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Smart Flashlight'),
//       ),
//       body: body,
//     );
//   }
// }
//
// class ScanResultScreen extends StatelessWidget {
//   final List<ScanResult> scanResults;
//   const ScanResultScreen({
//     Key key,
//     @required this.scanResults,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       itemCount: scanResults.length,
//       itemBuilder: (context, index) => Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
//         child: ScanResultCard(scanResult: scanResults[index]),
//       ),
//     );
//   }
// }
//
// class ScanResultCard extends ConsumerWidget {
//   final ScanResult scanResult;
//   const ScanResultCard({
//     Key key,
//     @required this.scanResult,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context, ScopedReader watch) {
//     final theme = Theme.of(context);
//     final textTheme = theme.textTheme;
//
//     final connectionState = watch(connectionStateProvider(scanResult.peripheral));
//
//     final connectableText = scanResult.isConnectable
//         ? Text(
//             'connectable',
//             style: textTheme.bodyText1.copyWith(color: Colors.green),
//           )
//         : Text(
//             'not connectable',
//             style: textTheme.bodyText1.copyWith(color: Colors.red),
//           );
//
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           children: [
//             Text(
//               scanResult.peripheral?.name ?? 'Unknown',
//               style: textTheme.headline4,
//             ),
//             SizedBox(height: 4.0),
//             Text(
//               scanResult.peripheral?.identifier ?? 'No Address',
//               style: textTheme.bodyText2,
//             ),
//             SizedBox(height: 4.0),
//             connectableText,
//             if (scanResult.isConnectable) ...[
//               SizedBox(
//                 height: 16.0,
//               ),
//               TextButton(
//                 onPressed: () async {
//                   if (!await scanResult.peripheral.isConnected()) {
//                     scanResult.peripheral.connect();
//                   }
//                 },
//                 child: Text('Connect'),
//               )
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
