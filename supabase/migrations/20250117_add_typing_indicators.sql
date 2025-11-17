-- Add typing_indicators table for real-time typing status
CREATE TABLE IF NOT EXISTS public.typing_indicators (
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (conversation_id, user_id)
);

-- Enable RLS
ALTER TABLE public.typing_indicators ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only insert/update their own typing indicators
CREATE POLICY "Users can manage own typing indicators"
    ON public.typing_indicators
    FOR ALL
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can see typing indicators in their conversations
CREATE POLICY "Users can see typing indicators in their conversations"
    ON public.typing_indicators
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.conversations
            WHERE conversations.id = typing_indicators.conversation_id
            AND (conversations.user1_id = auth.uid() OR conversations.user2_id = auth.uid())
        )
    );

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_typing_indicators_conversation 
    ON public.typing_indicators(conversation_id);

-- Create index for timestamp queries
CREATE INDEX IF NOT EXISTS idx_typing_indicators_updated_at 
    ON public.typing_indicators(updated_at);

-- Enable real-time for typing indicators
ALTER PUBLICATION supabase_realtime ADD TABLE public.typing_indicators;

-- Auto-delete old typing indicators (older than 10 seconds)
-- This function will be called periodically to clean up stale indicators
CREATE OR REPLACE FUNCTION public.cleanup_old_typing_indicators()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    DELETE FROM public.typing_indicators
    WHERE updated_at < NOW() - INTERVAL '10 seconds';
END;
$$;

-- Create a scheduled job to clean up old typing indicators every 30 seconds
-- Note: pg_cron extension needs to be enabled for this
-- You can manually call this function or set up a cron job in Supabase dashboard
SELECT cron.schedule(
    'cleanup-typing-indicators',
    '30 seconds',
    $$SELECT public.cleanup_old_typing_indicators()$$
);

