import '../models/chat_models.dart';

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
