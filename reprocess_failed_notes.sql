-- Reset failed notes to re-trigger processing
-- We target notes that have "Error" in the description and 0 chunks

WITH notes_to_process AS (
    SELECT id 
    FROM course_notes 
    WHERE description LIKE '%Error%'
    -- AND uploaded_at > NOW() - INTERVAL '1 day' -- Optional safety
)
SELECT 
    net.http_post(
        url := 'https://yhuujolmbqvntzifoaed.supabase.co/functions/v1/process-course-notes',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'SUPABASE_SERVICE_ROLE_KEY' limit 1)
        ),
        body := jsonb_build_object(
            'note_id', id
        )
    )
FROM notes_to_process;
