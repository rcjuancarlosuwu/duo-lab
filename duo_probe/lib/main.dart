import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foldable/foldable.dart';

import 'hinge_demo.dart';
import 'nav_bars.dart';
import 'theme.dart';
import 'widgets.dart';

void main() => runApp(const DuoProbeApp());

const _tag = '[DUO_PROBE]';

void probeLog(String message) => debugPrint('$_tag $message');

final appNavigatorKey = GlobalKey<NavigatorState>();
final keyboardProbeFocus = FocusNode(debugLabel: 'keyboardProbe');
final tabIndexNotifier = ValueNotifier<int>(0);

Future<void> showProbeDialog(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    backgroundColor: kPanel,
    title: const Text('Wide dialog'),
    content: const SizedBox(
      width: 4000,
      child: MeasuredBox(
        label: 'dialogContent',
        height: 120,
        color: Color(0xFF3A2A17),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Close'),
      ),
    ],
  ),
);

Future<void> showProbeDatePicker(BuildContext context) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2030),
  );
  probeLog('datePicker result=$picked');
}

Future<void> showProbeSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: kPanel,
  builder: (context) => const MeasuredBox(
    label: 'bottomSheet',
    height: 240,
    color: Color(0xFF17323A),
  ),
);

class DuoProbeApp extends StatefulWidget {
  const DuoProbeApp({super.key});

  @override
  State<DuoProbeApp> createState() => _DuoProbeAppState();
}

class _DuoProbeAppState extends State<DuoProbeApp> with WidgetsBindingObserver {
  final _condition = TextEditingController();

