-- ==============================================================================
-- TIME CAPSULE — Supabase PostgreSQL Schema & Security Policies
-- Paradigm: One Capsule -> Unlimited Daily Memories -> One Future Unlock
-- ==============================================================================

-- 1. Create capsules table (The time vault containers)
CREATE TABLE IF NOT EXISTS public.capsules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL DEFAULT 'My Future Self',
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  unlock_at TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'locked' CHECK (status IN ('locked', 'ready', 'opened')),
  opened_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ
);

-- 2. Create memories table (Individual moments captured within a capsule)
CREATE TABLE IF NOT EXISTS public.memories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  capsule_id UUID REFERENCES public.capsules(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT,
  content TEXT NOT NULL,
  image_url TEXT,
  memory_type TEXT NOT NULL DEFAULT 'note' CHECK (memory_type IN ('note', 'photo', 'voice', 'video')),
  is_important BOOLEAN NOT NULL DEFAULT false,
  captured_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
  deleted_at TIMESTAMPTZ
);

-- 3. Performance indexes
CREATE INDEX IF NOT EXISTS idx_capsules_user_id ON public.capsules(user_id);
CREATE INDEX IF NOT EXISTS idx_capsules_unlock_at ON public.capsules(unlock_at);
CREATE INDEX IF NOT EXISTS idx_capsules_status ON public.capsules(status);

CREATE INDEX IF NOT EXISTS idx_memories_capsule_id ON public.memories(capsule_id);
CREATE INDEX IF NOT EXISTS idx_memories_user_id ON public.memories(user_id);
CREATE INDEX IF NOT EXISTS idx_memories_captured_at ON public.memories(captured_at);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.capsules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.memories ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for Capsules
DROP POLICY IF EXISTS "Users can view own capsules" ON public.capsules;
CREATE POLICY "Users can view own capsules"
  ON public.capsules FOR SELECT
  USING (auth.uid() = user_id AND deleted_at IS NULL);

DROP POLICY IF EXISTS "Users can insert own capsules" ON public.capsules;
CREATE POLICY "Users can insert own capsules"
  ON public.capsules FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own capsules" ON public.capsules;
CREATE POLICY "Users can update own capsules"
  ON public.capsules FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own capsules" ON public.capsules;
CREATE POLICY "Users can delete own capsules"
  ON public.capsules FOR DELETE
  USING (auth.uid() = user_id);

-- 6. RLS Policies for Memories
DROP POLICY IF EXISTS "Users can view own memories" ON public.memories;
CREATE POLICY "Users can view own memories"
  ON public.memories FOR SELECT
  USING (
    auth.uid() = user_id 
    AND deleted_at IS NULL
    AND EXISTS (
      SELECT 1 FROM public.capsules c 
      WHERE c.id = memories.capsule_id AND c.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can insert memories to own capsules" ON public.memories;
CREATE POLICY "Users can insert memories to own capsules"
  ON public.memories FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM public.capsules c 
      WHERE c.id = memories.capsule_id AND c.user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Users can update own memories" ON public.memories;
CREATE POLICY "Users can update own memories"
  ON public.memories FOR UPDATE
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own memories" ON public.memories;
CREATE POLICY "Users can delete own memories"
  ON public.memories FOR DELETE
  USING (auth.uid() = user_id);

-- 7. Automatic Capsule Status Check Trigger
CREATE OR REPLACE FUNCTION public.handle_capsule_status_check()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.opened_at IS NOT NULL THEN
    NEW.status := 'opened';
  ELSIF NEW.unlock_at <= timezone('utc'::text, now()) THEN
    NEW.status := 'ready';
  ELSE
    NEW.status := 'locked';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_capsules_status_check ON public.capsules;
CREATE TRIGGER tr_capsules_status_check
  BEFORE INSERT OR UPDATE ON public.capsules
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_capsule_status_check();

-- 8. Storage Bucket for Memory Photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('memory-images', 'memory-images', false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Users can upload memory images" ON storage.objects;
CREATE POLICY "Users can upload memory images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'memory-images' 
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "Users can view own memory images" ON storage.objects;
CREATE POLICY "Users can view own memory images"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'memory-images'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
