CREATE TABLE IF NOT EXISTS items (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO items (name, description) VALUES
    ('Ejemplo 1', 'Primer item de ejemplo'),
    ('Ejemplo 2', 'Segundo item de ejemplo')
ON CONFLICT DO NOTHING;