  late final File _commandFile;
  Timer? _commandPoll;
  int _rootBuilds = 0;
  String? _lastSnapshot;
  String _lifecycle = 'none';
  String _lifecycleAt = '-';
  bool _portraitLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onHotkey);
    navBarLog = probeLog;
    _commandFile = File('${Directory.systemTemp.path}/duo_probe_command');
    probeLog('commandFile ${_commandFile.path}');
    _commandPoll = Timer.periodic(
      const Duration(milliseconds: 400),
      (_) => _pollCommandFile(),
    );
    probeLog('App.initState at ${DateTime.now().toIso8601String()}');
  }

  Future<void> _pollCommandFile() async {
    if (!_commandFile.existsSync()) return;
    final command = _commandFile.readAsStringSync().trim();
    _commandFile.deleteSync();
    if (command.isEmpty) return;
    await _runCommand(command);
  }

  Future<void> _runCommand(String command) async {
    probeLog('command $command');

    final segments = command.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return;
    final context = appNavigatorKey.currentContext;
    final argument = segments.length > 1 ? segments[1] : null;

    switch (segments.first) {
      case 'tab':
        tabIndexNotifier.value = int.tryParse(argument ?? '') ?? 0;
      case 'dialog':
        if (context != null) showProbeDialog(context);
      case 'datepicker':
        if (context != null) showProbeDatePicker(context);
      case 'sheet':
        if (context != null) showProbeSheet(context);
      case 'keyboard':
        tabIndexNotifier.value = 1;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => keyboardProbeFocus.requestFocus(),
        );
      case 'dismiss':
        keyboardProbeFocus.unfocus();
        final navigator = appNavigatorKey.currentState;
        if (navigator != null && navigator.canPop()) navigator.pop();
      case 'orient':
        await _applyOrientation(argument);
      case 'condition':
        _condition.text = Uri.decodeComponent(argument ?? '');
        setState(() {});
      case 'log':
        setState(() {});
      case 'measure':
        _measureOverlays();
      case 'foldable':
        final data = await Foldable.snapshot;
        probeLog(
          'foldableSnapshot isFoldable=${data.isFoldable} '
          'status=${data.status.name} angle=${data.angleDegrees} '
          'hSizeClass=${data.horizontalSizeClass.name} '
          'vSizeClass=${data.verticalSizeClass.name} '
          'supportLevel=${data.capabilities.supportLevel.name} '
          'hingeApi=${data.capabilities.hingeApiPresent} '
          'regionApi=${data.capabilities.regionApiPresent} '
          'angleVerified=${data.capabilities.angleUnitVerified} '
          'strategy=${data.capabilities.strategy} '
          'regions=${data.regions.map((r) => "${r.kind.name}:${r.bounds}:${r.isActive}").toList()} '
          'bridgedFeatures=${data.displayFeatures.length}',
        );
        probeLog('foldableNativeApi ${await Foldable.debugDumpNativeApi()}');
    }
  }

  void _measureOverlays() {
    const wanted = [
      'DatePickerDialog',
      'AlertDialog',
      'Dialog',
      'BottomSheet',
      'Material',
    ];
    final screen = MediaQuery.sizeOf(context).width;

    void visit(Element element) {
      final name = element.widget.runtimeType.toString();
      if (wanted.contains(name)) {
        final box = element.renderObject;
        if (box is RenderBox && box.hasSize) {
          final size = box.size;
          if (size.width < screen) {
            probeLog(
              'measured $name ${size.width} x ${size.height} '
              'screenWidth=$screen ratio=${(size.width / screen).toStringAsFixed(3)}',
            );
          }
        }
      }
      element.visitChildren(visit);
    }

    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return;
    visit(root);
  }

  Future<void> _applyOrientation(String? mode) async {
    final orientations = switch (mode) {
      'portrait' => [DeviceOrientation.portraitUp],
      'landscape' => [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      _ => DeviceOrientation.values,
    };
    await SystemChrome.setPreferredOrientations(orientations);
    probeLog('setPreferredOrientations $mode -> $orientations');
    setState(() => _portraitLocked = mode == 'portrait');
  }

  bool _onHotkey(KeyEvent event) {
    if (event is! KeyDownEvent || !HardwareKeyboard.instance.isControlPressed) {
      return false;
    }
    final context = appNavigatorKey.currentContext;
    if (context == null) return false;

    final label = event.logicalKey.keyLabel.toLowerCase();
    probeLog('hotkey $label');

    switch (label) {
      case '1':
      case '2':
      case '3':
      case '4':
        tabIndexNotifier.value = int.parse(label) - 1;
      case 'd':
        showProbeDialog(context);
      case 'p':
        showProbeDatePicker(context);
      case 's':
        showProbeSheet(context);
      case 'k':
        tabIndexNotifier.value = 1;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => keyboardProbeFocus.requestFocus(),
        );
      case 'x':
        keyboardProbeFocus.unfocus();
        final navigator = appNavigatorKey.currentState;
        if (navigator != null && navigator.canPop()) navigator.pop();
      case 'l':
        probeLog('manual dump requested');
        setState(() {});
      default:
        return false;
    }
    return true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_onHotkey);
    _commandPoll?.cancel();
    probeLog('App.dispose at ${DateTime.now().toIso8601String()}');
    _condition.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final at = DateTime.now().toIso8601String();
    probeLog('lifecycle=${state.name} at $at');
    setState(() {
      _lifecycle = state.name;
      _lifecycleAt = at;
    });
  }

  @override
  void didChangeMetrics() {
    probeLog('didChangeMetrics at ${DateTime.now().toIso8601String()}');
  }

  Future<void> _togglePortraitLock(bool value) async {
    await SystemChrome.setPreferredOrientations(
      value ? [DeviceOrientation.portraitUp] : DeviceOrientation.values,
    );
    probeLog('setPreferredOrientations portraitUpOnly=$value');
    setState(() => _portraitLocked = value);
  }

  Map<String, dynamic> _snapshot(BuildContext context, BoxConstraints c) {
    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final padding = MediaQuery.paddingOf(context);
    final insets = MediaQuery.viewInsetsOf(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final features = MediaQuery.of(context).displayFeatures;

    return {
      'condition': _condition.text,
      'rootBuilds': _rootBuilds,
      'size': {'width': size.width, 'height': size.height},
      'devicePixelRatio': dpr,
      'physicalPixels': {
        'width': size.width * dpr,
        'height': size.height * dpr,
      },
      'padding': {
        'left': padding.left,
        'top': padding.top,
        'right': padding.right,
        'bottom': padding.bottom,
      },
      'paddingAsymmetric': padding.left != padding.right,
      'viewInsets': {
        'left': insets.left,
        'top': insets.top,
        'right': insets.right,
        'bottom': insets.bottom,
      },
      'viewPadding': {
        'left': viewPadding.left,
        'top': viewPadding.top,
        'right': viewPadding.right,
        'bottom': viewPadding.bottom,
      },
      'displayFeatures': features
          .map(
            (f) => {
              'bounds': f.bounds.toString(),
              'type': f.type.name,
              'state': f.state.name,
            },
          )
          .toList(),
      'orientation': MediaQuery.orientationOf(context).name,
      'textScalerScaleOf14': MediaQuery.textScalerOf(context).scale(14),
      'platformBrightness': MediaQuery.platformBrightnessOf(context).name,
      'rootConstraints': {
        'minWidth': c.minWidth,
        'maxWidth': c.maxWidth,
        'minHeight': c.minHeight,
        'maxHeight': c.maxHeight,
      },
      'lifecycle': {'state': _lifecycle, 'at': _lifecycleAt},
      'portraitLocked': _portraitLocked,
    };
  }

  @override
  Widget build(BuildContext context) {
    _rootBuilds++;
    return MaterialApp(
      title: 'duo_probe',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: buildProbeTheme(),
      home: LayoutBuilder(
        builder: (context, constraints) {
          final snapshot = _snapshot(context, constraints);
          final encoded = const JsonEncoder.withIndent('  ').convert(snapshot);

          if (encoded != _lastSnapshot) {
            _lastSnapshot = encoded;
            probeLog('snapshot ${jsonEncode(snapshot)}');
          }

          return ProbeHome(
            snapshot: snapshot,
            encoded: encoded,
            condition: _condition,
            portraitLocked: _portraitLocked,
            onPortraitLockChanged: _togglePortraitLock,
          );
        },
      ),
    );
  }
}

