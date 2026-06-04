-- TYPES
DO $$ BEGIN CREATE TYPE public.app_role AS ENUM ('owner', 'admin', 'courier', 'office'); EXCEPTION WHEN duplicate_object THEN NULL; END $$;
DO $$ BEGIN ALTER TYPE public.app_role ADD VALUE IF NOT EXISTS 'office'; EXCEPTION WHEN others THEN NULL; END $$;

-- SEQUENCES
CREATE SEQUENCE IF NOT EXISTS public.barcode_seq START WITH 1000;
CREATE SEQUENCE IF NOT EXISTS public.barcode_numeric_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE IF NOT EXISTS public.order_barcode_seq START WITH 1;

-- TABLES
CREATE TABLE IF NOT EXISTS public.offices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL DEFAULT '',
  specialty text DEFAULT '',
  owner_name text DEFAULT '',
  owner_phone text DEFAULT '',
  address text DEFAULT '',
  notes text DEFAULT '',
  can_add_orders boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  phone TEXT DEFAULT '',
  office_commission NUMERIC DEFAULT 0);
CREATE TABLE IF NOT EXISTS public.order_statuses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL DEFAULT '',
  color text NOT NULL DEFAULT '#6b7280',
  sort_order integer NOT NULL DEFAULT 0,
  is_fixed boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL DEFAULT '',
  quantity integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY,
  full_name text NOT NULL DEFAULT '',
  phone text DEFAULT '',
  login_code text DEFAULT '',
  address text DEFAULT '',
  notes text DEFAULT '',
  salary numeric NOT NULL DEFAULT 0,
  coverage_areas text DEFAULT '',
  office_id uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  commission_amount NUMERIC DEFAULT 0,
  rejection_commission NUMERIC DEFAULT 0);
CREATE TABLE IF NOT EXISTS public.user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid  NOT NULL,
  role app_role NOT NULL,
  UNIQUE (user_id, role));
CREATE TABLE IF NOT EXISTS public.orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  barcode text DEFAULT '',
  tracking_id text DEFAULT '',
  customer_name text NOT NULL DEFAULT '',
  customer_phone text DEFAULT '',
  customer_code text DEFAULT '',
  product_name text DEFAULT 'بدون منتج',
  product_id uuid,
  quantity integer NOT NULL DEFAULT 1,
  price numeric NOT NULL DEFAULT 0,
  delivery_price numeric NOT NULL DEFAULT 0,
  partial_amount numeric DEFAULT 0,
  shipping_paid numeric DEFAULT 0,
  color text DEFAULT '',
  size text DEFAULT '',
  address text DEFAULT '',
  notes text DEFAULT '',
  priority text NOT NULL DEFAULT 'normal',
  status_id uuid,
  office_id uuid,
  courier_id uuid,
  company_id uuid,
  is_closed boolean NOT NULL DEFAULT false,
  is_settled boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  closed_at TIMESTAMPTZ,
  courier_assigned_at TIMESTAMPTZ,
  is_courier_closed BOOLEAN DEFAULT false,
  closed_by UUID,
  courier_closed_by UUID,
  last_modified_by UUID,
  returned_to_sender BOOLEAN NOT NULL DEFAULT false,
  returned_to_sender_at TIMESTAMPTZ,
  returned_to_sender_by UUID);
CREATE TABLE IF NOT EXISTS public.order_notes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL,
  user_id uuid NOT NULL,
  note text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.advances (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  amount numeric NOT NULL DEFAULT 0,
  reason text DEFAULT '',
  type text NOT NULL DEFAULT 'advance' CHECK (type IN ('advance', 'deduction', 'bonus')),
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.courier_bonuses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  courier_id uuid NOT NULL,
  amount numeric NOT NULL DEFAULT 0,
  reason text DEFAULT '',
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  type TEXT DEFAULT 'special');
CREATE TABLE IF NOT EXISTS public.delivery_prices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id uuid  NOT NULL,
  governorate text NOT NULL DEFAULT '',
  price numeric NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  pickup_price numeric NOT NULL DEFAULT 0);
CREATE TABLE IF NOT EXISTS public.office_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id uuid NOT NULL,
  amount numeric NOT NULL DEFAULT 0,
  type text NOT NULL DEFAULT 'advance',
  notes text DEFAULT '',
  paid_by uuid,
  created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.user_permissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  section text NOT NULL,
  permission text NOT NULL DEFAULT 'hidden' CHECK (permission IN ('view', 'edit', 'hidden')),
  UNIQUE (user_id, section));
CREATE TABLE IF NOT EXISTS public.diaries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id uuid NOT NULL,
  diary_number integer NOT NULL DEFAULT 0,
  diary_date date NOT NULL DEFAULT CURRENT_DATE,
  is_closed boolean NOT NULL DEFAULT false,
  lock_status_updates boolean NOT NULL DEFAULT false,
  prevent_new_orders boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  closed_at timestamptz,
  is_archived boolean DEFAULT false,
  cash_arrived_entries jsonb DEFAULT '[]'::jsonb,
  balance numeric DEFAULT 0,
  previous_due numeric DEFAULT 0,
  orange_extra_due numeric DEFAULT 0,
  orange_extra_due_reason text DEFAULT '',
  show_postponed_due boolean DEFAULT true,
  manual_arrived_total numeric DEFAULT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.diary_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL,
  diary_id uuid NOT NULL,
  status_inside_diary text NOT NULL DEFAULT 'بدون حالة',
  partial_amount numeric DEFAULT 0,
  n_column text DEFAULT '',
  created_at timestamptz NOT NULL DEFAULT now(),
  notes text DEFAULT '',
  locked_status boolean DEFAULT false,
  copied_from_diary_id uuid,
  copied_from_diary_order_id uuid,
  manual_pickup numeric DEFAULT 0,
  manual_arrived numeric DEFAULT 0,
  manual_shipping_diff numeric DEFAULT 0,
  manual_delivery_commission numeric DEFAULT 0,
  manual_reject_no_ship numeric DEFAULT 0,
  manual_return_penalty numeric DEFAULT 0,
  manual_return_status text DEFAULT '',
  manual_total_amount numeric DEFAULT NULL,
  manual_shipping_amount numeric DEFAULT NULL,
  manual_shipping NUMERIC DEFAULT 0,
  manual_collected NUMERIC DEFAULT 0);
