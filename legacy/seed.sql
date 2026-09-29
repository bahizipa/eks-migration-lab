CREATE TABLE IF NOT EXISTS notes (
  id SERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);
INSERT INTO notes (title, body) VALUES
  ('Discovery', 'Inventory of legacy services on OVH'),
  ('Landing zone', 'VPC, EKS, RDS provisioned by Terraform'),
  ('Cutover', 'Switch DNS after verification');
