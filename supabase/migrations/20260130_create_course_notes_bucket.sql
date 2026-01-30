-- Create the course_notes bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'course_notes', 
  'course_notes', 
  true, 
  104857600, -- 100MB limit
  ARRAY['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', 'image/jpeg', 'image/png']
) ON CONFLICT (id) DO NOTHING;

-- RLS Policies for course_notes bucket
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
USING (bucket_id = 'course_notes');

CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'course_notes');

CREATE POLICY "Users can update their own uploads"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'course_notes' AND auth.uid() = owner);

CREATE POLICY "Users can delete their own uploads"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'course_notes' AND auth.uid() = owner);
