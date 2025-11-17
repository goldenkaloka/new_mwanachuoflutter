-- Optimize messages table for better performance

-- Add index on conversation_id and created_at for faster message retrieval
CREATE INDEX IF NOT EXISTS idx_messages_conversation_created 
    ON public.messages(conversation_id, created_at DESC);

-- Add index on sender_id for faster sender queries
CREATE INDEX IF NOT EXISTS idx_messages_sender 
    ON public.messages(sender_id);

-- Add index on is_read for unread count queries
CREATE INDEX IF NOT EXISTS idx_messages_conversation_unread 
    ON public.messages(conversation_id, is_read) WHERE is_read = false;

-- Add composite index for unread messages by recipient
CREATE INDEX IF NOT EXISTS idx_messages_unread_not_sender 
    ON public.messages(conversation_id, sender_id, is_read) 
    WHERE is_read = false;

-- Add index on content for full-text search (case-insensitive)
CREATE INDEX IF NOT EXISTS idx_messages_content_search 
    ON public.messages USING gin(to_tsvector('english', content));

-- Add index on conversations for faster queries
CREATE INDEX IF NOT EXISTS idx_conversations_user1 
    ON public.conversations(user1_id, last_message_time DESC);

CREATE INDEX IF NOT EXISTS idx_conversations_user2 
    ON public.conversations(user2_id, last_message_time DESC);

-- Create a function to efficiently count unread messages
CREATE OR REPLACE FUNCTION public.get_unread_count(
    p_conversation_id UUID,
    p_user_id UUID
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    unread_count INTEGER;
BEGIN
    SELECT COUNT(*)::INTEGER INTO unread_count
    FROM public.messages
    WHERE conversation_id = p_conversation_id
    AND sender_id != p_user_id
    AND is_read = false;
    
    RETURN COALESCE(unread_count, 0);
END;
$$;

-- Create a function to efficiently mark messages as read
CREATE OR REPLACE FUNCTION public.mark_conversation_messages_read(
    p_conversation_id UUID,
    p_user_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.messages
    SET is_read = true,
        read_at = NOW()
    WHERE conversation_id = p_conversation_id
    AND sender_id != p_user_id
    AND is_read = false;
END;
$$;

-- Create a function to update delivered_at for all messages in a conversation
CREATE OR REPLACE FUNCTION public.mark_messages_delivered(
    p_conversation_id UUID,
    p_user_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.messages
    SET delivered_at = NOW()
    WHERE conversation_id = p_conversation_id
    AND sender_id != p_user_id
    AND delivered_at IS NULL;
END;
$$;

-- Add trigger to automatically update conversation's last_message_time
CREATE OR REPLACE FUNCTION public.update_conversation_on_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.conversations
    SET last_message = NEW.content,
        last_message_time = NEW.created_at,
        updated_at = NOW()
    WHERE id = NEW.conversation_id;
    
    RETURN NEW;
END;
$$;

-- Create trigger
DROP TRIGGER IF EXISTS trigger_update_conversation_on_message ON public.messages;
CREATE TRIGGER trigger_update_conversation_on_message
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.update_conversation_on_message();

-- Grant execute permissions on the functions
GRANT EXECUTE ON FUNCTION public.get_unread_count(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_conversation_messages_read(UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_messages_delivered(UUID, UUID) TO authenticated;

