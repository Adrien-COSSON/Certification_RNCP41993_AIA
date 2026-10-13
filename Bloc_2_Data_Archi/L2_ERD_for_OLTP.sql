CREATE TYPE "transaction_type" AS ENUM (
  'payment',
  'refund',
  'chargeback',
  'subscription'
);

CREATE TYPE "transaction_status" AS ENUM (
  'successful',
  'failed',
  'refunded'
);

CREATE TYPE "device_type" AS ENUM (
  'mobile',
  'desktop',
  'tablet'
);

CREATE TYPE "payment_method_type" AS ENUM (
  'card',
  'bank_transfer',
  'wallet'
);

CREATE TYPE "billing_interval" AS ENUM (
  'monthly',
  'yearly'
);

CREATE TYPE "subscription_status" AS ENUM (
  'active',
  'canceled',
  'expired'
);

CREATE TABLE "transaction" (
  "transaction_id" bigint PRIMARY KEY,
  "idempotency_key" varchar(64) UNIQUE NOT NULL,
  "parent_transaction_id" bigint,
  "merchant_id" bigint NOT NULL,
  "customer_id" bigint NOT NULL,
  "payment_method_id" bigint NOT NULL,
  "subscription_id" bigint,
  "transaction_type" transaction_type NOT NULL,
  "transaction_amount" numeric(14,2) NOT NULL,
  "currency_code" char(3) NOT NULL,
  "exchange_rate" numeric(12,6) NOT NULL,
  "status" transaction_status NOT NULL,
  "fraud_score" numeric(5,4),
  "ip_address" inet,
  "ip_country_id" int,
  "device_type" device_type,
  "transaction_date_time" timestamptz NOT NULL
);

CREATE TABLE "transaction_item" (
  "transaction_item_id" bigint PRIMARY KEY,
  "transaction_id" bigint NOT NULL,
  "product_id" bigint NOT NULL,
  "quantity" int NOT NULL,
  "unit_price" numeric(12,2) NOT NULL
);

CREATE TABLE "merchant" (
  "merchant_id" bigint PRIMARY KEY,
  "name" varchar(150) NOT NULL,
  "email" varchar(150) UNIQUE,
  "phone" varchar(30),
  "mcc" char(4),
  "country_id" int NOT NULL,
  "created_at" timestamptz NOT NULL
);

CREATE TABLE "customer" (
  "customer_id" bigint PRIMARY KEY,
  "full_name" varchar(120),
  "email" varchar(150) UNIQUE NOT NULL,
  "phone" varchar(30),
  "country_id" int,
  "created_at" timestamptz NOT NULL
);

CREATE TABLE "payment_method" (
  "payment_method_id" bigint PRIMARY KEY,
  "customer_id" bigint NOT NULL,
  "method_type" payment_method_type NOT NULL,
  "payment_token" varchar(64) UNIQUE NOT NULL,
  "brand" varchar(30),
  "last4" char(4),
  "exp_month" smallint,
  "exp_year" smallint,
  "created_at" timestamptz NOT NULL
);

CREATE TABLE "product" (
  "product_id" bigint PRIMARY KEY,
  "merchant_id" bigint NOT NULL,
  "name" varchar(150) NOT NULL,
  "unit_price" numeric(12,2) NOT NULL,
  "currency_code" char(3) NOT NULL,
  "created_at" timestamptz NOT NULL
);

CREATE TABLE "subscription" (
  "subscription_id" bigint PRIMARY KEY,
  "customer_id" bigint NOT NULL,
  "merchant_id" bigint NOT NULL,
  "product_id" bigint NOT NULL,
  "billing_interval" billing_interval NOT NULL,
  "status" subscription_status NOT NULL,
  "start_date" date NOT NULL,
  "end_date" date
);

CREATE TABLE "country" (
  "country_id" int PRIMARY KEY,
  "iso_code" char(2) UNIQUE NOT NULL,
  "name" varchar(100) NOT NULL,
  "region" varchar(50)
);

CREATE TABLE "currency" (
  "currency_code" char(3) PRIMARY KEY,
  "label" varchar(50) NOT NULL
);

CREATE TABLE "audit_log" (
  "audit_id" bigint PRIMARY KEY,
  "actor" varchar(80) NOT NULL,
  "action" varchar(20) NOT NULL,
  "entity" varchar(50) NOT NULL,
  "entity_id" bigint NOT NULL,
  "transaction_id" bigint,
  "customer_id" bigint,
  "occurred_at" timestamptz NOT NULL,
  "details" jsonb
);

CREATE INDEX ON "transaction" ("customer_id", "transaction_date_time");

CREATE INDEX ON "transaction" ("merchant_id", "transaction_date_time");

CREATE INDEX ON "transaction" ("parent_transaction_id");

CREATE INDEX ON "audit_log" ("customer_id");

COMMENT ON COLUMN "transaction"."idempotency_key" IS 'Empêche un double prélèvement';

COMMENT ON COLUMN "transaction"."parent_transaction_id" IS 'Paiement d’origine pour un remboursement ou une rétrofacturation';

COMMENT ON COLUMN "transaction"."exchange_rate" IS 'Taux vers USD au moment du paiement';

COMMENT ON COLUMN "transaction"."fraud_score" IS 'Vide si la transaction n’a pas pu être scorée';

COMMENT ON COLUMN "transaction_item"."unit_price" IS 'Prix au moment de l’achat';

COMMENT ON COLUMN "payment_method"."payment_token" IS 'Jeton : le numéro de carte n’est jamais stocké';

ALTER TABLE "transaction" ADD FOREIGN KEY ("merchant_id") REFERENCES "merchant" ("merchant_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "transaction" ADD FOREIGN KEY ("customer_id") REFERENCES "customer" ("customer_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "transaction" ADD FOREIGN KEY ("payment_method_id") REFERENCES "payment_method" ("payment_method_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "transaction" ADD FOREIGN KEY ("currency_code") REFERENCES "currency" ("currency_code") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "transaction_item" ADD FOREIGN KEY ("transaction_id") REFERENCES "transaction" ("transaction_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "transaction_item" ADD FOREIGN KEY ("product_id") REFERENCES "product" ("product_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "merchant" ADD FOREIGN KEY ("country_id") REFERENCES "country" ("country_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "payment_method" ADD FOREIGN KEY ("customer_id") REFERENCES "customer" ("customer_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "product" ADD FOREIGN KEY ("merchant_id") REFERENCES "merchant" ("merchant_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "product" ADD FOREIGN KEY ("currency_code") REFERENCES "currency" ("currency_code") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "subscription" ADD FOREIGN KEY ("customer_id") REFERENCES "customer" ("customer_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "subscription" ADD FOREIGN KEY ("merchant_id") REFERENCES "merchant" ("merchant_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "subscription" ADD FOREIGN KEY ("product_id") REFERENCES "product" ("product_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "transaction" ADD FOREIGN KEY ("parent_transaction_id") REFERENCES "transaction" ("transaction_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "transaction" ADD FOREIGN KEY ("subscription_id") REFERENCES "subscription" ("subscription_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "transaction" ADD FOREIGN KEY ("ip_country_id") REFERENCES "country" ("country_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "customer" ADD FOREIGN KEY ("country_id") REFERENCES "country" ("country_id") DEFERRABLE INITIALLY IMMEDIATE;

ALTER TABLE "audit_log" ADD FOREIGN KEY ("transaction_id") REFERENCES "transaction" ("transaction_id") DEFERRABLE INITIALLY IMMEDIATE;
