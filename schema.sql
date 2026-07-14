-- ══════════════════════════════════════════════════════
-- RidersDeal DATEV-Abgleich Dashboard
-- Supabase Schema Setup
-- Einmalig ausführen im SQL Editor
-- ══════════════════════════════════════════════════════

-- Einträge (alle DATEV + Lizenzliste Posten)
CREATE TABLE IF NOT EXISTS eintraege (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  quelle TEXT,
  kategorie TEXT,
  abteilung TEXT,
  status TEXT DEFAULT 'offen',
  erste_buchung TEXT,
  letzte_buchung TEXT,
  betrag TEXT,
  betrag_raw NUMERIC,
  kosten_monat TEXT,
  laufzeit_bis TEXT,
  kuendigung_bis TEXT,
  buchungsbeispiel TEXT,
  massnahme TEXT,
  ext_ansprechpartner TEXT,
  int_ansprechpartner TEXT,
  erledigt BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notizen / Kommentare
CREATE TABLE IF NOT EXISTS notizen (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  eintrag_id TEXT REFERENCES eintraege(id) ON DELETE CASCADE,
  autor TEXT NOT NULL,
  text TEXT NOT NULL,
  resolved BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Zellen-Bearbeitungen (Inline Edits)
CREATE TABLE IF NOT EXISTS edits (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  eintrag_id TEXT REFERENCES eintraege(id) ON DELETE CASCADE,
  feld TEXT NOT NULL,
  wert TEXT,
  autor TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(eintrag_id, feld)
);

-- Dokumente (File Uploads)
CREATE TABLE IF NOT EXISTS dokumente (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  eintrag_id TEXT REFERENCES eintraege(id) ON DELETE CASCADE,
  dateiname TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  dateityp TEXT,
  groesse BIGINT,
  hochgeladen_von TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Ansprechpartner (manuell ergänzbar)
CREATE TABLE IF NOT EXISTS ansprechpartner (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  eintrag_id TEXT REFERENCES eintraege(id) ON DELETE CASCADE,
  typ TEXT CHECK (typ IN ('extern', 'intern')),
  name TEXT NOT NULL,
  rolle TEXT,
  email TEXT,
  telefon TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Row Level Security (öffentlicher Zugriff für alle Mitarbeiter) ──
ALTER TABLE eintraege ENABLE ROW LEVEL SECURITY;
ALTER TABLE notizen ENABLE ROW LEVEL SECURITY;
ALTER TABLE edits ENABLE ROW LEVEL SECURITY;
ALTER TABLE dokumente ENABLE ROW LEVEL SECURITY;
ALTER TABLE ansprechpartner ENABLE ROW LEVEL SECURITY;

-- Alle dürfen lesen + schreiben (kein Login nötig)
CREATE POLICY "Public read" ON eintraege FOR SELECT USING (true);
CREATE POLICY "Public insert" ON eintraege FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update" ON eintraege FOR UPDATE USING (true);

CREATE POLICY "Public read" ON notizen FOR SELECT USING (true);
CREATE POLICY "Public insert" ON notizen FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update" ON notizen FOR UPDATE USING (true);
CREATE POLICY "Public delete" ON notizen FOR DELETE USING (true);

CREATE POLICY "Public read" ON edits FOR SELECT USING (true);
CREATE POLICY "Public insert" ON edits FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update" ON edits FOR UPDATE USING (true);

CREATE POLICY "Public read" ON dokumente FOR SELECT USING (true);
CREATE POLICY "Public insert" ON dokumente FOR INSERT WITH CHECK (true);
CREATE POLICY "Public delete" ON dokumente FOR DELETE USING (true);

CREATE POLICY "Public read" ON ansprechpartner FOR SELECT USING (true);
CREATE POLICY "Public insert" ON ansprechpartner FOR INSERT WITH CHECK (true);
CREATE POLICY "Public update" ON ansprechpartner FOR UPDATE USING (true);
CREATE POLICY "Public delete" ON ansprechpartner FOR DELETE USING (true);

-- ── Storage Bucket für PDFs ──
INSERT INTO storage.buckets (id, name, public)
VALUES ('dokumente', 'dokumente', true)
ON CONFLICT DO NOTHING;

CREATE POLICY "Public upload" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'dokumente');
CREATE POLICY "Public read" ON storage.objects
  FOR SELECT USING (bucket_id = 'dokumente');
CREATE POLICY "Public delete" ON storage.objects
  FOR DELETE USING (bucket_id = 'dokumente');

-- ── Updated_at Trigger ──
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER eintraege_updated_at
  BEFORE UPDATE ON eintraege
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

