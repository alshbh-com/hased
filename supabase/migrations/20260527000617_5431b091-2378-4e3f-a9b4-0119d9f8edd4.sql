-- =============================================
-- FULL ALKING SHIPPING SYSTEM SCHEMA
-- =============================================

-- 1. Create app_role enum
CREATE TYPE public.app_role AS ENUM ('owner', 'admin', 'courier', 'office');

-- 2. Profiles table
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT DEFAULT '',
  phone TEXT DEFAULT '',
  login_code TEXT DEFAULT '',
  office_id UUID,
  salary NUMERIC DEFAULT 0,
  commission_amount NUMERIC DEFAULT 0,
  rejection_commission NUMERIC DEFAULT 0,
  address TEXT DEFAULT '',
  coverage_areas TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "profiles_select" ON public.profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "profiles_update" ON public.profiles FOR UPDATE TO authenticated USING (true);
CREATE POLICY "profiles_insert" ON public.profiles FOR INSERT TO authenticated WITH CHECK (true);

-- 3. User roles
CREATE TABLE public.user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role app_role NOT NULL,
  UNIQUE (user_id, role)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_roles TO authenticated;
GRANT ALL ON public.user_roles TO service_role;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_roles_select" ON public.user_roles FOR SELECT TO authenticated USING (true);
CREATE POLICY "user_roles_all" ON public.user_roles FOR ALL TO service_role USING (true);

-- 4. User permissions
CREATE TABLE public.user_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  section TEXT NOT NULL,
  permission TEXT NOT NULL DEFAULT 'edit',
  UNIQUE (user_id, section)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_permissions TO authenticated;
GRANT ALL ON public.user_permissions TO service_role;
ALTER TABLE public.user_permissions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_permissions_select" ON public.user_permissions FOR SELECT TO authenticated USING (true);
CREATE POLICY "user_permissions_all" ON public.user_permissions FOR ALL TO authenticated USING (true);

-- 5. Offices
CREATE TABLE public.offices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  phone TEXT DEFAULT '',
  address TEXT DEFAULT '',
  owner_name TEXT DEFAULT '',
  owner_phone TEXT DEFAULT '',
  specialty TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  can_add_orders BOOLEAN DEFAULT false,
  office_commission NUMERIC DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.offices TO authenticated;
GRANT ALL ON public.offices TO service_role;
ALTER TABLE public.offices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "offices_all" ON public.offices FOR ALL TO authenticated USING (true);

ALTER TABLE public.profiles ADD CONSTRAINT profiles_office_fk FOREIGN KEY (office_id) REFERENCES public.offices(id) ON DELETE SET NULL;

-- 6. Order statuses
CREATE TABLE public.order_statuses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  color TEXT DEFAULT '#6b7280',
  sort_order INT DEFAULT 0,
  is_fixed BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.order_statuses TO authenticated;
GRANT ALL ON public.order_statuses TO service_role;
ALTER TABLE public.order_statuses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "order_statuses_all" ON public.order_statuses FOR ALL TO authenticated USING (true);

INSERT INTO public.order_statuses (name, color, sort_order) VALUES 
('جديد', '#3b82f6', 0),
('قيد التوصيل', '#f59e0b', 1),
('تم التسليم', '#22c55e', 2),
('تسليم جزئي', '#06b6d4', 3),
('مؤجل', '#a855f7', 4),
('رفض ودفع شحن', '#ef4444', 5),
('رفض ولم يدفع شحن', '#dc2626', 6),
('استلم ودفع نص الشحن', '#f97316', 7),
('تهرب', '#6b7280', 8),
('ملغي', '#374151', 9),
('الرقم غلط', '#ef4444', 10),
('مغلق', '#6b7280', 11);

-- 7. Products
CREATE TABLE public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  quantity INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.products TO authenticated;
GRANT ALL ON public.products TO service_role;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
CREATE POLICY "products_all" ON public.products FOR ALL TO authenticated USING (true);

-- 8. Companies
CREATE TABLE public.companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  agreement_price NUMERIC DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.companies TO authenticated;
GRANT ALL ON public.companies TO service_role;
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
CREATE POLICY "companies_all" ON public.companies FOR ALL TO authenticated USING (true);