CREATE TABLE IF NOT EXISTS public.expenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  expense_name text NOT NULL,
  amount numeric NOT NULL DEFAULT 0,
  expense_date date NOT NULL DEFAULT CURRENT_DATE,
  category text NOT NULL DEFAULT 'أخرى',
  notes text DEFAULT '',
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  office_id uuid);
CREATE TABLE IF NOT EXISTS public.cash_flow_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  type text NOT NULL DEFAULT 'inside',
  amount numeric NOT NULL DEFAULT 0,
  entry_date date NOT NULL DEFAULT CURRENT_DATE,
  reason text DEFAULT '',
  office_id uuid,
  notes text DEFAULT '',
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.app_settings (
  key text PRIMARY KEY,
  value text NOT NULL DEFAULT '',
  updated_at timestamptz DEFAULT now());
CREATE TABLE IF NOT EXISTS public.courier_locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  courier_id uuid NOT NULL,
  latitude numeric NOT NULL DEFAULT 0,
  longitude numeric NOT NULL DEFAULT 0,
  accuracy numeric DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id uuid NOT NULL,
  receiver_id uuid NOT NULL,
  message text NOT NULL DEFAULT '',
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.office_daily_closings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id uuid,
  closing_date date NOT NULL DEFAULT CURRENT_DATE,
  data_json jsonb NOT NULL DEFAULT '{}',
  pickup_rate numeric NOT NULL DEFAULT 0,
  is_locked boolean NOT NULL DEFAULT false,
  is_closed boolean NOT NULL DEFAULT false,
  prevent_add boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (office_id, closing_date));
CREATE TABLE IF NOT EXISTS public.companies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL DEFAULT '',
  agreement_price numeric NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.activity_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid,
  action text NOT NULL DEFAULT '',
  details jsonb DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.courier_collections (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  courier_id uuid NOT NULL,
  order_id uuid,
  amount numeric NOT NULL DEFAULT 0,
  collected_by uuid,
  created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.company_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id uuid,
  amount numeric NOT NULL DEFAULT 0,
  notes text DEFAULT '',
  paid_by uuid,
  created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.office_daily_expenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id uuid,
  expense_date date NOT NULL DEFAULT CURRENT_DATE,
  category text NOT NULL DEFAULT 'office',
  notes text DEFAULT '',
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  amount NUMERIC DEFAULT 0);
CREATE TABLE IF NOT EXISTS public.scan_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid,
  started_at timestamptz NOT NULL DEFAULT now(),
  ended_at timestamptz,
  total_count integer NOT NULL DEFAULT 0,
  notes text DEFAULT '');
CREATE TABLE IF NOT EXISTS public.scan_session_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL,
  order_id uuid NOT NULL,
  scanned_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS public.order_status_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL,
  old_status_id uuid,
  new_status_id uuid,
  changed_by uuid,
  changed_at timestamptz NOT NULL DEFAULT now(),
  source text NOT NULL DEFAULT 'manual');

-- GRANTS
GRANT SELECT, INSERT, UPDATE, DELETE ON public.offices TO authenticated;
GRANT ALL ON public.offices TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.order_statuses TO authenticated;
GRANT ALL ON public.order_statuses TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.products TO authenticated;
GRANT ALL ON public.products TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_roles TO authenticated;
GRANT ALL ON public.user_roles TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.orders TO authenticated;
GRANT ALL ON public.orders TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.order_notes TO authenticated;
GRANT ALL ON public.order_notes TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.advances TO authenticated;
GRANT ALL ON public.advances TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.courier_bonuses TO authenticated;
GRANT ALL ON public.courier_bonuses TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.delivery_prices TO authenticated;
GRANT ALL ON public.delivery_prices TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.office_payments TO authenticated;
GRANT ALL ON public.office_payments TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_permissions TO authenticated;
GRANT ALL ON public.user_permissions TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.diaries TO authenticated;
GRANT ALL ON public.diaries TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.diary_orders TO authenticated;
GRANT ALL ON public.diary_orders TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.expenses TO authenticated;
GRANT ALL ON public.expenses TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cash_flow_entries TO authenticated;
GRANT ALL ON public.cash_flow_entries TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.app_settings TO authenticated;
GRANT ALL ON public.app_settings TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.courier_locations TO authenticated;
GRANT ALL ON public.courier_locations TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.messages TO authenticated;
GRANT ALL ON public.messages TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.office_daily_closings TO authenticated;
GRANT ALL ON public.office_daily_closings TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.companies TO authenticated;
GRANT ALL ON public.companies TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.activity_logs TO authenticated;
GRANT ALL ON public.activity_logs TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.courier_collections TO authenticated;
GRANT ALL ON public.courier_collections TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.company_payments TO authenticated;
GRANT ALL ON public.company_payments TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.office_daily_expenses TO authenticated;
GRANT ALL ON public.office_daily_expenses TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.scan_sessions TO authenticated;
GRANT ALL ON public.scan_sessions TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.scan_session_items TO authenticated;
GRANT ALL ON public.scan_session_items TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.order_status_history TO authenticated;
GRANT ALL ON public.order_status_history TO service_role;

