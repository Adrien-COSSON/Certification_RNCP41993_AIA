CREATE TABLE "fact_transaction" (
  "transaction_key" bigint PRIMARY KEY,
  "transaction_id" bigint NOT NULL,
  "date_key" int NOT NULL,
  "hour_of_day" smallint,
  "merchant_key" bigint NOT NULL,
  "customer_key" bigint NOT NULL,
  "payment_method_key" bigint NOT NULL,
  "currency_key" int NOT NULL,
  "ip_country_key" int,
  "transaction_type" varchar(20) NOT NULL,
  "status" varchar(20) NOT NULL,
  "device_type" varchar(20),
  "amount" numeric(14,2) NOT NULL,
  "exchange_rate" numeric(12,6) NOT NULL,
  "amount_usd" numeric(14,2) NOT NULL,
  "item_count" int,
  "fraud_score" numeric(5,4),
  "is_fraud" boolean
);

CREATE TABLE "fact_audit" (
  "audit_key" bigint PRIMARY KEY,
  "audit_id" bigint NOT NULL,
  "date_key" int NOT NULL,
  "hour_of_day" smallint,
  "actor" varchar(80) NOT NULL,
  "action" varchar(20) NOT NULL,
  "entity" varchar(50) NOT NULL,
  "entity_id" bigint,
  "customer_key" bigint,
  "transaction_id" bigint
);

CREATE TABLE "dim_date" (
  "date_key" int PRIMARY KEY,
  "full_date" date NOT NULL,
  "day" smallint,
  "month" smallint,
  "month_name" varchar(12),
  "week" smallint,
  "quarter" smallint,
  "year" smallint,
  "day_of_week" smallint,
  "is_weekend" boolean
);

CREATE TABLE "dim_merchant" (
  "merchant_key" bigint PRIMARY KEY,
  "merchant_id" bigint NOT NULL,
  "name" varchar(150),
  "mcc" char(4),
  "country_name" varchar(100),
  "region" varchar(50)
);

CREATE TABLE "dim_customer" (
  "customer_key" bigint PRIMARY KEY,
  "customer_id" bigint NOT NULL,
  "country_name" varchar(100),
  "region" varchar(50),
  "segment" varchar(50),
  "signup_year" smallint
);

CREATE TABLE "dim_payment_method" (
  "payment_method_key" bigint PRIMARY KEY,
  "method_type" varchar(30),
  "brand" varchar(30)
);

CREATE TABLE "dim_currency" (
  "currency_key" int PRIMARY KEY,
  "currency_code" char(3) NOT NULL,
  "label" varchar(50)
);

CREATE TABLE "dim_country" (
  "country_key" int PRIMARY KEY,
  "iso_code" char(2) NOT NULL,
  "name" varchar(100),
  "region" varchar(50)
);

CREATE TABLE "dim_product" (
  "product_key" bigint PRIMARY KEY,
  "product_id" bigint NOT NULL,
  "name" varchar(150),
  "merchant_name" varchar(150)
);

CREATE TABLE "agg_revenue_daily" (
  "date_key" int NOT NULL,
  "merchant_key" bigint NOT NULL,
  "total_amount_usd" numeric(16,2),
  "refund_amount_usd" numeric(16,2),
  "transaction_count" int,
  "successful_count" int,
  "failed_count" int,
  PRIMARY KEY ("date_key", "merchant_key")
);

CREATE TABLE "agg_fraud_daily" (
  "date_key" int NOT NULL,
  "ip_country_key" int NOT NULL,
  "transaction_count" int,
  "avg_fraud_score" numeric(5,4),
  "fraud_count" int,
  "fraud_amount_usd" numeric(16,2),
  PRIMARY KEY ("date_key", "ip_country_key")
);

CREATE TABLE "agg_product_daily" (
  "date_key" int NOT NULL,
  "product_key" bigint NOT NULL,
  "quantity_sold" int,
  "revenue_usd" numeric(16,2),
  PRIMARY KEY ("date_key", "product_key")
);

COMMENT ON COLUMN "fact_transaction"."transaction_id" IS 'Identifiant de la transaction dans l’OLTP';

COMMENT ON COLUMN "fact_transaction"."date_key" IS 'Clé de tri';

COMMENT ON COLUMN "fact_transaction"."customer_key" IS 'Clé de distribution';

COMMENT ON COLUMN "fact_audit"."audit_id" IS 'Identifiant de la ligne dans audit_log (OLTP)';

COMMENT ON COLUMN "fact_audit"."date_key" IS 'Clé de tri';

COMMENT ON COLUMN "dim_date"."week" IS 'Semaine ISO';

COMMENT ON COLUMN "dim_customer"."customer_key" IS 'Clé de distribution';

COMMENT ON COLUMN "dim_customer"."segment" IS 'Mis à jour chaque semaine par le modèle de segmentation';

ALTER TABLE "fact_transaction" ADD FOREIGN KEY ("date_key") REFERENCES "dim_date" ("date_key") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "fact_transaction" ADD FOREIGN KEY ("merchant_key") REFERENCES "dim_merchant" ("merchant_key") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "fact_transaction" ADD FOREIGN KEY ("customer_key") REFERENCES "dim_customer" ("customer_key") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "fact_transaction" ADD FOREIGN KEY ("payment_method_key") REFERENCES "dim_payment_method" ("payment_method_key") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "fact_transaction" ADD FOREIGN KEY ("currency_key") REFERENCES "dim_currency" ("currency_key") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "fact_transaction" ADD FOREIGN KEY ("ip_country_key") REFERENCES "dim_country" ("country_key") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "fact_audit" ADD FOREIGN KEY ("date_key") REFERENCES "dim_date" ("date_key") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "fact_audit" ADD FOREIGN KEY ("customer_key") REFERENCES "dim_customer" ("customer_key") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "agg_revenue_daily" ADD FOREIGN KEY ("date_key") REFERENCES "dim_date" ("date_key") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "agg_revenue_daily" ADD FOREIGN KEY ("merchant_key") REFERENCES "dim_merchant" ("merchant_key") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "agg_fraud_daily" ADD FOREIGN KEY ("date_key") REFERENCES "dim_date" ("date_key") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "agg_fraud_daily" ADD FOREIGN KEY ("ip_country_key") REFERENCES "dim_country" ("country_key") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "agg_product_daily" ADD FOREIGN KEY ("date_key") REFERENCES "dim_date" ("date_key") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "agg_product_daily" ADD FOREIGN KEY ("product_key") REFERENCES "dim_product" ("product_key") DEFERRABLE INITIALLY IMMEDIATE;
