USE autopieces;

ALTER TABLE shops ADD COLUMN payments VARCHAR(120) NOT NULL DEFAULT 'Cash';
ALTER TABLE job_requests ADD COLUMN distance_km DOUBLE NULL;
UPDATE shops SET payments = 'Cash, CIB card' WHERE id = 1;