class ProbeHome extends StatefulWidget {
  const ProbeHome({
    super.key,
    required this.snapshot,
    required this.encoded,
    required this.condition,
    required this.portraitLocked,
    required this.onPortraitLockChanged,
  });

  final Map<String, dynamic> snapshot;
  final String encoded;
  final TextEditingController condition;
  final bool portraitLocked;
  final ValueChanged<bool> onPortraitLockChanged;

  @override
  State<ProbeHome> createState() => _ProbeHomeState();
}

class _ProbeHomeState extends State<ProbeHome> {
  @override
  void initState() {
    super.initState();
    tabIndexNotifier.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    tabIndexNotifier.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() => setState(() {});

  int get _tab => tabIndexNotifier.value;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: ConditionBanner(
              controller: widget.condition,
              rebuilds: widget.snapshot['rootBuilds'] as int,
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                MetricsPage(
                  snapshot: widget.snapshot,
                  encoded: widget.encoded,
                  portraitLocked: widget.portraitLocked,
                  onPortraitLockChanged: widget.onPortraitLockChanged,
                ),
                const OverlaysPage(),
                const LayoutPage(),
                const StatePage(),
                const HingeDemoPage(),
                const NavBarsPage(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kAccent,
        foregroundColor: kBg,
        onPressed: () => probeLog('FAB tapped'),
        child: const Icon(Icons.straighten),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab.clamp(0, 3),
        type: BottomNavigationBarType.fixed,
        backgroundColor: kPanel,
        selectedItemColor: kAccent,
        unselectedItemColor: kMuted,
        selectedLabelStyle: const TextStyle(fontSize: 10.5, fontFamily: kMono),
        unselectedLabelStyle: const TextStyle(fontSize: 10.5, fontFamily: kMono),
        onTap: (i) => tabIndexNotifier.value = i,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Metrics'),
          BottomNavigationBarItem(icon: Icon(Icons.layers), label: 'Overlays'),
          BottomNavigationBarItem(
            icon: Icon(Icons.aspect_ratio),
            label: 'Layout',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.save), label: 'State'),
        ],
      ),
    );
  }
}