-- FUNCTIONS
CREATE OR REPLACE FUNCTION public.nextval_barcode()
RETURNS bigint LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  SELECT nextval('public.barcode_numeric_seq');
$$;
CREATE OR REPLACE FUNCTION public.cleanup_old_activity_logs()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM public.activity_logs WHERE created_at < NOW() - INTERVAL '7 days';
END;
$$;
CREATE OR REPLACE FUNCTION public.log_activity(_action TEXT, _details JSONB DEFAULT '{}'::jsonb)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.activity_logs (user_id, action, details)
  VALUES (auth.uid(), _action, _details);
END;
$$;
CREATE OR REPLACE FUNCTION public.generate_barcode()
RETURNS trigger LANGUAGE plpgsql SET search_path TO 'public' AS $$
BEGIN
  IF NEW.barcode IS NULL OR NEW.barcode = '' THEN
    NEW.barcode := nextval('public.barcode_numeric_seq')::TEXT;
  END IF;
  RETURN NEW;
END;
$$;
CREATE OR REPLACE FUNCTION public.generate_diary_number()
RETURNS trigger LANGUAGE plpgsql SET search_path TO 'public' AS $$
BEGIN
  SELECT COALESCE(MAX(diary_number), 0) + 1 INTO NEW.diary_number FROM public.diaries WHERE office_id = NEW.office_id;
  RETURN NEW;
END;
$$;
CREATE OR REPLACE FUNCTION public.cleanup_old_diaries()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
BEGIN
  UPDATE public.diaries SET is_archived = true WHERE is_closed = true AND is_archived = false AND closed_at < now() - interval '3 months';
  DELETE FROM public.diaries WHERE is_archived = true AND closed_at < now() - interval '6 months';
END;
$$;
CREATE OR REPLACE FUNCTION public.auto_create_diary_for_order()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public' AS $$
DECLARE v_diary_id uuid; v_order_date date;
BEGIN
  IF NEW.office_id IS NULL THEN RETURN NEW; END IF;
  v_order_date := (NEW.created_at AT TIME ZONE 'UTC')::date;
  SELECT id INTO v_diary_id FROM public.diaries WHERE office_id = NEW.office_id AND diary_date = v_order_date AND is_closed = false AND is_archived = false AND prevent_new_orders = false LIMIT 1;
  IF v_diary_id IS NULL THEN
    INSERT INTO public.diaries (office_id, diary_date) VALUES (NEW.office_id, v_order_date) RETURNING id INTO v_diary_id;
  END IF;
  IF v_diary_id IS NOT NULL THEN
    INSERT INTO public.diary_orders (order_id, diary_id) VALUES (NEW.id, v_diary_id) ON CONFLICT (order_id, diary_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'full_name', ''))
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;
CREATE OR REPLACE FUNCTION public.has_role(_user_id uuid, _role app_role)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role = _role)
$$;
CREATE OR REPLACE FUNCTION public.is_owner_or_admin(_user_id uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.user_roles WHERE user_id = _user_id AND role IN ('owner', 'admin'))
$$;
CREATE OR REPLACE FUNCTION public.generate_order_barcode()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.barcode IS NULL OR NEW.barcode = '' THEN
    NEW.barcode := nextval('public.order_barcode_seq')::TEXT;
  END IF;
  IF NEW.tracking_id IS NULL OR NEW.tracking_id = '' THEN
    NEW.tracking_id := 'AK-' || NEW.barcode;
  END IF;
  RETURN NEW;
END;
$$;
CREATE OR REPLACE FUNCTION public.handle_orders_courier_assignment()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.courier_id IS NOT NULL AND NEW.courier_assigned_at IS NULL THEN
      NEW.courier_assigned_at := now();
    END IF;
    RETURN NEW;
  END IF;
  IF NEW.courier_id IS DISTINCT FROM OLD.courier_id THEN
    IF NEW.courier_id IS NULL THEN
      NEW.courier_assigned_at := NULL;
    ELSE
      NEW.courier_assigned_at := now();
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
CREATE OR REPLACE FUNCTION public.handle_orders_audit()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public'
AS $$
DECLARE
  uid uuid := auth.uid();
BEGIN
  IF uid IS NOT NULL THEN
    NEW.last_modified_by := uid;
  END IF;
  IF (TG_OP = 'UPDATE') THEN
    IF NEW.is_closed = true AND (OLD.is_closed IS DISTINCT FROM true) THEN
      NEW.closed_by := COALESCE(uid, NEW.closed_by);
      IF NEW.closed_at IS NULL THEN NEW.closed_at := now(); END IF;
    END IF;
    IF NEW.is_closed = false AND OLD.is_closed = true THEN
      NEW.closed_by := NULL;
      NEW.closed_at := NULL;
    END IF;
    IF NEW.is_courier_closed = true AND (OLD.is_courier_closed IS DISTINCT FROM true) THEN
      NEW.courier_closed_by := COALESCE(uid, NEW.courier_closed_by);
    END IF;
    IF NEW.is_courier_closed = false AND OLD.is_courier_closed = true THEN
      NEW.courier_closed_by := NULL;
    END IF;
    IF NEW.returned_to_sender = true AND (OLD.returned_to_sender IS DISTINCT FROM true) THEN
      NEW.returned_to_sender_at := now();
      NEW.returned_to_sender_by := COALESCE(uid, NEW.returned_to_sender_by);
    END IF;
    IF NEW.returned_to_sender = false AND OLD.returned_to_sender = true THEN
      NEW.returned_to_sender_at := NULL;
      NEW.returned_to_sender_by := NULL;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
GRANT EXECUTE ON FUNCTION public.has_role(uuid, app_role) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_owner_or_admin(uuid) TO authenticated;

