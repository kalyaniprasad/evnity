import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme.dart';
import '../../providers/club_providers.dart';
import '../../models/club_message.dart';
import '../../dashboard/widgets/message_bubble.dart';

class ClubDiscussionScreen extends ConsumerStatefulWidget {
  final String eventId;
  const ClubDiscussionScreen({super.key, required this.eventId});

  @override
  ConsumerState<ClubDiscussionScreen> createState() =>
      _ClubDiscussionScreenState();
}

class _ClubDiscussionScreenState
    extends ConsumerState<ClubDiscussionScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    ref.read(clubDiscussionProvider.notifier).sendMessage(text);
    _inputCtrl.clear();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(clubDiscussionProvider);
    final event = ref
        .watch(clubEventsProvider)
        .where((e) => e.id == widget.eventId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.cardShadow,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event?.title ?? 'Discussion',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.headingM,
            ),
            Text('${messages.length} messages',
                style: AppTextStyles.caption),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_outline_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${messages.length + 3}',
                    style: AppTextStyles.labelS
                        .copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // ── Messages List ─────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              itemCount: messages.length,
              itemBuilder: (ctx, i) {
                final msg = messages[i];
                final isMe =
                    msg.senderType == ClubMessageSender.organizer;
                return MessageBubble(message: msg, isMe: isMe);
              },
            ),
          ),

          // ── Input Bar ────────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(24),
                        border:
                            Border.all(color: AppColors.divider),
                      ),
                      child: TextField(
                        controller: _inputCtrl,
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        style: AppTextStyles.bodyM
                            .copyWith(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Reply to participants...',
                          hintStyle: AppTextStyles.bodyM,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.32),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: AppColors.white, size: 20),
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