class MetricsPage extends StatelessWidget {
  const MetricsPage({
    super.key,
    required this.snapshot,
    required this.encoded,
    required this.portraitLocked,
    required this.onPortraitLockChanged,
  });

  final Map<String, dynamic> snapshot;
  final String encoded;
  final bool portraitLocked;
  final ValueChanged<bool> onPortraitLockChanged;

  @override
  Widget build(BuildContext context) {
    final size = snapshot['size'] as Map;
    final physical = snapshot['physicalPixels'] as Map;
    final p = snapshot['padding'] as Map;
    final insets = snapshot['viewInsets'] as Map;
    final viewPadding = snapshot['viewPadding'] as Map;
    final constraints = snapshot['rootConstraints'] as Map;
    final lifecycle = snapshot['lifecycle'] as Map;
    final features = snapshot['displayFeatures'] as List;

    final width = size['width'] as num;
    final height = size['height'] as num;
    final overBreakpoint = width > 600;
    final asymmetric = snapshot['paddingAsymmetric'] as bool;

    final padding = EdgeInsets.fromLTRB(
      (p['left'] as num).toDouble(),
      (p['top'] as num).toDouble(),
      (p['right'] as num).toDouble(),
      (p['bottom'] as num).toDouble(),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 150),
      children: [
        Row(
          children: [
            Expanded(
              child: BigStat(
                label: 'logical size',
                value: '${_n(width)} x ${_n(height)}',
                unit: 'lp',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BigStat(
                label: 'device pixel ratio',
                value: '${snapshot['devicePixelRatio']}',
                unit: 'x',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: BigStat(
                label: 'width > 600 breakpoint',
                value: overBreakpoint ? 'YES' : 'NO',
                tone: overBreakpoint ? Tone.good : Tone.bad,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: BigStat(
                label: 'displayFeatures',
                value: features.isEmpty ? 'EMPTY' : '${features.length}',
                tone: features.isEmpty ? Tone.bad : Tone.good,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const FoldablePanel(),
        Panel(
          title: 'display features',
          accent: features.isEmpty ? kBad : kGood,
          trailing: StatusPill(
            features.isEmpty ? 'NOT POPULATED' : 'POPULATED',
            tone: features.isEmpty ? Tone.bad : Tone.good,
          ),
          children: [
            if (features.isEmpty)
              const Text(
                'displayFeatures: [] (EMPTY)',
                style: TextStyle(
                  fontFamily: kMono,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kBad,
                ),
              )
            else
              for (final f in features.cast<Map>())
                MetricRow(
                  '${f['type']} / ${f['state']}',
                  '${f['bounds']}',
                  tone: Tone.good,
                ),
          ],
        ),
        Panel(
          title: 'padding',
          accent: asymmetric ? kBad : kAccent,
          trailing: StatusPill(
            asymmetric ? 'ASYMMETRIC' : 'SYMMETRIC',
            tone: asymmetric ? Tone.bad : Tone.good,
          ),
          children: [
            PaddingDiagram(padding: padding, label: 'safe area'),
            const SizedBox(height: 8),
            MetricRow(
              'padding.left',
              '${p['left']}',
              tone: asymmetric ? Tone.bad : Tone.neutral,
            ),
            MetricRow('padding.top', '${p['top']}'),
            MetricRow(
              'padding.right',
              '${p['right']}',
              tone: asymmetric ? Tone.bad : Tone.neutral,
            ),
            MetricRow('padding.bottom', '${p['bottom']}'),
          ],
        ),
        Panel(
          title: 'geometry',
          children: [
            MetricRow(
              'physical px',
              '${_n(physical['width'] as num)} x ${_n(physical['height'] as num)}',
            ),
            MetricRow(
              'orientation',
              '${snapshot['orientation']}',
              tone: Tone.accent,
            ),
            MetricRow('textScaler.scale(14)', '${snapshot['textScalerScaleOf14']}'),
            MetricRow('platformBrightness', '${snapshot['platformBrightness']}'),
          ],
        ),
        Panel(
          title: 'insets',
          children: [
            MetricRow(
              'viewInsets',
              'L${insets['left']} T${insets['top']} R${insets['right']} B${insets['bottom']}',
              tone: (insets['bottom'] as num) > 0 ? Tone.warn : Tone.neutral,
            ),
            MetricRow(
              'viewPadding',
              'L${viewPadding['left']} T${viewPadding['top']} R${viewPadding['right']} B${viewPadding['bottom']}',
            ),
          ],
        ),
        Panel(
          title: 'root LayoutBuilder vs MediaQuery',
          children: [
            MetricRow(
              'constraints max',
              '${_n(constraints['maxWidth'] as num)} x ${_n(constraints['maxHeight'] as num)}',
            ),
            MetricRow(
              'constraints min',
              '${_n(constraints['minWidth'] as num)} x ${_n(constraints['minHeight'] as num)}',
            ),
            MetricRow(
              'delta vs sizeOf',
              '${_n((constraints['maxWidth'] as num) - width)} x '
                  '${_n((constraints['maxHeight'] as num) - height)}',
              tone:
                  (constraints['maxWidth'] as num) == width &&
                      (constraints['maxHeight'] as num) == height
                  ? Tone.good
                  : Tone.warn,
            ),
          ],
        ),
        Panel(
          title: 'lifecycle',
          children: [
            MetricRow(
              'state',
              '${lifecycle['state']}',
              tone: switch (lifecycle['state']) {
                'resumed' => Tone.good,
                'inactive' => Tone.warn,
                'paused' || 'hidden' => Tone.bad,
                _ => Tone.neutral,
              },
            ),
            MetricRow('at', '${lifecycle['at']}'),
            MetricRow('root builds', '${snapshot['rootBuilds']}'),
          ],
        ),
        Panel(
          title: 'controls',
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: encoded));
                      probeLog('clipboard copy');
                    },
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy JSON'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        probeLog('manual dump ${jsonEncode(snapshot)}'),
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('Log now'),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: portraitLocked,
              activeThumbColor: kAccent,
              onChanged: onPortraitLockChanged,
              title: const Text(
                'SystemChrome portraitUp only',
                style: TextStyle(fontFamily: kMono, fontSize: 12),
              ),
            ),
          ],
        ),
        Panel(
          title: 'raw json',
          children: [
            SelectableText(
              encoded,
              style: const TextStyle(
                fontFamily: kMono,
                fontSize: 9.5,
                color: kMuted,
                height: 1.35,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _n(num v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

class FoldablePanel extends StatefulWidget {
  const FoldablePanel({super.key});

  @override
  State<FoldablePanel> createState() => _FoldablePanelState();
}

class _FoldablePanelState extends State<FoldablePanel> {
  String _nativeDump = 'not dumped';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FoldableData>(
      stream: Foldable.changes,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final rows = <Widget>[
          MetricRow('stream state', snapshot.connectionState.name),
          if (snapshot.hasError)
            MetricRow('stream error', '${snapshot.error}', tone: Tone.bad),
          if (data == null)
            const MetricRow(
              'FoldableData',
              'none emitted',
              tone: Tone.bad,
            )
          else ...[
            MetricRow(
              'isFoldable',
              '${data.isFoldable}',
              tone: data.isFoldable ? Tone.good : Tone.bad,
            ),
            MetricRow('status', data.status.name, tone: Tone.accent),
            MetricRow(
              'angleDegrees',
              '${data.angleDegrees}',
              tone: data.angleDegrees == null ? Tone.bad : Tone.good,
            ),
            MetricRow('horizontalSizeClass', data.horizontalSizeClass.name),
            MetricRow('verticalSizeClass', data.verticalSizeClass.name),
            MetricRow('supportLevel', data.capabilities.supportLevel.name),
            MetricRow('hingeApiPresent', '${data.capabilities.hingeApiPresent}'),
            MetricRow(
              'regionApiPresent',
              '${data.capabilities.regionApiPresent}',
            ),
            MetricRow(
              'angleUnitVerified',
              '${data.capabilities.angleUnitVerified}',
              tone: data.capabilities.angleUnitVerified
                  ? Tone.good
                  : Tone.warn,
            ),
            MetricRow('strategy', data.capabilities.strategy),
            MetricRow('regions', '${data.regions.length}'),
            for (final r in data.regions)
              MetricRow(
                '  ${r.kind.name} active=${r.isActive}',
                '${r.bounds}',
              ),
            MetricRow(
              'bridged displayFeatures',
              '${data.displayFeatures.length}',
            ),
          ],
        ];

        probeLog(
          'foldable connection=${snapshot.connectionState.name} '
          'isFoldable=${data?.isFoldable} status=${data?.status.name} '
          'angle=${data?.angleDegrees} regions=${data?.regions.length}',
        );

        return Panel(
          title: 'package:foldable 1.0.4',
          accent: (data?.isFoldable ?? false) ? kGood : kWarn,
          trailing: StatusPill(
            (data?.isFoldable ?? false) ? 'HINGE' : 'NO HINGE',
            tone: (data?.isFoldable ?? false) ? Tone.good : Tone.warn,
          ),
          children: [
            ...rows,
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                final dump = await Foldable.debugDumpNativeApi();
                probeLog('debugDumpNativeApi $dump');
                setState(() => _nativeDump = dump.toString());
              },
              child: const Text('debugDumpNativeApi()'),
            ),
            const SizedBox(height: 6),
            SelectableText(
              _nativeDump,
              style: const TextStyle(
                fontFamily: kMono,
                fontSize: 9.5,
                color: kMuted,
              ),
            ),
          ],
        );
      },
    );
  }
}

class OverlaysPage extends StatelessWidget {
  const OverlaysPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 150),
      children: [
        Panel(
          title: 'overlay width probes',
          children: [
            const Text(
              'Each overlay renders a LayoutBuilder that prints its own '
              'maxWidth next to the screen width, so a confined overlay is '
              'visible in the screenshot itself.',
              style: TextStyle(fontSize: 11.5, color: kMuted, height: 1.4),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () => showProbeDialog(context),
              child: const Text('AlertDialog (wide content)'),
            ),
            const SizedBox(height: 6),
            FilledButton(
              onPressed: () => showProbeDatePicker(context),
              child: const Text('showDatePicker'),
            ),
            const SizedBox(height: 6),
            FilledButton(
              onPressed: () => showProbeSheet(context),
              child: const Text('showModalBottomSheet'),
            ),
          ],
        ),
        const Panel(
          title: 'keyboard probe (#193096)',
          children: [KeyboardProbe()],
        ),
      ],
    );
  }

}

class MeasuredBox extends StatelessWidget {
  const MeasuredBox({
    super.key,
    required this.label,
    required this.height,
    required this.color,
  });

  final String label;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final ratio = constraints.maxWidth / screenWidth;
        probeLog(
          '$label maxWidth=${constraints.maxWidth} screenWidth=$screenWidth '
          'ratio=${ratio.toStringAsFixed(3)}',
        );
        return Container(
          height: height,
          color: color,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: kMono,
                  fontSize: 11,
                  color: kMuted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${constraints.maxWidth.toStringAsFixed(1)} / '
                '${screenWidth.toStringAsFixed(1)} lp',
                style: const TextStyle(
                  fontFamily: kMono,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const SizedBox(height: 6),
              StatusPill(
                '${(ratio * 100).toStringAsFixed(1)}% of screen width',
                tone: ratio > 0.9 ? Tone.good : Tone.warn,
              ),
            ],
          ),
        );
      },
    );
  }
}