-- 9. Orders
CREATE TABLE public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tracking_id TEXT UNIQUE,
  barcode TEXT UNIQUE,
  customer_name TEXT DEFAULT '',
  customer_phone TEXT DEFAULT '',
  customer_code TEXT DEFAULT '',
  product_name TEXT DEFAULT '',
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  quantity INT DEFAULT 1,
  price NUMERIC DEFAULT 0,
  delivery_price NUMERIC DEFAULT 0,
  office_id UUID REFERENCES public.offices(id) ON DELETE SET NULL,
  status_id UUID REFERENCES public.order_statuses(id) ON DELETE SET NULL,
  courier_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  courier_assigned_at TIMESTAMPTZ,
  company_id UUID REFERENCES public.companies(id) ON DELETE SET NULL,
  color TEXT DEFAULT '',
  size TEXT DEFAULT '',
  address TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  priority TEXT DEFAULT 'normal',
  is_closed BOOLEAN DEFAULT false,
  is_courier_closed BOOLEAN DEFAULT false,
  is_settled BOOLEAN DEFAULT false,
  partial_amount NUMERIC DEFAULT 0,
  shipping_paid NUMERIC DEFAULT 0,
  closed_at TIMESTAMPTZ,
  closed_by UUID,
  courier_closed_by UUID,
  last_modified_by UUID,
  returned_to_sender BOOLEAN NOT NULL DEFAULT false,
  returned_to_sender_at TIMESTAMPTZ,
  returned_to_sender_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.orders TO authenticated;
GRANT ALL ON public.orders TO service_role;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "orders_all" ON public.orders FOR ALL TO authenticated USING (true);
CREATE INDEX idx_orders_courier_assigned_at ON public.orders (courier_id, courier_assigned_at DESC) WHERE courier_id IS NOT NULL;

-- 10. Order notes
CREATE TABLE public.order_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  note TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.order_notes TO authenticated;
GRANT ALL ON public.order_notes TO service_role;
ALTER TABLE public.order_notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "order_notes_all" ON public.order_notes FOR ALL TO authenticated USING (true);

-- 11. Delivery prices
CREATE TABLE public.delivery_prices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id UUID REFERENCES public.offices(id) ON DELETE CASCADE,
  governorate TEXT NOT NULL,
  price NUMERIC DEFAULT 0,
  pickup_price NUMERIC DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.delivery_prices TO authenticated;
GRANT ALL ON public.delivery_prices TO service_role;
ALTER TABLE public.delivery_prices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "delivery_prices_all" ON public.delivery_prices FOR ALL TO authenticated USING (true);

-- 12. Diaries
CREATE TABLE public.diaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id UUID REFERENCES public.offices(id) ON DELETE CASCADE NOT NULL,
  diary_date DATE NOT NULL DEFAULT CURRENT_DATE,
  diary_number SERIAL,
  is_closed BOOLEAN DEFAULT false,
  is_archived BOOLEAN DEFAULT false,
  lock_status_updates BOOLEAN DEFAULT false,
  prevent_new_orders BOOLEAN DEFAULT false,
  cash_arrived_entries JSONB DEFAULT '[]'::jsonb,
  balance NUMERIC DEFAULT 0,
  previous_due NUMERIC DEFAULT 0,
  show_postponed_due BOOLEAN DEFAULT true,
  manual_arrived_total NUMERIC,
  orange_extra_due NUMERIC DEFAULT 0,
  orange_extra_due_reason TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.diaries TO authenticated;
GRANT ALL ON public.diaries TO service_role;
ALTER TABLE public.diaries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "diaries_all" ON public.diaries FOR ALL TO authenticated USING (true);

