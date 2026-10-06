import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/reading_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/bp_category.dart';
import '../models/reading.dart';
import '../services/bp_parser.dart';
import '../theme.dart';

/// Confirms OCR results for a new reading, or edits an existing one.
class ReadingFormScreen extends StatefulWidget {
  const ReadingFormScreen({
    super.key,
    required this.repository,
    this.existing,
    this.imagePath,
    this.parsed,
  });

  final ReadingRepository repository;
  final Reading? existing;
  final String? imagePath;

  /// OCR result for a freshly captured photo; null for manual entry/edit.
  final ParsedReading? parsed;

  @override
  State<ReadingFormScreen> createState() => _ReadingFormScreenState();
}

class _ReadingFormScreenState extends State<ReadingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sys;
  late final TextEditingController _dia;
  late final TextEditingController _pulse;
  late final TextEditingController _note;
  late DateTime _when;
  bool _saving = false;

  String? get _imagePath => widget.existing?.imagePath ?? widget.imagePath;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final p = widget.parsed;
    _sys = TextEditingController(text: '${e?.systolic ?? p?.systolic ?? ''}');
    _dia = TextEditingController(text: '${e?.diastolic ?? p?.diastolic ?? ''}');
    _pulse = TextEditingController(text: '${e?.pulse ?? p?.pulse ?? ''}');
    _note = TextEditingController(text: e?.note ?? '');
    _when = e?.timestamp ?? DateTime.now();
    for (final c in [_sys, _dia]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_sys, _dia, _pulse, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when),
    );
    if (time == null) return;
    setState(() {
      _when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    var path = _imagePath;
    if (path != null && !widget.repository.isStoredPhoto(path)) {
      path = await widget.repository.storePhoto(path);
    }
    final note = _note.text.trim();
    await widget.repository.save(
      Reading(
        id: widget.existing?.id,
        timestamp: _when,
        systolic: int.parse(_sys.text),
        diastolic: int.parse(_dia.text),
        pulse: int.tryParse(_pulse.text),
        imagePath: path,
        note: note.isEmpty ? null : note,
      ),
    );
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteReadingTitle),
        content: Text(l.deleteReadingBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.delete(widget.existing!);
    if (mounted) Navigator.pop(context);
  }

  String? Function(String?) _range(int min, int max, {bool required = true}) {
    final l = AppLocalizations.of(context);
    return (value) {
      if (value == null || value.isEmpty) {
        return required ? l.required : null;
      }
      final n = int.tryParse(value);
      if (n == null || n < min || n > max) {
        return l.rangeError('$min', '$max');
      }
      return null;
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sys = int.tryParse(_sys.text);
    final dia = int.tryParse(_dia.text);
    final category = sys != null && dia != null
        ? BpCategory.of(sys, dia)
        : null;
    final ocrIncomplete = widget.parsed != null && !widget.parsed!.isComplete;
    final imagePath = _imagePath;

    return GradientBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.existing == null ? l.newReading : l.editReading),
          actions: [
            if (widget.existing != null)
              IconButton(
                tooltip: l.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: _delete,
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (imagePath != null)
                GestureDetector(
                  onTap: () => _showPhoto(context, imagePath),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _photo(
                      imagePath,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => SizedBox(
                        height: 80,
                        child: Center(child: Text(l.photoUnavailable)),
                      ),
                    ),
                  ),
                ),
              if (widget.parsed != null) ...[
                const SizedBox(height: 12),
                Card(
                  color: ocrIncomplete
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      ocrIncomplete ? l.ocrIncomplete : l.ocrComplete,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _numberField(
                      _sys,
                      l.systolic,
                      'mmHg',
                      _range(60, 300),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _numberField(
                      _dia,
                      l.diastolic,
                      'mmHg',
                      _range(30, 200),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _numberField(
                _pulse,
                l.pulseOptional,
                'bpm',
                _range(25, 250, required: false),
              ),
              const SizedBox(height: 12),
              if (category != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: CircleAvatar(backgroundColor: category.color),
                    label: Text(category.label(l)),
                  ),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(
                  DateFormat.yMMMEd(l.localeName).add_Hm().format(_when),
                ),
                trailing: const Icon(Icons.edit_calendar),
                onTap: _pickDateTime,
              ),
              TextFormField(
                controller: _note,
                decoration: InputDecoration(
                  labelText: l.noteOptional,
                  hintText: l.noteHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(l.save),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    String suffix,
    String? Function(String?) validator,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
      validator: validator,
    );
  }
}

void _showPhoto(BuildContext context, String path) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(),
        backgroundColor: Colors.black,
        body: InteractiveViewer(
          maxScale: 6,
          child: Center(child: _photo(path)),
        ),
      ),
    ),
  );
}

/// Picked images are blob URLs in the browser preview, files on device.
Widget _photo(
  String path, {
  double? height,
  BoxFit? fit,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  return kIsWeb
      ? Image.network(
          path,
          height: height,
          fit: fit,
          errorBuilder: errorBuilder,
        )
      : Image.file(
          File(path),
          height: height,
          fit: fit,
          errorBuilder: errorBuilder,
        );
}