class KeyboardProbe extends StatefulWidget {
  const KeyboardProbe({super.key});

  @override
  State<KeyboardProbe> createState() => _KeyboardProbeState();
}

class _KeyboardProbeState extends State<KeyboardProbe> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context);
    final up = insets.bottom > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () {
            keyboardProbeFocus.requestFocus();
            probeLog('keyboard requestFocus');
          },
          icon: const Icon(Icons.keyboard, size: 16),
          label: const Text('Focus TextField'),
        ),
        const SizedBox(height: 8),
        TextField(
          focusNode: keyboardProbeFocus,
          controller: _controller,
          style: const TextStyle(fontFamily: kMono, fontSize: 13),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            labelText: 'keyboard probe',
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: StatusPill(
            'viewInsets.bottom = ${insets.bottom}',
            tone: up ? Tone.good : Tone.neutral,
          ),
        ),
      ],
    );
  }
}

class LayoutPage extends StatelessWidget {
  const LayoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ListView(
      padding: const EdgeInsets.only(bottom: 150),
      children: [
        RulerStripe(height: 26),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Panel(
            title: 'edge to edge',
            children: [
              const Text(
                'The ruler above and below have zero horizontal padding. Any '
                'gap, letterbox or asymmetric inset shows as dead space at '
                'either end.',
                style: TextStyle(fontSize: 11.5, color: kMuted, height: 1.4),
              ),
              const SizedBox(height: 6),
              MetricRow(
                'MediaQuery width',
                size.width.toStringAsFixed(1),
                tone: Tone.accent,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final boxWidth = constraints.maxWidth;
              final boxHeight = boxWidth * 9 / 16;
              final wasted = 1 - (boxHeight / size.height);
              return Panel(
                title: 'AspectRatio 16:9',
                trailing: StatusPill(
                  '${(wasted * 100).toStringAsFixed(1)}% unused height',
                  tone: wasted > 0.6 ? Tone.bad : Tone.warn,
                ),
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        color: kPanelAlt,
                        border: Border.all(color: kAccent),
                      ),
                      child: const Placeholder(color: kAccent),
                    ),
                  ),
                  const SizedBox(height: 8),
                  MetricRow(
                    '16:9 box',
                    '${boxWidth.toStringAsFixed(1)} x ${boxHeight.toStringAsFixed(1)}',
                  ),
                  MetricRow('screen height', size.height.toStringAsFixed(1)),
                  MetricRow(
                    'unused height',
                    '${(wasted * 100).toStringAsFixed(1)}%',
                    tone: Tone.bad,
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        RulerStripe(height: 26),
      ],
    );
  }
}

class StatePage extends StatefulWidget {
  const StatePage({super.key});

