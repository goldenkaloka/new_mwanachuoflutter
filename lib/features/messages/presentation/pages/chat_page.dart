import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mwanachuo/core/di/injection_container.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mwanachuo/features/auth/presentation/bloc/auth_state.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/chat_bloc.dart';
import 'package:mwanachuo/features/messages/presentation/bloc/presence_cubit.dart';
import 'package:mwanachuo/features/messages/domain/entities/message.dart'
    as domain;
import 'package:mwanachuo/features/messages/presentation/widgets/product_share_card.dart';
import 'package:mwanachuo/features/messages/presentation/widgets/offer_card.dart';
import 'package:mwanachuo/features/messages/presentation/widgets/deal_confirmation_card.dart';
import 'package:mwanachuo/features/products/domain/entities/product_entity.dart';
import 'package:mwanachuo/features/products/domain/entities/product_order.dart';
import 'package:uuid/uuid.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_cart_bloc.dart';
import 'package:mwanachuo/features/products/presentation/bloc/product_orders_bloc.dart';
import 'package:mwanachuo/features/products/presentation/bloc/offers_bloc.dart';
import 'package:mwanachuo/features/products/presentation/widgets/make_offer_dialog.dart';
import 'package:mwanachuo/features/messages/presentation/widgets/quick_checkout_bottom_sheet.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatPage extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  final double? initialOffer;
  final String? initialMessage;
  final ProductEntity? product;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.initialOffer,
    this.initialMessage,
    this.product,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialActions();
    });
  }

  void _handleInitialActions() {
    if (widget.initialOffer != null && widget.product != null) {
      context.read<OffersBloc>().add(
        CreateOffer(
          productId: widget.product!.id,
          sellerId: widget.otherUserId,
          conversationId: widget.conversationId,
          offerAmount: widget.initialOffer!,
          originalPrice: widget.product!.price,
          message: widget.initialMessage?.isEmpty == true
              ? null
              : widget.initialMessage,
        ),
      );
    } else if (widget.product != null) {
      // Just share the product
      context.read<ChatBloc>().add(
        SendMessage(
          conversationId: widget.conversationId,
          content: "I'm interested in this product: ${widget.product!.title}",
          type: domain.MessageType.productShare,
          metadata: {
            'type': 'product_share',
            'product_id': widget.product!.id,
            'product_title': widget.product!.title,
            'product_price': widget.product!.price,
            'product_image': widget.product!.images.isNotEmpty
                ? widget.product!.images.first
                : null,
            'seller_id': widget.product!.sellerId,
          },
        ),
      );
    } else if (widget.initialMessage != null) {
      _messageController.text = widget.initialMessage!;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatBloc>().add(
      SendMessage(conversationId: widget.conversationId, content: text),
    );
    _messageController.clear();
  }

  void _showMakeOfferDialog(domain.Message message) {
    final metadata = message.metadata;
    final productId = metadata['product_id'] as String;
    final productTitle = metadata['product_title'] as String;
    final originalPrice = (metadata['product_price'] as num).toDouble();
    final sellerId = metadata['seller_id'] as String? ?? widget.otherUserId;

    showDialog(
      context: context,
      builder: (context) => MakeOfferDialog(
        originalPrice: originalPrice,
        productTitle: productTitle,
        onSendOffer: (amount, offerMessage) {
          this.context.read<OffersBloc>().add(
            CreateOffer(
              productId: productId,
              sellerId: sellerId,
              conversationId: widget.conversationId,
              offerAmount: amount,
              originalPrice: originalPrice,
              message: offerMessage.isEmpty ? null : offerMessage,
            ),
          );
        },
      ),
    );
  }

  void _showQuickCheckout(domain.Message message) {
    final metadata = message.metadata;
    final productId = metadata['product_id'] as String;
    final productTitle = metadata['product_title'] as String;
    final price = (metadata['product_price'] as num).toDouble();
    final productImage = metadata['product_image'] as String?;
    final sellerId = metadata['seller_id'] as String? ?? widget.otherUserId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QuickCheckoutBottomSheet(
        productTitle: productTitle,
        productImage: productImage,
        price: price,
        sellerName: widget.otherUserName,
        onConfirm: (paymentMethod, deliveryMethod, address, phone) {
          final orderItem = ProductOrderItem(
            id: sl<Uuid>().v4(),
            orderId: '', // Will be set by backend/repository
            productId: productId,
            productSnapshot: metadata,
            quantity: 1,
            priceAtTime: price,
            createdAt: DateTime.now(),
          );

          this.context.read<ProductOrdersBloc>().add(
            PlaceProductOrder(
              sellerId: sellerId,
              items: [orderItem],
              paymentMethod: paymentMethod,
              deliveryMethod: deliveryMethod,
              deliveryAddress: address,
              deliveryPhone: phone,
              conversationId: widget.conversationId,
              offerId: metadata['offer_id'],
              agreedPrice: price,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<ChatBloc>()
            ..add(LoadMessages(widget.conversationId))
            ..add(MarkAsRead(widget.conversationId)),
        ),
        BlocProvider(
          create: (_) =>
              sl<PresenceCubit>()..subscribeToUserPresence(widget.otherUserId),
        ),
        BlocProvider(create: (_) => sl<OffersBloc>()),
        BlocProvider(create: (_) => sl<ProductCartBloc>()),
        BlocProvider(create: (_) => sl<ProductOrdersBloc>()),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFECE5DD),
        appBar: AppBar(
          backgroundColor: const Color(0xFF075E54),
          foregroundColor: Colors.white,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                backgroundImage: widget.otherUserAvatar != null
                    ? NetworkImage(widget.otherUserAvatar!)
                    : null,
                child: widget.otherUserAvatar == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  BlocBuilder<PresenceCubit, PresenceState>(
                    builder: (context, state) {
                      String status = 'Offline';
                      if (state is PresenceLoaded) {
                        if (state.user.isOnline) {
                          status = 'Online';
                        } else if (state.user.lastSeenAt != null) {
                          status =
                              'Last seen ${timeago.format(state.user.lastSeenAt!)}';
                        }
                      }
                      return Text(
                        status,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // In a real app, this opens a product selector
                // For demonstration, we'll send a mock product share
                context.read<ChatBloc>().add(
                  SendMessage(
                    conversationId: widget.conversationId,
                    content: 'Check out this product!',
                    type: domain.MessageType.productShare,
                    metadata: {
                      'product_id': 'demo-prod-123',
                      'product_title': 'MacBook Pro 2020',
                      'product_price': 500000,
                      'product_image': 'https://placehold.co/400',
                      'seller_id': widget.otherUserId,
                    },
                  ),
                );
              },
              tooltip: 'Share Product',
            ),
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ChatError) {
                    return Center(child: Text('Error: ${state.message}'));
                  } else if (state is ChatLoaded) {
                    final messages = state.messages;
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final authState = context.read<AuthBloc>().state;
                        final currentUserId = authState is Authenticated
                            ? authState.user.id
                            : null;
                        final isMe = message.senderId == currentUserId;

                        // Auto-scroll to bottom on new messages
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients &&
                              index == messages.length - 1) {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        });

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: _buildMessageContent(
                              message,
                              isMe,
                              currentUserId,
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.grey),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: const CircleAvatar(
              backgroundColor: Color(0xFF075E54),
              radius: 24,
              child: Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(
    domain.Message message,
    bool isMe,
    String? currentUserId,
  ) {
    switch (message.type) {
      case domain.MessageType.productShare:
        final sellerId = message.metadata['seller_id'];
        final showActions = currentUserId != null && currentUserId != sellerId;

        return ProductShareCard(
          message: message,
          showActions: showActions,
          onViewProduct: () {
            // context.push('/product/${message.metadata['product_id']}');
          },
          onMakeOffer: () {
            _showMakeOfferDialog(message);
          },
          onAddToCart: () {
            _showQuickCheckout(message);
          },
        );
      case domain.MessageType.offer:
        return OfferCard(
          message: message,
          isMe: isMe,
          onAccept: () {
            final offerId = message.metadata['offer_id'];
            if (offerId != null) {
              context.read<OffersBloc>().add(AcceptOffer(offerId));
            }
          },
          onDecline: () {
            final offerId = message.metadata['offer_id'];
            if (offerId != null) {
              context.read<OffersBloc>().add(DeclineOffer(offerId));
            }
          },
          onCounter: () {
            // Open counter offer dialog using MakeOfferDialog with current offer as base
            _showMakeOfferDialog(message);
          },
        );

      case domain.MessageType.dealConfirmed:
        return DealConfirmationCard(
          message: message,
          isMe: isMe,
          onPayNow: () {
            // Navigate to checkout or pay
            // context.push('/checkout/${message.metadata['order_id']}');
          },
          onViewOrder: () {
            // Navigate to order details
            // context.push('/order/${message.metadata['order_id']}');
          },
        );
      case domain.MessageType.text:
      default:
        return _MessageBubble(message: message, isMe: isMe);
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final domain.Message message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFDCF8C6) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(isMe ? 12 : 0),
          bottomRight: Radius.circular(isMe ? 0 : 12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('HH:mm').format(message.createdAt),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  message.isRead ? Icons.done_all : Icons.done,
                  size: 16,
                  color: message.isRead ? Colors.blue : Colors.grey,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