-- FOREIGN KEYS
DO $$ BEGIN ALTER TABLE public.order_notes ADD CONSTRAINT fk_order_notes_order_id FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.delivery_prices ADD CONSTRAINT fk_delivery_prices_office_id FOREIGN KEY (office_id) REFERENCES public.offices(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.office_payments ADD CONSTRAINT fk_office_payments_office_id FOREIGN KEY (office_id) REFERENCES public.offices(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.user_permissions ADD CONSTRAINT fk_user_permissions_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.diaries ADD CONSTRAINT fk_diaries_office_id FOREIGN KEY (office_id) REFERENCES public.offices(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.diary_orders ADD CONSTRAINT fk_diary_orders_order_id FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.diary_orders ADD CONSTRAINT fk_diary_orders_diary_id FOREIGN KEY (diary_id) REFERENCES public.diaries(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.diary_orders ADD CONSTRAINT fk_diary_orders_copied_from_diary_id FOREIGN KEY (copied_from_diary_id) REFERENCES public.diaries(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.expenses ADD CONSTRAINT fk_expenses_office_id FOREIGN KEY (office_id) REFERENCES public.offices(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.cash_flow_entries ADD CONSTRAINT fk_cash_flow_entries_office_id FOREIGN KEY (office_id) REFERENCES public.offices(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.courier_locations ADD CONSTRAINT fk_courier_locations_courier_id FOREIGN KEY (courier_id) REFERENCES auth.users(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.messages ADD CONSTRAINT fk_messages_sender_id FOREIGN KEY (sender_id) REFERENCES auth.users(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.messages ADD CONSTRAINT fk_messages_receiver_id FOREIGN KEY (receiver_id) REFERENCES auth.users(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.office_daily_closings ADD CONSTRAINT fk_office_daily_closings_office_id FOREIGN KEY (office_id) REFERENCES public.offices(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.profiles ADD CONSTRAINT fk_profiles_id FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.profiles ADD CONSTRAINT fk_profiles_office_id FOREIGN KEY (office_id) REFERENCES public.offices(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.user_roles ADD CONSTRAINT fk_user_roles_user_id FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.orders ADD CONSTRAINT fk_orders_product_id FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.orders ADD CONSTRAINT fk_orders_status_id FOREIGN KEY (status_id) REFERENCES public.order_statuses(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.orders ADD CONSTRAINT fk_orders_office_id FOREIGN KEY (office_id) REFERENCES public.offices(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.orders ADD CONSTRAINT fk_orders_company_id FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE SET NULL; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.courier_collections ADD CONSTRAINT fk_courier_collections_order_id FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.company_payments ADD CONSTRAINT fk_company_payments_company_id FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER TABLE public.scan_session_items ADD CONSTRAINT fk_scan_session_items_session_id FOREIGN KEY (session_id) REFERENCES public.scan_sessions(id) ON DELETE CASCADE; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;

-- RLS
ALTER TABLE public.offices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_statuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.advances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courier_bonuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.delivery_prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.office_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.diaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.diary_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cash_flow_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courier_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.office_daily_closings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courier_collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.office_daily_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scan_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scan_session_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;

-- POLICIES
DROP POLICY IF EXISTS "Authenticated can read order notes" ON public.order_notes;
CREATE POLICY "Authenticated can read order notes" ON public.order_notes FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Owner/Admin can insert notes" ON public.order_notes;
CREATE POLICY "Owner/Admin can insert notes" ON public.order_notes FOR INSERT TO authenticated WITH CHECK (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Courier can insert notes on assigned orders" ON public.order_notes;
CREATE POLICY "Courier can insert notes on assigned orders" ON public.order_notes FOR INSERT TO authenticated WITH CHECK (has_role(auth.uid(), 'courier') AND EXISTS (SELECT 1 FROM orders WHERE id = order_id AND courier_id = auth.uid()));
DROP POLICY IF EXISTS "Owner can delete notes" ON public.order_notes;
CREATE POLICY "Owner can delete notes" ON public.order_notes FOR DELETE TO authenticated USING (has_role(auth.uid(), 'owner'));
DROP POLICY IF EXISTS "Owner/Admin can read advances" ON public.advances;
CREATE POLICY "Owner/Admin can read advances" ON public.advances FOR SELECT TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can insert advances" ON public.advances;
CREATE POLICY "Owner/Admin can insert advances" ON public.advances FOR INSERT TO authenticated WITH CHECK (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can update advances" ON public.advances;
CREATE POLICY "Owner/Admin can update advances" ON public.advances FOR UPDATE TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner can delete advances" ON public.advances;
CREATE POLICY "Owner can delete advances" ON public.advances FOR DELETE TO authenticated USING (has_role(auth.uid(), 'owner'));
DROP POLICY IF EXISTS "Courier can read own advances" ON public.advances;
CREATE POLICY "Courier can read own advances" ON public.advances FOR SELECT TO authenticated USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Owner/Admin can read bonuses" ON public.courier_bonuses;
CREATE POLICY "Owner/Admin can read bonuses" ON public.courier_bonuses FOR SELECT TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can insert bonuses" ON public.courier_bonuses;
CREATE POLICY "Owner/Admin can insert bonuses" ON public.courier_bonuses FOR INSERT TO authenticated WITH CHECK (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can update bonuses" ON public.courier_bonuses;
CREATE POLICY "Owner/Admin can update bonuses" ON public.courier_bonuses FOR UPDATE TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner can delete bonuses" ON public.courier_bonuses;
CREATE POLICY "Owner can delete bonuses" ON public.courier_bonuses FOR DELETE TO authenticated USING (has_role(auth.uid(), 'owner'));
DROP POLICY IF EXISTS "Authenticated can read delivery_prices" ON public.delivery_prices;
CREATE POLICY "Authenticated can read delivery_prices" ON public.delivery_prices FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Owner/Admin can insert delivery_prices" ON public.delivery_prices;
CREATE POLICY "Owner/Admin can insert delivery_prices" ON public.delivery_prices FOR INSERT TO authenticated WITH CHECK (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can update delivery_prices" ON public.delivery_prices;
CREATE POLICY "Owner/Admin can update delivery_prices" ON public.delivery_prices FOR UPDATE TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner can delete delivery_prices" ON public.delivery_prices;
CREATE POLICY "Owner can delete delivery_prices" ON public.delivery_prices FOR DELETE TO authenticated USING (has_role(auth.uid(), 'owner'::app_role));
DROP POLICY IF EXISTS "Owner/Admin can read office_payments" ON public.office_payments;
CREATE POLICY "Owner/Admin can read office_payments" ON public.office_payments FOR SELECT TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can insert office_payments" ON public.office_payments;
CREATE POLICY "Owner/Admin can insert office_payments" ON public.office_payments FOR INSERT TO authenticated WITH CHECK (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can update office_payments" ON public.office_payments;
CREATE POLICY "Owner/Admin can update office_payments" ON public.office_payments FOR UPDATE TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner can delete office_payments" ON public.office_payments;
CREATE POLICY "Owner can delete office_payments" ON public.office_payments FOR DELETE TO authenticated USING (has_role(auth.uid(), 'owner'));
DROP POLICY IF EXISTS "Owner/Admin can read permissions" ON public.user_permissions;
CREATE POLICY "Owner/Admin can read permissions" ON public.user_permissions FOR SELECT TO authenticated USING (is_owner_or_admin(auth.uid()) OR user_id = auth.uid());
DROP POLICY IF EXISTS "Owner can insert permissions" ON public.user_permissions;
CREATE POLICY "Owner can insert permissions" ON public.user_permissions FOR INSERT TO authenticated WITH CHECK (has_role(auth.uid(), 'owner'));
DROP POLICY IF EXISTS "Owner can update permissions" ON public.user_permissions;
CREATE POLICY "Owner can update permissions" ON public.user_permissions FOR UPDATE TO authenticated USING (has_role(auth.uid(), 'owner'));
DROP POLICY IF EXISTS "Owner can delete permissions" ON public.user_permissions;
CREATE POLICY "Owner can delete permissions" ON public.user_permissions FOR DELETE TO authenticated USING (has_role(auth.uid(), 'owner'));
DROP POLICY IF EXISTS "Office user can read own office orders" ON public.orders;
CREATE POLICY "Office user can read own office orders" ON public.orders FOR SELECT TO authenticated USING (has_role(auth.uid(), 'office'::app_role) AND office_id = (SELECT office_id FROM public.profiles WHERE id = auth.uid()) AND is_closed = false);
DROP POLICY IF EXISTS "Office user can read own office payments" ON public.office_payments;
CREATE POLICY "Office user can read own office payments" ON public.office_payments FOR SELECT TO authenticated USING (has_role(auth.uid(), 'office'::app_role) AND office_id = (SELECT office_id FROM public.profiles WHERE id = auth.uid()));
DROP POLICY IF EXISTS "Office user can insert orders for own office" ON public.orders;
CREATE POLICY "Office user can insert orders for own office" ON public.orders FOR INSERT TO authenticated WITH CHECK (has_role(auth.uid(), 'office'::app_role) AND office_id = (SELECT profiles.office_id FROM profiles WHERE profiles.id = auth.uid()) AND EXISTS (SELECT 1 FROM offices WHERE offices.id = office_id AND offices.can_add_orders = true));
DROP POLICY IF EXISTS "Owner/Admin can read logs" ON public.activity_logs;
CREATE POLICY "Owner/Admin can read logs" ON public.activity_logs FOR SELECT USING (public.is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can read diaries" ON public.diaries;
CREATE POLICY "Owner/Admin can read diaries" ON public.diaries FOR SELECT TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can insert diaries" ON public.diaries;
CREATE POLICY "Owner/Admin can insert diaries" ON public.diaries FOR INSERT TO authenticated WITH CHECK (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can update diaries" ON public.diaries;
CREATE POLICY "Owner/Admin can update diaries" ON public.diaries FOR UPDATE TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner can delete diaries" ON public.diaries;
CREATE POLICY "Owner can delete diaries" ON public.diaries FOR DELETE TO authenticated USING (has_role(auth.uid(), 'owner'));
DROP POLICY IF EXISTS "Owner/Admin can read diary_orders" ON public.diary_orders;
CREATE POLICY "Owner/Admin can read diary_orders" ON public.diary_orders FOR SELECT TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can insert diary_orders" ON public.diary_orders;
CREATE POLICY "Owner/Admin can insert diary_orders" ON public.diary_orders FOR INSERT TO authenticated WITH CHECK (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can update diary_orders" ON public.diary_orders;
CREATE POLICY "Owner/Admin can update diary_orders" ON public.diary_orders FOR UPDATE TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner can delete diary_orders" ON public.diary_orders;
CREATE POLICY "Owner can delete diary_orders" ON public.diary_orders FOR DELETE TO authenticated USING (has_role(auth.uid(), 'owner'));
DROP POLICY IF EXISTS "Owner/Admin can read expenses" ON public.expenses;
CREATE POLICY "Owner/Admin can read expenses" ON public.expenses FOR SELECT TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can insert expenses" ON public.expenses;
CREATE POLICY "Owner/Admin can insert expenses" ON public.expenses FOR INSERT TO authenticated WITH CHECK (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can update expenses" ON public.expenses;
CREATE POLICY "Owner/Admin can update expenses" ON public.expenses FOR UPDATE TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner can delete expenses" ON public.expenses;
CREATE POLICY "Owner can delete expenses" ON public.expenses FOR DELETE TO authenticated USING (has_role(auth.uid(), 'owner'));
DROP POLICY IF EXISTS "Owner/Admin can read cash_flow" ON public.cash_flow_entries;
CREATE POLICY "Owner/Admin can read cash_flow" ON public.cash_flow_entries FOR SELECT TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can insert cash_flow" ON public.cash_flow_entries;
CREATE POLICY "Owner/Admin can insert cash_flow" ON public.cash_flow_entries FOR INSERT TO authenticated WITH CHECK (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can update cash_flow" ON public.cash_flow_entries;
CREATE POLICY "Owner/Admin can update cash_flow" ON public.cash_flow_entries FOR UPDATE TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner can delete cash_flow" ON public.cash_flow_entries;
CREATE POLICY "Owner can delete cash_flow" ON public.cash_flow_entries FOR DELETE TO authenticated USING (has_role(auth.uid(), 'owner'));
DROP POLICY IF EXISTS "Authenticated can read settings" ON public.app_settings;
CREATE POLICY "Authenticated can read settings" ON public.app_settings FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Owner can manage settings" ON public.app_settings;
CREATE POLICY "Owner can manage settings" ON public.app_settings FOR ALL TO authenticated USING (public.has_role(auth.uid(), 'owner')) WITH CHECK (public.has_role(auth.uid(), 'owner'));
DROP POLICY IF EXISTS "Courier can upsert own location" ON public.courier_locations;
CREATE POLICY "Courier can upsert own location" ON public.courier_locations FOR ALL TO authenticated USING (courier_id = auth.uid()) WITH CHECK (courier_id = auth.uid());
DROP POLICY IF EXISTS "Owner/Admin can read all locations" ON public.courier_locations;
CREATE POLICY "Owner/Admin can read all locations" ON public.courier_locations FOR SELECT TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Users can read own messages" ON public.messages;
CREATE POLICY "Users can read own messages" ON public.messages FOR SELECT TO authenticated USING (sender_id = auth.uid() OR receiver_id = auth.uid());
DROP POLICY IF EXISTS "Users can insert messages" ON public.messages;
CREATE POLICY "Users can insert messages" ON public.messages FOR INSERT TO authenticated WITH CHECK (sender_id = auth.uid());
DROP POLICY IF EXISTS "Receiver can update (mark read)" ON public.messages;
CREATE POLICY "Receiver can update (mark read)" ON public.messages
  FOR UPDATE TO authenticated
  USING (receiver_id = auth.uid());
DROP POLICY IF EXISTS "Owner/Admin can read all messages" ON public.messages;
CREATE POLICY "Owner/Admin can read all messages" ON public.messages FOR SELECT TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can manage closings" ON public.office_daily_closings;
CREATE POLICY "Owner/Admin can manage closings" ON public.office_daily_closings FOR ALL TO authenticated USING (is_owner_or_admin(auth.uid())) WITH CHECK (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Authenticated can read profiles" ON public.profiles;
CREATE POLICY "Authenticated can read profiles" ON public.profiles FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE TO authenticated USING (id = auth.uid());
DROP POLICY IF EXISTS "Owner/Admin can update all profiles" ON public.profiles;
CREATE POLICY "Owner/Admin can update all profiles" ON public.profiles FOR UPDATE TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Authenticated can read offices" ON public.offices;
CREATE POLICY "Authenticated can read offices" ON public.offices FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Owner/Admin can insert offices" ON public.offices;
CREATE POLICY "Owner/Admin can insert offices" ON public.offices FOR INSERT TO authenticated WITH CHECK (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can update offices" ON public.offices;
CREATE POLICY "Owner/Admin can update offices" ON public.offices FOR UPDATE TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner can delete offices" ON public.offices;
CREATE POLICY "Owner can delete offices" ON public.offices FOR DELETE TO authenticated USING (has_role(auth.uid(), 'owner'));
DROP POLICY IF EXISTS "Authenticated can read companies" ON public.companies;
CREATE POLICY "Authenticated can read companies" ON public.companies FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Owner/Admin can insert companies" ON public.companies;
CREATE POLICY "Owner/Admin can insert companies" ON public.companies FOR INSERT TO authenticated WITH CHECK (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can update companies" ON public.companies;
CREATE POLICY "Owner/Admin can update companies" ON public.companies FOR UPDATE TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner can delete companies" ON public.companies;
CREATE POLICY "Owner can delete companies" ON public.companies FOR DELETE TO authenticated USING (has_role(auth.uid(), 'owner'));
DROP POLICY IF EXISTS "Authenticated can read statuses" ON public.order_statuses;
CREATE POLICY "Authenticated can read statuses" ON public.order_statuses FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Owner/Admin can insert statuses" ON public.order_statuses;
CREATE POLICY "Owner/Admin can insert statuses" ON public.order_statuses FOR INSERT TO authenticated WITH CHECK (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can update statuses" ON public.order_statuses;
CREATE POLICY "Owner/Admin can update statuses" ON public.order_statuses FOR UPDATE TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner can delete statuses" ON public.order_statuses;
CREATE POLICY "Owner can delete statuses" ON public.order_statuses FOR DELETE TO authenticated USING (has_role(auth.uid(), 'owner'));
DROP POLICY IF EXISTS "Authenticated can read products" ON public.products;
CREATE POLICY "Authenticated can read products" ON public.products FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Owner/Admin can insert products" ON public.products;
CREATE POLICY "Owner/Admin can insert products" ON public.products FOR INSERT TO authenticated WITH CHECK (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can update products" ON public.products;
CREATE POLICY "Owner/Admin can update products" ON public.products FOR UPDATE TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner can delete products" ON public.products;
CREATE POLICY "Owner can delete products" ON public.products FOR DELETE TO authenticated USING (has_role(auth.uid(), 'owner'));
DROP POLICY IF EXISTS "Authenticated can read roles" ON public.user_roles;
CREATE POLICY "Authenticated can read roles" ON public.user_roles FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Owner/Admin can insert roles" ON public.user_roles;
CREATE POLICY "Owner/Admin can insert roles" ON public.user_roles FOR INSERT TO authenticated WITH CHECK (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can update roles" ON public.user_roles;
CREATE POLICY "Owner/Admin can update roles" ON public.user_roles FOR UPDATE TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner can delete roles" ON public.user_roles;
CREATE POLICY "Owner can delete roles" ON public.user_roles FOR DELETE TO authenticated USING (has_role(auth.uid(), 'owner'));
DROP POLICY IF EXISTS "Authenticated can insert logs" ON public.activity_logs;
CREATE POLICY "Authenticated can insert logs" ON public.activity_logs FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "Owner/Admin can read orders" ON public.orders;
CREATE POLICY "Owner/Admin can read orders" ON public.orders FOR SELECT TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Courier can read assigned orders" ON public.orders;
CREATE POLICY "Courier can read assigned orders" ON public.orders FOR SELECT TO authenticated USING (courier_id = auth.uid());
DROP POLICY IF EXISTS "Owner/Admin can insert orders" ON public.orders;
CREATE POLICY "Owner/Admin can insert orders" ON public.orders FOR INSERT TO authenticated WITH CHECK (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can update orders" ON public.orders;
CREATE POLICY "Owner/Admin can update orders" ON public.orders FOR UPDATE TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Courier can update assigned orders" ON public.orders;
CREATE POLICY "Courier can update assigned orders" ON public.orders FOR UPDATE TO authenticated USING (courier_id = auth.uid());
DROP POLICY IF EXISTS "Owner can delete orders" ON public.orders;
CREATE POLICY "Owner can delete orders" ON public.orders FOR DELETE TO authenticated USING (has_role(auth.uid(), 'owner'));
DROP POLICY IF EXISTS "Receiver can update messages" ON public.messages;
CREATE POLICY "Receiver can update messages" ON public.messages FOR UPDATE TO authenticated USING (receiver_id = auth.uid());
DROP POLICY IF EXISTS "Authenticated can read collections" ON public.courier_collections;
CREATE POLICY "Authenticated can read collections" ON public.courier_collections FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Authenticated can insert collections" ON public.courier_collections;
CREATE POLICY "Authenticated can insert collections" ON public.courier_collections FOR INSERT TO authenticated WITH CHECK (true);
DROP POLICY IF EXISTS "Authenticated can update collections" ON public.courier_collections;
CREATE POLICY "Authenticated can update collections" ON public.courier_collections FOR UPDATE TO authenticated USING (true);
DROP POLICY IF EXISTS "Authenticated can delete collections" ON public.courier_collections;
CREATE POLICY "Authenticated can delete collections" ON public.courier_collections FOR DELETE TO authenticated USING (true);
DROP POLICY IF EXISTS "Owner/Admin can read company_payments" ON public.company_payments;
CREATE POLICY "Owner/Admin can read company_payments" ON public.company_payments FOR SELECT TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can insert company_payments" ON public.company_payments;
CREATE POLICY "Owner/Admin can insert company_payments" ON public.company_payments FOR INSERT TO authenticated WITH CHECK (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner/Admin can update company_payments" ON public.company_payments;
CREATE POLICY "Owner/Admin can update company_payments" ON public.company_payments FOR UPDATE TO authenticated USING (is_owner_or_admin(auth.uid()));
DROP POLICY IF EXISTS "Owner can delete company_payments" ON public.company_payments;
CREATE POLICY "Owner can delete company_payments" ON public.company_payments FOR DELETE TO authenticated USING (has_role(auth.uid(), 'owner'));


DROP POLICY IF EXISTS "profiles_select" ON public.profiles;
CREATE POLICY "profiles_select" ON public.profiles FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "profiles_update" ON public.profiles;
CREATE POLICY "profiles_update" ON public.profiles FOR UPDATE TO authenticated USING (true);
DROP POLICY IF EXISTS "user_roles_select" ON public.user_roles;
CREATE POLICY "user_roles_select" ON public.user_roles FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "user_roles_all" ON public.user_roles;
CREATE POLICY "user_roles_all" ON public.user_roles FOR ALL TO service_role USING (true);
DROP POLICY IF EXISTS "user_permissions_select" ON public.user_permissions;
CREATE POLICY "user_permissions_select" ON public.user_permissions FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "user_permissions_all" ON public.user_permissions;
CREATE POLICY "user_permissions_all" ON public.user_permissions FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "offices_all" ON public.offices;
CREATE POLICY "offices_all" ON public.offices FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "order_statuses_all" ON public.order_statuses;
CREATE POLICY "order_statuses_all" ON public.order_statuses FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "products_all" ON public.products;
CREATE POLICY "products_all" ON public.products FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "companies_all" ON public.companies;
CREATE POLICY "companies_all" ON public.companies FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "orders_all" ON public.orders;
CREATE POLICY "orders_all" ON public.orders FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "order_notes_all" ON public.order_notes;
CREATE POLICY "order_notes_all" ON public.order_notes FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "delivery_prices_all" ON public.delivery_prices;
CREATE POLICY "delivery_prices_all" ON public.delivery_prices FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "diaries_all" ON public.diaries;
CREATE POLICY "diaries_all" ON public.diaries FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "diary_orders_all" ON public.diary_orders;
CREATE POLICY "diary_orders_all" ON public.diary_orders FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "courier_collections_all" ON public.courier_collections;
CREATE POLICY "courier_collections_all" ON public.courier_collections FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "courier_bonuses_all" ON public.courier_bonuses;
CREATE POLICY "courier_bonuses_all" ON public.courier_bonuses FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "advances_all" ON public.advances;
CREATE POLICY "advances_all" ON public.advances FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "company_payments_all" ON public.company_payments;
CREATE POLICY "company_payments_all" ON public.company_payments FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "office_payments_all" ON public.office_payments;
CREATE POLICY "office_payments_all" ON public.office_payments FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "office_daily_closings_all" ON public.office_daily_closings;
CREATE POLICY "office_daily_closings_all" ON public.office_daily_closings FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "expenses_all" ON public.expenses;
CREATE POLICY "expenses_all" ON public.expenses FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "cash_flow_entries_all" ON public.cash_flow_entries;
CREATE POLICY "cash_flow_entries_all" ON public.cash_flow_entries FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "app_settings_all" ON public.app_settings;
CREATE POLICY "app_settings_all" ON public.app_settings FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "activity_logs_all" ON public.activity_logs;
CREATE POLICY "activity_logs_all" ON public.activity_logs FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "courier_locations_all" ON public.courier_locations;
CREATE POLICY "courier_locations_all" ON public.courier_locations FOR ALL TO authenticated USING (true);
DROP POLICY IF EXISTS "messages_select" ON public.messages;
CREATE POLICY "messages_select" ON public.messages FOR SELECT TO authenticated USING (sender_id = auth.uid() OR receiver_id = auth.uid());
DROP POLICY IF EXISTS "messages_insert" ON public.messages;
CREATE POLICY "messages_insert" ON public.messages FOR INSERT TO authenticated WITH CHECK (sender_id = auth.uid());
DROP POLICY IF EXISTS "messages_update" ON public.messages;
CREATE POLICY "messages_update" ON public.messages FOR UPDATE TO authenticated USING (receiver_id = auth.uid());
DROP POLICY IF EXISTS "office_daily_expenses_all" ON public.office_daily_expenses;
CREATE POLICY "office_daily_expenses_all" ON public.office_daily_expenses FOR ALL TO authenticated USING (true) WITH CHECK (true);
DROP POLICY IF EXISTS "profiles_insert" ON public.profiles;
CREATE POLICY "profiles_insert" ON public.profiles FOR INSERT TO authenticated WITH CHECK (true);

-- TRIGGERS
DROP TRIGGER IF EXISTS set_diary_number ON public.diaries;
CREATE TRIGGER set_diary_number BEFORE INSERT ON public.diaries FOR EACH ROW EXECUTE FUNCTION public.generate_diary_number();
DROP TRIGGER IF EXISTS auto_diary_on_order_insert ON public.orders;
CREATE TRIGGER auto_diary_on_order_insert AFTER INSERT ON public.orders FOR EACH ROW EXECUTE FUNCTION public.auto_create_diary_for_order();
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
DROP TRIGGER IF EXISTS set_barcode_on_insert ON public.orders;
CREATE TRIGGER set_barcode_on_insert BEFORE INSERT ON public.orders FOR EACH ROW EXECUTE FUNCTION public.generate_barcode();
DROP TRIGGER IF EXISTS set_order_barcode ON public.orders;
CREATE TRIGGER set_order_barcode
  BEFORE INSERT ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.generate_order_barcode();
DROP TRIGGER IF EXISTS handle_orders_courier_assignment ON public.orders;
CREATE TRIGGER handle_orders_courier_assignment
BEFORE INSERT OR UPDATE ON public.orders
FOR EACH ROW EXECUTE FUNCTION public.handle_orders_courier_assignment();
DROP TRIGGER IF EXISTS trg_orders_audit ON public.orders;
CREATE TRIGGER trg_orders_audit
BEFORE INSERT OR UPDATE ON public.orders
FOR EACH ROW EXECUTE FUNCTION public.handle_orders_audit();

-- REALTIME
ALTER TABLE public.scan_session_items REPLICA IDENTITY FULL;
ALTER TABLE public.orders REPLICA IDENTITY FULL;
ALTER TABLE public.order_status_history REPLICA IDENTITY FULL;
ALTER TABLE public.messages REPLICA IDENTITY FULL;
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.scan_session_items; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.orders; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.order_status_history; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;
DO $$ BEGIN ALTER PUBLICATION supabase_realtime ADD TABLE public.messages; EXCEPTION WHEN duplicate_object THEN NULL; WHEN others THEN NULL; END $$;

-- SEED
INSERT INTO public.order_statuses (name, color, sort_order)
SELECT name, color, sort_order FROM (VALUES
  ('جديد', '#6b7280', 0),
  ('قيد التوصيل', '#3b82f6', 1),
  ('تم التسليم', '#10b981', 2),
  ('مرتجع', '#ef4444', 3),
  ('مرتجع بشحن', '#f97316', 4),
  ('مرتجع دون شحن', '#dc2626', 5),
  ('مؤجل', '#eab308', 6),
  ('رفض', '#991b1b', 7),
  ('رفض واخد شحن', '#7c2d12', 8)
) AS t(name, color, sort_order)
WHERE NOT EXISTS (SELECT 1 FROM public.order_statuses WHERE order_statuses.name = t.name);
INSERT INTO public.order_statuses (name, color, sort_order) SELECT 'تسليم جزئي','#f59e0b',15 WHERE NOT EXISTS (SELECT 1 FROM public.order_statuses WHERE name='تسليم جزئي');