  @override
  State<StatePage> createState() => _StatePageState();
}

class _StatePageState extends State<StatePage> {
  static int _instances = 0;

  final _controller = TextEditingController();
  final _scroll = ScrollController();
  late final int _instanceId;

  @override
  void initState() {
    super.initState();
    _instanceId = ++_instances;
    probeLog(
      'StatePage.initState instance=$_instanceId at ${DateTime.now().toIso8601String()}',
    );
  }

  @override
  void dispose() {
    probeLog(
      'StatePage.dispose instance=$_instanceId at ${DateTime.now().toIso8601String()}',
    );
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Panel(
            title: 'state preservation across fold',
            trailing: StatusPill(
              'instance #$_instanceId',
              tone: _instanceId == 1 ? Tone.good : Tone.bad,
            ),
            children: [
              MetricRow(
                'StatePage instances created',
                '$_instances',
                tone: _instances == 1 ? Tone.good : Tone.bad,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                style: const TextStyle(fontFamily: kMono, fontSize: 13),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  labelText: 'type here, scroll below, then fold',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 150),
            itemCount: 200,
            itemBuilder: (context, i) => Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: kPanel,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kBorder),
              ),
              child: Text(
                'row ${i.toString().padLeft(3, '0')}',
                style: const TextStyle(fontFamily: kMono, fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
