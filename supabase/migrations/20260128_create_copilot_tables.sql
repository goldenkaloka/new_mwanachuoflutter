-- Enable UUID extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pgvector extension for RAG
CREATE EXTENSION IF NOT EXISTS vector;

-- 1. Add year_of_study to student_profiles
ALTER TABLE student_profiles 
ADD COLUMN IF NOT EXISTS year_of_study INTEGER CHECK (year_of_study BETWEEN 1 AND 7);

-- Add index for year filtering
CREATE INDEX IF NOT EXISTS idx_student_profiles_year ON student_profiles(year_of_study);

-- 2. Create course_notes table
CREATE TABLE IF NOT EXISTS course_notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  course_id UUID REFERENCES courses(id) ON DELETE CASCADE,
  uploaded_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  file_type TEXT NOT NULL,
  year_relevance INTEGER CHECK (year_relevance BETWEEN 1 AND 7),
  study_readiness_score REAL DEFAULT 0 CHECK (study_readiness_score >= 0 AND study_readiness_score <= 100),
  download_count INTEGER DEFAULT 0,
  view_count INTEGER DEFAULT 0,
  is_official BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for course_notes
CREATE INDEX IF NOT EXISTS idx_course_notes_course ON course_notes(course_id);
CREATE INDEX IF NOT EXISTS idx_course_notes_uploader ON course_notes(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_course_notes_year ON course_notes(year_relevance);
CREATE INDEX IF NOT EXISTS idx_course_notes_official ON course_notes(is_official);
CREATE INDEX IF NOT EXISTS idx_course_notes_created ON course_notes(created_at DESC);

-- 3. Create note_concepts table (AI-extracted concepts)
CREATE TABLE IF NOT EXISTS note_concepts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  note_id UUID REFERENCES course_notes(id) ON DELETE CASCADE,
  concept_text TEXT NOT NULL,
  concept_type TEXT CHECK (concept_type IN ('key_term', 'formula', 'definition', 'example')),
  page_number INTEGER,
  context TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_note_concepts_note ON note_concepts(note_id);

-- 4. Create note_tags table
CREATE TABLE IF NOT EXISTS note_tags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  note_id UUID REFERENCES course_notes(id) ON DELETE CASCADE,
  tag_name TEXT NOT NULL,
  is_ai_generated BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(note_id, tag_name)
);

CREATE INDEX IF NOT EXISTS idx_note_tags_note ON note_tags(note_id);
CREATE INDEX IF NOT EXISTS idx_note_tags_name ON note_tags(tag_name);

-- 5. Create note_flashcards table
CREATE TABLE IF NOT EXISTS note_flashcards (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  note_id UUID REFERENCES course_notes(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_note_flashcards_note ON note_flashcards(note_id);

-- 6. Create user_note_downloads table (offline tracking)
CREATE TABLE IF NOT EXISTS user_note_downloads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  note_id UUID REFERENCES course_notes(id) ON DELETE CASCADE,
  downloaded_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, note_id)
);

CREATE INDEX IF NOT EXISTS idx_user_downloads_user ON user_note_downloads(user_id);
CREATE INDEX IF NOT EXISTS idx_user_downloads_note ON user_note_downloads(note_id);

-- 7. Create note_chunks table for RAG (pgvector)
CREATE TABLE IF NOT EXISTS note_chunks (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  note_id UUID REFERENCES course_notes(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  page_number INTEGER,
  chunk_index INTEGER NOT NULL,
  embedding vector(1536), -- OpenAI/Gemini embeddings dimension
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Vector similarity search index
CREATE INDEX IF NOT EXISTS idx_note_chunks_embedding 
  ON note_chunks USING ivfflat (embedding vector_cosine_ops)
  WITH (lists = 100);

CREATE INDEX IF NOT EXISTS idx_note_chunks_note ON note_chunks(note_id);

-- 8. Enable Row Level Security (RLS)
ALTER TABLE course_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_concepts ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_flashcards ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_note_downloads ENABLE ROW LEVEL SECURITY;
ALTER TABLE note_chunks ENABLE ROW LEVEL SECURITY;

-- 9. RLS Policies for course_notes
CREATE POLICY "Anyone can view notes"
  ON course_notes FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can upload notes"
  ON course_notes FOR INSERT
  WITH CHECK (auth.uid() = uploaded_by);

CREATE POLICY "Users can update their own notes"
  ON course_notes FOR UPDATE
  USING (auth.uid() = uploaded_by);

CREATE POLICY "Users can delete their own notes"
  ON course_notes FOR DELETE
  USING (auth.uid() = uploaded_by);

-- 10. RLS Policies for note_concepts
CREATE POLICY "Anyone can view concepts"
  ON note_concepts FOR SELECT
  USING (true);

CREATE POLICY "Only system can insert concepts"
  ON note_concepts FOR INSERT
  WITH CHECK (false); -- Only via service role

-- 11. RLS Policies for note_tags
CREATE POLICY "Anyone can view tags"
  ON note_tags FOR SELECT
  USING (true);

CREATE POLICY "Note owners can manage tags"
  ON note_tags FOR ALL
  USING (EXISTS (
    SELECT 1 FROM course_notes 
    WHERE course_notes.id = note_tags.note_id 
    AND course_notes.uploaded_by = auth.uid()
  ));

-- 12. RLS Policies for note_flashcards
CREATE POLICY "Anyone can view flashcards"
  ON note_flashcards FOR SELECT
  USING (true);

-- 13. RLS Policies for user_note_downloads
CREATE POLICY "Users can view their own downloads"
  ON user_note_downloads FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can track their downloads"
  ON user_note_downloads FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- 14. RLS Policies for note_chunks (RAG)
CREATE POLICY "Anyone can view chunks"
  ON note_chunks FOR SELECT
  USING (true);

CREATE POLICY "Only system can manage chunks"
  ON note_chunks FOR ALL
  USING (false); -- Only via service role

-- 15. Functions: Update updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Add trigger to course_notes
DROP TRIGGER IF EXISTS update_course_notes_updated_at ON course_notes;
CREATE TRIGGER update_course_notes_updated_at
  BEFORE UPDATE ON course_notes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- 16. Function: Increment download count
CREATE OR REPLACE FUNCTION increment_download_count(note_uuid UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE course_notes 
  SET download_count = download_count + 1
  WHERE id = note_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 17. Function: Increment view count
CREATE OR REPLACE FUNCTION increment_view_count(note_uuid UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE course_notes 
  SET view_count = view_count + 1
  WHERE id = note_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON TABLE course_notes IS 'Student-uploaded course notes with AI analysis';
COMMENT ON TABLE note_concepts IS 'AI-extracted key concepts from notes';
COMMENT ON TABLE note_tags IS 'Tags for categorizing notes (AI and manual)';
COMMENT ON TABLE note_flashcards IS 'AI-generated flashcards for study';
COMMENT ON TABLE user_note_downloads IS 'Track which notes users have downloaded for offline use';
COMMENT ON TABLE note_chunks IS 'Text chunks with embeddings for RAG (pgvector)';
