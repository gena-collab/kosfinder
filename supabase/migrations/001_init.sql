CREATE TABLE public.kos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id uuid NOT NULL DEFAULT auth.uid()
        REFERENCES auth.users (id),
    nama text NOT NULL CHECK (btrim(nama) <> ''),
    alamat text NOT NULL CHECK (btrim(alamat) <> ''),
    harga_bulanan numeric(12, 2) NOT NULL
        CHECK (harga_bulanan > 0),
    deskripsi text NOT NULL CHECK (btrim(deskripsi) <> ''),
    fasilitas text,
    foto_url text,
    created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.kos ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON TABLE public.kos TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.kos TO authenticated;

CREATE POLICY kos_public_read
    ON public.kos
    FOR SELECT
    TO anon, authenticated
    USING (true);

CREATE POLICY kos_owner_insert
    ON public.kos
    FOR INSERT
    TO authenticated
    WITH CHECK (owner_id = auth.uid());

CREATE POLICY kos_owner_update
    ON public.kos
    FOR UPDATE
    TO authenticated
    USING (owner_id = auth.uid())
    WITH CHECK (owner_id = auth.uid());

CREATE POLICY kos_owner_delete
    ON public.kos
    FOR DELETE
    TO authenticated
    USING (owner_id = auth.uid());