-- 13. Diary orders
CREATE TABLE public.diary_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  diary_id UUID REFERENCES public.diaries(id) ON DELETE CASCADE NOT NULL,
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
  status_inside_diary TEXT DEFAULT 'بدون حالة',
  partial_amount NUMERIC DEFAULT 0,
  n_column TEXT DEFAULT '',
  manual_return_status TEXT DEFAULT '',
  manual_shipping NUMERIC DEFAULT 0,
  manual_collected NUMERIC DEFAULT 0,
  manual_pickup NUMERIC DEFAULT 0,
  manual_arrived NUMERIC DEFAULT 0,
  manual_shipping_diff NUMERIC DEFAULT 0,
  manual_delivery_commission NUMERIC DEFAULT 0,
  manual_reject_no_ship NUMERIC DEFAULT 0,
  manual_return_penalty NUMERIC DEFAULT 0,
  manual_total_amount NUMERIC,
  manual_shipping_amount NUMERIC,
  notes TEXT DEFAULT '',
  locked_status BOOLEAN DEFAULT false,
  copied_from_diary_id UUID REFERENCES public.diaries(id) ON DELETE SET NULL,
  copied_from_diary_order_id UUID REFERENCES public.diary_orders(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.diary_orders TO authenticated;
GRANT ALL ON public.diary_orders TO service_role;
ALTER TABLE public.diary_orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "diary_orders_all" ON public.diary_orders FOR ALL TO authenticated USING (true);

-- 14. Courier collections
CREATE TABLE public.courier_collections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  courier_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  amount NUMERIC DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.courier_collections TO authenticated;
GRANT ALL ON public.courier_collections TO service_role;
ALTER TABLE public.courier_collections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "courier_collections_all" ON public.courier_collections FOR ALL TO authenticated USING (true);

-- 15. Courier bonuses
CREATE TABLE public.courier_bonuses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  courier_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  amount NUMERIC DEFAULT 0,
  reason TEXT DEFAULT '',
  type TEXT DEFAULT 'special',
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.courier_bonuses TO authenticated;
GRANT ALL ON public.courier_bonuses TO service_role;
ALTER TABLE public.courier_bonuses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "courier_bonuses_all" ON public.courier_bonuses FOR ALL TO authenticated USING (true);

-- 16. Advances
CREATE TABLE public.advances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  amount NUMERIC DEFAULT 0,
  reason TEXT DEFAULT '',
  type TEXT DEFAULT 'advance',
  created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.advances TO authenticated;
GRANT ALL ON public.advances TO service_role;
ALTER TABLE public.advances ENABLE ROW LEVEL SECURITY;
CREATE POLICY "advances_all" ON public.advances FOR ALL TO authenticated USING (true);

-- 17. Company payments
CREATE TABLE public.company_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE NOT NULL,
  amount NUMERIC DEFAULT 0,
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.company_payments TO authenticated;
GRANT ALL ON public.company_payments TO service_role;
ALTER TABLE public.company_payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "company_payments_all" ON public.company_payments FOR ALL TO authenticated USING (true);

-- 18. Office payments
CREATE TABLE public.office_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id UUID REFERENCES public.offices(id) ON DELETE CASCADE,
  amount NUMERIC DEFAULT 0,
  type TEXT DEFAULT 'advance',
  notes TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.office_payments TO authenticated;
GRANT ALL ON public.office_payments TO service_role;
ALTER TABLE public.office_payments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "office_payments_all" ON public.office_payments FOR ALL TO authenticated USING (true);

-- 19. Office daily closings
CREATE TABLE public.office_daily_closings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id UUID REFERENCES public.offices(id) ON DELETE CASCADE NOT NULL,
  closing_date DATE NOT NULL DEFAULT CURRENT_DATE,
  data_json JSONB DEFAULT '[]'::jsonb,
  pickup_rate NUMERIC DEFAULT 0,
  is_locked BOOLEAN DEFAULT false,
  is_closed BOOLEAN DEFAULT false,
  prevent_add BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (office_id, closing_date)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.office_daily_closings TO authenticated;
GRANT ALL ON public.office_daily_closings TO service_role;
ALTER TABLE public.office_daily_closings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "office_daily_closings_all" ON public.office_daily_closings FOR ALL TO authenticated USING (true);

-- 19b. Office daily expenses
CREATE TABLE public.office_daily_expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  office_id UUID,
  expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
  category TEXT NOT NULL DEFAULT 'office',
  amount NUMERIC DEFAULT 0,
  notes TEXT DEFAULT '',
  created_by UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.office_daily_expenses TO authenticated;
GRANT ALL ON public.office_daily_expenses TO service_role;
ALTER TABLE public.office_daily_expenses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "office_daily_expenses_all" ON public.office_daily_expenses FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE INDEX idx_office_daily_expenses_office_date ON public.office_daily_expenses (office_id, expense_date);

-- 20. Expenses
CREATE TABLE public.expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  expense_name TEXT NOT NULL,
  amount NUMERIC DEFAULT 0,
  category TEXT DEFAULT 'أخرى',
  notes TEXT DEFAULT '',
  expense_date DATE DEFAULT CURRENT_DATE,
  office_id UUID REFERENCES public.offices(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.expenses TO authenticated;
GRANT ALL ON public.expenses TO service_role;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "expenses_all" ON public.expenses FOR ALL TO authenticated USING (true);

-- 21. Cash flow
CREATE TABLE public.cash_flow_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT DEFAULT 'inside',
  amount NUMERIC DEFAULT 0,
  reason TEXT DEFAULT '',
  notes TEXT DEFAULT '',
  entry_date DATE DEFAULT CURRENT_DATE,
  office_id UUID REFERENCES public.offices(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cash_flow_entries TO authenticated;
GRANT ALL ON public.cash_flow_entries TO service_role;
ALTER TABLE public.cash_flow_entries ENABLE ROW LEVEL SECURITY;
CREATE POLICY "cash_flow_entries_all" ON public.cash_flow_entries FOR ALL TO authenticated USING (true);

-- 22. App settings
CREATE TABLE public.app_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  value TEXT DEFAULT '',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.app_settings TO authenticated;
GRANT ALL ON public.app_settings TO service_role;
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "app_settings_all" ON public.app_settings FOR ALL TO authenticated USING (true);

-- 23. Activity logs
CREATE TABLE public.activity_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  details JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.activity_logs TO authenticated;
GRANT ALL ON public.activity_logs TO service_role;
ALTER TABLE public.activity_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "activity_logs_all" ON public.activity_logs FOR ALL TO authenticated USING (true);

-- 24. Courier locations
CREATE TABLE public.courier_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  courier_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  accuracy DOUBLE PRECISION DEFAULT 0,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.courier_locations TO authenticated;
GRANT ALL ON public.courier_locations TO service_role;
ALTER TABLE public.courier_locations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "courier_locations_all" ON public.courier_locations FOR ALL TO authenticated USING (true);

-- 25. Messages
CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  receiver_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.messages TO authenticated;
GRANT ALL ON public.messages TO service_role;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "messages_select" ON public.messages FOR SELECT TO authenticated USING (sender_id = auth.uid() OR receiver_id = auth.uid());
CREATE POLICY "messages_insert" ON public.messages FOR INSERT TO authenticated WITH CHECK (sender_id = auth.uid());
CREATE POLICY "messages_update" ON public.messages FOR UPDATE TO authenticated USING (receiver_id = auth.uid());

-- 26. Scan sessions
CREATE TABLE public.scan_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ended_at TIMESTAMPTZ,
  total_count INTEGER NOT NULL DEFAULT 0,
  notes TEXT DEFAULT ''
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.scan_sessions TO authenticated;
GRANT ALL ON public.scan_sessions TO service_role;
ALTER TABLE public.scan_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY scan_sessions_all ON public.scan_sessions FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE TABLE public.scan_session_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES public.scan_sessions(id) ON DELETE CASCADE,
  order_id UUID NOT NULL,
  scanned_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(session_id, order_id)
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.scan_session_items TO authenticated;
GRANT ALL ON public.scan_session_items TO service_role;
ALTER TABLE public.scan_session_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY scan_session_items_all ON public.scan_session_items FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE INDEX idx_scan_items_session ON public.scan_session_items(session_id);

-- 27. Order status history
CREATE TABLE public.order_status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL,
  old_status_id UUID,
  new_status_id UUID,
  changed_by UUID,
  changed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  source TEXT NOT NULL DEFAULT 'manual'
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.order_status_history TO authenticated;
GRANT ALL ON public.order_status_history TO service_role;
ALTER TABLE public.order_status_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY order_status_history_all ON public.order_status_history FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE INDEX idx_status_history_order ON public.order_status_history(order_id);

-- =============================================
-- FUNCTIONS & TRIGGERS
-- =============================================

-- log_activity RPC
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

-- Auto-create profile on signup
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

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Barcode sequence
CREATE SEQUENCE public.order_barcode_seq START WITH 1;

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

CREATE TRIGGER set_order_barcode
  BEFORE INSERT ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.generate_order_barcode();

-- Courier assignment timestamp
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

CREATE TRIGGER handle_orders_courier_assignment
BEFORE INSERT OR UPDATE ON public.orders
FOR EACH ROW EXECUTE FUNCTION public.handle_orders_courier_assignment();

-- Orders audit trigger
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

CREATE TRIGGER trg_orders_audit
BEFORE INSERT OR UPDATE ON public.orders
FOR EACH ROW EXECUTE FUNCTION public.handle_orders_audit();

-- Cleanup old activity logs
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

-- Realtime
ALTER TABLE public.messages REPLICA IDENTITY FULL;
ALTER TABLE public.scan_session_items REPLICA IDENTITY FULL;
ALTER TABLE public.order_status_history REPLICA IDENTITY FULL;
ALTER TABLE public.orders REPLICA IDENTITY FULL;
ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.scan_session_items;
ALTER PUBLICATION supabase_realtime ADD TABLE public.order_status_history;
ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;