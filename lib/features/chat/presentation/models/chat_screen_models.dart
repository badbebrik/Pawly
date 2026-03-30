import '../../data/chat_repository_models.dart';

class ChatInboxState {
  const ChatInboxState({
    required this.items,
    required this.nextCursor,
    required this.isLoadingMore,
    required this.petIdFilter,
  });

  factory ChatInboxState.initial({String? petIdFilter}) => ChatInboxState(
        items: const <ChatListItem>[],
        nextCursor: null,
        isLoadingMore: false,
        petIdFilter: petIdFilter,
      );

  final List<ChatListItem> items;
  final String? nextCursor;
  final bool isLoadingMore;
  final String? petIdFilter;

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;
  bool get isEmpty => items.isEmpty;

  ChatInboxState copyWith({
    List<ChatListItem>? items,
    String? nextCursor,
    bool? isLoadingMore,
    bool clearNextCursor = false,
    String? petIdFilter,
  }) {
    return ChatInboxState(
      items: items ?? this.items,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      petIdFilter: petIdFilter ?? this.petIdFilter,
    );
  }
}

class ChatConversationState {
  const ChatConversationState({
    required this.currentUserId,
    required this.conversation,
    required this.messages,
    required this.hasMoreMessages,
    required this.isLoadingMoreMessages,
    required this.isMarkingRead,
    required this.isSendingMessage,
  });

  final String currentUserId;
  final ChatListItem conversation;
  final List<ChatMessageItem> messages;
  final bool hasMoreMessages;
  final bool isLoadingMoreMessages;
  final bool isMarkingRead;
  final bool isSendingMessage;

  String? get lastMessageId =>
      messages.isEmpty ? conversation.lastMessageId : messages.last.messageId;

  bool get canMarkRead => lastMessageId != null && lastMessageId!.isNotEmpty;

  ChatConversationState copyWith({
    String? currentUserId,
    ChatListItem? conversation,
    List<ChatMessageItem>? messages,
    bool? hasMoreMessages,
    bool? isLoadingMoreMessages,
    bool? isMarkingRead,
    bool? isSendingMessage,
  }) {
    return ChatConversationState(
      currentUserId: currentUserId ?? this.currentUserId,
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      isLoadingMoreMessages:
          isLoadingMoreMessages ?? this.isLoadingMoreMessages,
      isMarkingRead: isMarkingRead ?? this.isMarkingRead,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
    );
  }
}
