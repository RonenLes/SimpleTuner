import 'package:flutter/material.dart';
import 'package:simple_tuner/features/tuner/frequency_readout.dart';
import 'package:simple_tuner/features/tuner/guitar_head_selector.dart';
import 'package:simple_tuner/features/tuner/needle_tuning_meter.dart';
import 'package:simple_tuner/features/tuner/tuner_controller.dart';
import 'package:simple_tuner/features/tuner/tuning_session_control.dart';
import 'package:simple_tuner/features/tunings/tuning_panel.dart';
import 'package:simple_tuner/features/tunings/tuning_preset.dart';

class TunerScreen extends StatefulWidget {
  const TunerScreen({super.key});

  @override
  State<TunerScreen> createState() => _TunerScreenState();
}

class _TunerScreenState extends State<TunerScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TunerController _tunerController;
  GuitarHeadLayout _headLayout = GuitarHeadLayout.threeByThree;

  @override
  void initState() {
    super.initState();
    _tunerController = TunerController();
  }

  @override
  void dispose() {
    _tunerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    return Scaffold(
      key: _scaffoldKey,
      drawer: wide
          ? null
          : Drawer(
              width: 330,
              child: SafeArea(
                child: _buildTuningPanel(closeAfterSelection: true),
              ),
            ),
      appBar: AppBar(
        leading: wide
            ? null
            : IconButton(
                tooltip: 'Open tunings',
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
        title: const Text('Simple Tuner'),
        actions: [
          ListenableBuilder(
            listenable: _tunerController,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(_tunerController.state.selectedTuning.name),
              ),
            ),
          ),
        ],
      ),
      body: wide
          ? Row(
              children: [
                SizedBox(width: 340, child: _buildTuningPanel()),
                Expanded(child: _buildTunerPane()),
              ],
            )
          : _buildTunerPane(compact: true),
    );
  }

  Widget _buildTunerPane({bool compact = false}) {
    return SingleChildScrollView(child: _buildTunerContent(compact: compact));
  }

  Widget _buildTunerContent({bool compact = false}) {
    return ListenableBuilder(
      listenable: _tunerController,
      builder: (context, _) {
        final state = _tunerController.state;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: compact
                  ? const EdgeInsets.fromLTRB(10, 6, 10, 10)
                  : const EdgeInsets.fromLTRB(24, 22, 24, 34),
              child: Column(
                children: [
                  GuitarHeadSelector(
                    tuning: state.selectedTuning,
                    match: state.match,
                    lockStatus: state.lockStatus,
                    selectedStringIndex: state.selectedStringIndex,
                    selectionMode: state.selectionMode,
                    layout: _headLayout,
                    onModeChanged: _tunerController.selectMode,
                    onLayoutChanged: (layout) =>
                        setState(() => _headLayout = layout),
                    onStringSelected: _tunerController.selectString,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 4 : 16),
                  NeedleTuningMeter(match: state.match, compact: compact),
                  FrequencyReadout(
                    match: state.match,
                    tuning: state.selectedTuning,
                    compact: compact,
                  ),
                  SizedBox(height: compact ? 6 : 22),
                  TuningSessionControl(controller: _tunerController.audioInput),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTuningPanel({bool closeAfterSelection = false}) {
    return ListenableBuilder(
      listenable: _tunerController,
      builder: (context, _) => TuningPanel(
        selectedTuning: _tunerController.state.selectedTuning,
        onSelected: (TuningPreset tuning) {
          _tunerController.selectTuning(tuning);
          if (closeAfterSelection) _scaffoldKey.currentState?.closeDrawer();
        },
      ),
    );
  }
}
