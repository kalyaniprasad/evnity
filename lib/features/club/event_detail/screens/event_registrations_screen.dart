import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/repositories/event_repository.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../providers/club_providers.dart';
import '../../models/registration_field_model.dart';
import '../../models/club_event.dart';

class EventRegistrationsScreen extends ConsumerStatefulWidget {
  final String eventId;
  const EventRegistrationsScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventRegistrationsScreen> createState() =>
      _EventRegistrationsScreenState();
}

class _EventRegistrationsScreenState
    extends ConsumerState<EventRegistrationsScreen> {
  List<Map<String, dynamic>> _registrations = [];
  bool _isLoading = true;
  bool _isExporting = false;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRegistrations();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRegistrations() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(eventRepositoryProvider);
      final data = await repo.getEventRegistrations(widget.eventId);
      setState(() => _registrations = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading registrations: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ClubEvent? get _event {
    final events = ref.read(clubEventsProvider).valueOrNull ?? [];
    return events.where((e) => e.id == widget.eventId).firstOrNull;
  }

  List<RegistrationFieldModel> get _customFields {
    // We need to get event with registrationFields – pulling from student events provider
    // For now, reconstructing from the first registration's response keys
    return [];
  }

  List<Map<String, dynamic>> get _filteredRegistrations {
    if (_searchQuery.isEmpty) return _registrations;
    final q = _searchQuery.toLowerCase();
    return _registrations.where((r) {
      final name = (r['aliasName'] ?? r['name'] ?? '').toString().toLowerCase();
      final email = (r['email'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q);
    }).toList();
  }

  /// Parse and format a timestamp from ISO string or Firestore Timestamp
  String _formatTimestamp(dynamic raw) {
    if (raw == null || raw.toString().isEmpty) return '';
    try {
      DateTime dt;
      if (raw is String) {
        dt = DateTime.parse(raw).toLocal();
      } else {
        // Firestore Timestamp object has .toDate()
        dt = (raw as dynamic).toDate().toLocal() as DateTime;
      }
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return raw.toString();
    }
  }

  Future<void> _exportToExcel(List<RegistrationFieldModel> formFields) async {
    setState(() => _isExporting = true);
    try {
      final excel = Excel.createExcel();

      // ── Delete the auto-created default sheet ──────────────────────
      // Excel.createExcel() always creates a 'Sheet1' by default.
      // We must create our sheet FIRST, then delete the default.
      final sheet = excel['Registrations'];
      excel.setDefaultSheet('Registrations');
      excel.delete('Sheet1'); // Remove the duplicate default sheet

      // Build headers — default fields first
      final defaultHeaders = ['#', 'Name', 'Email', 'Year', 'Branch', 'Phone', 'Submitted At'];
      // Custom field headers
      final customHeaders = formFields.map((f) => f.label.isEmpty ? 'Field' : f.label).toList();
      final allHeaders = [...defaultHeaders, ...customHeaders];

      // Style the header row
      for (var i = 0; i < allHeaders.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(allHeaders[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#4F46E5'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      // Data rows
      for (var rowIdx = 0; rowIdx < _registrations.length; rowIdx++) {
        final reg = _registrations[rowIdx];
        final responses = (reg['responses'] as Map<String, dynamic>?) ?? {};

        final defaultValues = [
          (rowIdx + 1).toString(),
          reg['aliasName'] ?? reg['name'] ?? '',
          reg['email'] ?? '',
          reg['year'] ?? '',
          reg['branch'] ?? '',
          reg['phone'] ?? '',
          // Format the timestamp to a human-readable string
          _formatTimestamp(reg['submittedAt'] ?? reg['registeredAt']),
        ];

        final customValues = formFields.map((f) {
          final val = responses[f.id];
          if (val == null) return '';
          if (val is List) return val.join(', ');
          return val.toString();
        }).toList();

        final allValues = [...defaultValues, ...customValues];

        for (var colIdx = 0; colIdx < allValues.length; colIdx++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: colIdx, rowIndex: rowIdx + 1),
          );
          cell.value = TextCellValue(allValues[colIdx].toString());
        }
      }

      // Save file
      final dir = await getTemporaryDirectory();
      final eventName = _event?.title.replaceAll(RegExp(r'[^\w\s]'), '') ?? 'event';
      final filePath = '${dir.path}/${eventName}_registrations.xlsx';
      final fileBytes = excel.save();
      if (fileBytes == null) throw Exception('Excel generation failed');

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        subject: '${_event?.title ?? 'Event'} — Registrations',
        text: '${_registrations.length} registrations exported.',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Registrations', style: AppTextStyles.headingM),
            if (event != null)
              Text(event.title, style: AppTextStyles.caption),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Refresh',
            onPressed: _loadRegistrations,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isExporting
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : ElevatedButton.icon(
                    onPressed: () => _exportToExcel(_customFields),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Export'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      textStyle: AppTextStyles.labelS,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search + stats bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                // Stats row
                if (!_isLoading)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.08),
                          AppColors.primary.withValues(alpha: 0.04),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
                    ),
                    child: Row(
                      children: [
                        _StatChip(label: 'Total', value: '${_registrations.length}', icon: Icons.people_rounded),
                        const SizedBox(width: 16),
                        _StatChip(label: 'Shown', value: '${_filteredRegistrations.length}', icon: Icons.filter_list_rounded),
                      ],
                    ),
                  ),
                // Search field
                TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: AppTextStyles.bodyS,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    hintStyle: AppTextStyles.bodyS.copyWith(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRegistrations.isEmpty
                    ? _EmptyState(hasSearch: _searchQuery.isNotEmpty)
                    : RefreshIndicator(
                        onRefresh: _loadRegistrations,
                        child: ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRegistrations.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            final reg = _filteredRegistrations[i];
                            return _RegistrationCard(
                              index: i + 1,
                              registration: reg,
                              customFields: _customFields,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatChip({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: AppTextStyles.labelS.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasSearch ? Icons.search_off_rounded : Icons.people_outline_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hasSearch ? 'No results found' : 'No registrations yet',
            style: AppTextStyles.headingM,
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Try a different name or email.'
                : 'Students who register will appear here.',
            style: AppTextStyles.bodyM.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _RegistrationCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> registration;
  final List<RegistrationFieldModel> customFields;

  const _RegistrationCard({
    required this.index,
    required this.registration,
    required this.customFields,
  });

  @override
  State<_RegistrationCard> createState() => _RegistrationCardState();
}

class _RegistrationCardState extends State<_RegistrationCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final reg = widget.registration;
    final responses = (reg['responses'] as Map<String, dynamic>?) ?? {};
    final name = reg['aliasName'] ?? reg['name'] ?? 'Unknown';
    final email = reg['email'] ?? '';
    final year = reg['year'] ?? '';
    final branch = reg['branch'] ?? '';
    final phone = reg['phone'] ?? '';
    final submittedAt = _formatTs(reg['submittedAt'] ?? reg['registeredAt']);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isExpanded
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.divider.withValues(alpha: 0.5),
          width: _isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main row
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '#',
                        style: AppTextStyles.headingM.copyWith(
                          color: AppColors.primary,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '#${widget.index}',
                              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                name,
                                style: AppTextStyles.labelM,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: AppTextStyles.bodyS.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (year.isNotEmpty || branch.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                if (year.isNotEmpty) _MiniTag(year),
                                if (year.isNotEmpty && branch.isNotEmpty) const SizedBox(width: 6),
                                if (branch.isNotEmpty) _MiniTag(branch),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded details
          if (_isExpanded) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Default fields summary
                  _DetailRow(icon: Icons.phone_rounded, label: 'Phone', value: phone.isEmpty ? '—' : phone),
                  if (submittedAt.isNotEmpty)
                    _DetailRow(icon: Icons.schedule_rounded, label: 'Submitted', value: submittedAt),

                  // Custom form field responses
                  if (widget.customFields.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'FORM RESPONSES',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        fontSize: 9,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.customFields.map((field) {
                      final val = responses[field.id];
                      if (field.type == FormFieldType.fileUpload && val != null) {
                        return _FileResponseRow(label: field.label, url: val.toString());
                      }
                      return _DetailRow(
                        label: field.label.isEmpty ? 'Field' : field.label,
                        value: val == null ? '—' : (val is List ? val.join(', ') : val.toString()),
                      );
                    }),
                  ] else if (responses.isNotEmpty) ...[
                    // Fallback: show raw responses when formFields not loaded
                    const SizedBox(height: 12),
                    Text(
                      'RESPONSES',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        fontSize: 9,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...responses.entries.map((e) {
                      final val = e.value;
                      final valStr = val is List ? val.join(', ') : val.toString();
                      // Check if it looks like a URL
                      if (valStr.startsWith('https://') || valStr.startsWith('http://')) {
                        return _FileResponseRow(label: e.key, url: valStr);
                      }
                      return _DetailRow(label: e.key, value: valStr.isEmpty ? '—' : valStr);
                    }),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  const _MiniTag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;

  const _DetailRow({this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 8),
          ] else
            const SizedBox(width: 22),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyS.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _FileResponseRow extends StatelessWidget {
  final String label;
  final String url;
  const _FileResponseRow({required this.label, required this.url});

  bool get _isImage => CloudinaryService.isImageUrl(url);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          if (_isImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                url,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _linkFallback(context),
              ),
            )
          else
            _linkFallback(context),
          const SizedBox(height: 6),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 13),
                label: const Text('Open Link'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  textStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied!')),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 13),
                label: const Text('Copy'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.divider),
                  textStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linkFallback(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.insert_drive_file_rounded, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              url,
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Format a raw timestamp (ISO string or Firestore Timestamp) to readable form
String _formatTs(dynamic raw) {
  if (raw == null || raw.toString().isEmpty) return '';
  try {
    DateTime dt;
    if (raw is String) {
      dt = DateTime.parse(raw).toLocal();
    } else {
      dt = (raw as dynamic).toDate().toLocal() as DateTime;
    }
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  } catch (_) {
    return raw.toString();
  }
}
