-- Rename existing tables if they exist to backup/legacy
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'messages') THEN
        ALTER TABLE public.messages RENAME TO messages_legacy;
    END IF;
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'conversations') THEN
        ALTER TABLE public.conversations RENAME TO conversations_legacy;
    END IF;
END $$;

-- Create conversations table
CREATE TABLE public.conversations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    participants UUID[] NOT NULL,
    last_message TEXT,
    last_message_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create messages table
CREATE TABLE public.messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT,
    type TEXT DEFAULT 'text', -- 'text', 'offer', 'image'
    metadata JSONB DEFAULT '{}'::jsonb, -- Store offer details: { amount, status: 'pending'|'accepted'|'rejected' }
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_conversations_participants ON public.conversations USING GIN(participants);
CREATE INDEX idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX idx_messages_sender_id ON public.messages(sender_id);

-- RLS Policies
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Conversations policies
CREATE POLICY "Users can view conversations they are part of"
    ON public.conversations FOR SELECT
    USING (auth.uid() = ANY(participants));

CREATE POLICY "Users can create conversations"
    ON public.conversations FOR INSERT
    WITH CHECK (auth.uid() = ANY(participants));

CREATE POLICY "Users can update conversations they are part of"
    ON public.conversations FOR UPDATE
    USING (auth.uid() = ANY(participants));

-- Messages policies
CREATE POLICY "Users can view messages in their conversations"
    ON public.messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.conversations c
            WHERE c.id = messages.conversation_id
            AND auth.uid() = ANY(c.participants)
        )
    );

CREATE POLICY "Users can insert messages in their conversations"
    ON public.messages FOR INSERT
    WITH CHECK (
        auth.uid() = sender_id AND
        EXISTS (
            SELECT 1 FROM public.conversations c
            WHERE c.id = conversation_id
            AND auth.uid() = ANY(c.participants)
        )
    );

CREATE POLICY "Users can update messages they sent"
    ON public.messages FOR UPDATE
    USING (auth.uid() = sender_id);

-- Function to update conversation timestamp on new message
CREATE OR REPLACE FUNCTION public.handle_new_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.conversations
    SET 
        last_message = NEW.content,
        last_message_at = NEW.created_at,
        updated_at = NEW.created_at
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new message
CREATE TRIGGER on_new_message
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_message();
