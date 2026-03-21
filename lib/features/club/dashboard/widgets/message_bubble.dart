import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe; // true = organizer (right-aligned)

  const MessageBubble({super.key, required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final isStudent = message.senderType == MessageSenderType.student;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Student avatar (left)
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primarySurface,
              child: Text(
                message.senderAlias[0].toUpperCase(),
                style: AppTextStyles.labelS
                    .copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Sender name
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 2),
                    child: Text(
                      message.senderAlias,
                      style: AppTextStyles.labelS.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                // Bubble
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    border: isMe
                        ? null
                        : Border.all(color: AppColors.divider),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.message,
                    style: AppTextStyles.bodyM.copyWith(
                      color: isMe
                          ? AppColors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ),

                // Timestamp
                Padding(
                  padding:
                      const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child:
                      Text(message.timestamp, style: AppTextStyles.caption),
                ),
              ],
            ),
          ),

          // Organizer avatar (right)
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primarySurface,
              child: const Icon(Icons.groups_rounded,
                  size: 16, color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}
