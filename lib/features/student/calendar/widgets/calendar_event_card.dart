import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/models/event_model.dart';

// ── Category helpers ──────────────────────────────────────────────────────────

Color getCategoryColor(String cat) => switch (cat) {
  'Technical' => AppColors.categoryTechnical,
  'Cultural'  => AppColors.categoryCultural,
  'Sports'    => AppColors.categorySports,
  'Workshop'  => AppColors.categoryWorkshop,
  'Seminar'   => AppColors.categorySeminar,
  _           => AppColors.primary,
};

Color getCategoryBg(String cat) => switch (cat) {
  'Technical' => AppColors.primarySurface,
  'Cultural'  => AppColors.categoryCulturalBg,
  'Sports'    => AppColors.successSurface,
  'Workshop'  => AppColors.warningSurface,
  'Seminar'   => AppColors.categorySeminarBg,
  _           => AppColors.primarySurface,
};

// ══════════════════════════════════════════════════════════════════════════════
// CALENDAR EVENT CARD
// Design: timeline dot on left, time stamp, full event info, subtle tap state
// ══════════════════════════════════════════════════════════════════════════════

class CalendarEventCard extends StatefulWidget {
  final EventModel event;
  final int index;

  const CalendarEventCard({
    super.key,
    required this.event,
    this.index = 0,
  });

  @override
  State<CalendarEventCard> createState() => _CalendarEventCardState();
}

class _CalendarEventCardState extends State<CalendarEventCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = getCategoryColor(widget.event.category);
    final bg    = getCategoryBg(widget.event.category);

    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() => _pressed = false),
      onTapCancel: ()  => setState(() => _pressed = false),
      onTap:       ()  => context.push('/event/${widget.event.id}'),
      child: AnimatedScale(
        scale:    _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Timeline column ─────────────────────────────────────────
              _TimelineColumn(
                color: color,
                time: widget.event.time,
                isFirst: widget.index == 0,
              ),

              const SizedBox(width: 12),

              // ── Card body ───────────────────────────────────────────────
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    color: _pressed
                        ? AppColors.surfaceAlt
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: _pressed
                          ? color.withOpacity(0.3)
                          : AppColors.divider,
                    ),
                    boxShadow: _pressed
                        ? []
                        : [
                      const BoxShadow(
                        color: AppColors.cardShadow,
                        blurRadius: 14,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Top: category bar + poster thumbnail ────────────
                      _CardTop(event: widget.event, color: color, bg: bg),

                      // ── Bottom: info rows ───────────────────────────────
                      _CardBottom(event: widget.event, color: color),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Timeline column ───────────────────────────────────────────────────────────

class _TimelineColumn extends StatelessWidget {
  final Color  color;
  final String time;
  final bool   isFirst;

  const _TimelineColumn({
    required this.color,
    required this.time,
    required this.isFirst,
  });

  @override
  Widget build(BuildContext context) {
    final parts = time.split(' ');          // ['9:00', 'AM']
    final hhmm  = parts[0];                 // '9:00'
    final ampm  = parts.length > 1 ? parts[1] : '';

    return SizedBox(
      width: 44,
      child: Column(
        children: [
          // Time text
          Text(
            hhmm,
            style: AppTextStyles.labelS.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          Text(
            ampm,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          // Dot
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          // Line below dot
          Container(
            width: 2,
            height: 80,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end:   Alignment.bottomCenter,
                colors: [
                  color.withOpacity(0.25),
                  color.withOpacity(0.0),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card top section ──────────────────────────────────────────────────────────

class _CardTop extends StatelessWidget {
  final EventModel event;
  final Color color;
  final Color bg;

  const _CardTop({
    required this.event,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    event.category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                // Event title
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelM.copyWith(
                    fontSize: 15,
                    height: 1.3,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Poster thumbnail with rounded corners
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              event.posterUrl,
              width: 54,
              height: 54,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 54,
                height: 54,
                color: bg,
                child: Icon(Icons.image_outlined, color: color, size: 22),
              ),
              loadingBuilder: (_, child, progress) =>
              progress == null
                  ? child
                  : Container(
                width: 54, height: 54,
                color: AppColors.surfaceAlt,
                child: const Center(
                  child: SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card bottom section ───────────────────────────────────────────────────────

class _CardBottom extends StatelessWidget {
  final EventModel event;
  final Color color;

  const _CardBottom({required this.event, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        children: [
          // Venue row
          _InfoRow(
            icon: Icons.location_on_rounded,
            text: event.venue,
          ),
          const SizedBox(height: 6),
          // Bottom row: registrations + registered badge
          Row(
            children: [
              _InfoRow(
                icon: Icons.people_outline_rounded,
                text: '${event.registrationCount} registered',
                flex: false,
              ),
              const Spacer(),
              if (event.isRegistered)
                _GoingBadge()
              else
                _ViewButton(color: color),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  final bool     flex;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.flex = true,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: flex ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        if (flex)
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption,
            ),
          )
        else
          Text(text, style: AppTextStyles.caption),
      ],
    );
    return content;
  }
}

// ── Going badge ───────────────────────────────────────────────────────────────

class _GoingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.successSurface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
          color: AppColors.success.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle_rounded,
            size: 11, color: AppColors.success),
        const SizedBox(width: 4),
        Text(
          'Going',
          style: AppTextStyles.labelS.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ],
    ),
  );
}

// ── View button (when not registered) ────────────────────────────────────────

class _ViewButton extends StatelessWidget {
  final Color color;
  const _ViewButton({required this.color});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'View',
        style: AppTextStyles.labelS.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
      const SizedBox(width: 2),
      Icon(Icons.arrow_forward_rounded, size: 13, color: color),
    ],
  );
}
