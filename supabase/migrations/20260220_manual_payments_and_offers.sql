-- Final Consolidated Payment & Offers System
-- Includes: Wallets, Transactions, Manual Payments, Coupons, Referrals, and ZenoPay Order compatibility

-- 1. DROP EXISTING BROKEN FUNCTIONS
DROP FUNCTION IF EXISTS public.credit_wallet_balance(uuid, numeric, text, text);
DROP FUNCTION IF EXISTS public.deduct_wallet_balance(uuid, numeric, text, text);

-- 2. CREATE TABLES
-- Wallets
CREATE TABLE IF NOT EXISTS public.wallets (
    user_id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
    currency TEXT NOT NULL DEFAULT 'TZS',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Wallet Transactions
DO $$ BEGIN
    CREATE TYPE wallet_transaction_type AS ENUM ('deposit', 'fee', 'payment', 'refund');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS public.wallet_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    wallet_id UUID NOT NULL REFERENCES public.wallets(user_id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL,
    type wallet_transaction_type NOT NULL,
    reference_id TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ZenoPay Orders (For compatibility)
CREATE TABLE IF NOT EXISTS public.zenopay_orders (
    order_id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'completed', 'failed')),
    type TEXT NOT NULL CHECK (type IN ('wallet_topup', 'subscription', 'promotion')),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Manual Payment Requests
CREATE TABLE IF NOT EXISTS public.manual_payment_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL,
    transaction_ref TEXT NOT NULL,
    payer_phone TEXT,
    type TEXT NOT NULL CHECK (type IN ('topup', 'subscription', 'promotion')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    admin_note TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Coupons
CREATE TABLE IF NOT EXISTS public.coupons (
    code TEXT PRIMARY KEY,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed')),
    value NUMERIC NOT NULL,
    max_uses INTEGER,
    current_uses INTEGER DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- User Coupons
CREATE TABLE IF NOT EXISTS public.user_coupons (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    coupon_code TEXT NOT NULL REFERENCES public.coupons(code) ON DELETE CASCADE,
    used_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, coupon_code)
);

-- Referrals
CREATE TABLE IF NOT EXISTS public.referrals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    referrer_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    referee_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed')),
    reward_amount NUMERIC DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(referee_id)
);

-- 3. ENABLE RLS
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.zenopay_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.manual_payment_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

-- 4. POLICIES
CREATE POLICY "Users can view own wallet" ON public.wallets FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can view own transactions" ON public.wallet_transactions FOR SELECT USING (wallet_id = auth.uid());
CREATE POLICY "Users can view own orders" ON public.zenopay_orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can view own payment requests" ON public.manual_payment_requests FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own payment requests" ON public.manual_payment_requests FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Coupons are viewable by all" ON public.coupons FOR SELECT USING (true);
CREATE POLICY "Users can view own coupon usage" ON public.user_coupons FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can view relevant referrals" ON public.referrals FOR SELECT USING (auth.uid() = referrer_id OR auth.uid() = referee_id);

-- 5. RPC FUNCTIONS
-- deduct_wallet_balance
CREATE OR REPLACE FUNCTION public.deduct_wallet_balance(
    p_user_id UUID,
    p_amount NUMERIC,
    p_description TEXT,
    p_reference_id TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_balance NUMERIC;
    v_new_balance NUMERIC;
BEGIN
    SELECT balance INTO v_current_balance FROM public.wallets WHERE user_id = p_user_id FOR UPDATE;
    IF v_current_balance IS NULL THEN
        INSERT INTO public.wallets (user_id, balance) VALUES (p_user_id, 0) RETURNING balance INTO v_current_balance;
    END IF;
    IF v_current_balance < p_amount THEN
        RETURN jsonb_build_object('success', false, 'message', 'Insufficient balance');
    END IF;
    v_new_balance := v_current_balance - p_amount;
    UPDATE public.wallets SET balance = v_new_balance WHERE user_id = p_user_id;
    INSERT INTO public.wallet_transactions (wallet_id, amount, type, reference_id, description)
    VALUES (p_user_id, -p_amount, 'fee', p_reference_id, p_description);
    RETURN jsonb_build_object('success', true, 'new_balance', v_new_balance);
END;
$$;

-- credit_wallet_balance
CREATE OR REPLACE FUNCTION public.credit_wallet_balance(
    p_user_id UUID,
    p_amount NUMERIC,
    p_reference_id TEXT,
    p_description TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_new_balance NUMERIC;
BEGIN
    INSERT INTO public.wallets (user_id, balance)
    VALUES (p_user_id, p_amount)
    ON CONFLICT (user_id) 
    DO UPDATE SET balance = public.wallets.balance + excluded.balance
    RETURNING balance INTO v_new_balance;
    
    INSERT INTO public.wallet_transactions (wallet_id, amount, type, reference_id, description)
    VALUES (p_user_id, p_amount, 'deposit', p_reference_id, p_description);
    
    -- Update ZenoPay Order if reference_id matches (compatibility)
    UPDATE public.zenopay_orders
    SET status = 'completed', completed_at = now()
    WHERE order_id = p_reference_id;
    
    RETURN jsonb_build_object('success', true, 'new_balance', v_new_balance);
END;
$$;

-- submit_payment_proof
CREATE OR REPLACE FUNCTION public.submit_payment_proof(
    p_amount NUMERIC,
    p_transaction_ref TEXT,
    p_payer_phone TEXT,
    p_type TEXT,
    p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS public.manual_payment_requests
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_request public.manual_payment_requests;
BEGIN
    INSERT INTO public.manual_payment_requests (user_id, amount, transaction_ref, payer_phone, type, metadata)
    VALUES (auth.uid(), p_amount, p_transaction_ref, p_payer_phone, p_type, p_metadata)
    RETURNING * INTO v_request;
    RETURN v_request;
END;
$$;

-- approve_manual_payment
CREATE OR REPLACE FUNCTION public.approve_manual_payment(
    p_request_id UUID,
    p_admin_note TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_request public.manual_payment_requests;
    v_wallet_result JSONB;
BEGIN
    SELECT * INTO v_request FROM public.manual_payment_requests WHERE id = p_request_id AND status = 'pending' FOR UPDATE;
    IF v_request IS NULL THEN
        RETURN jsonb_build_object('success', false, 'message', 'Request not found or already processed');
    END IF;
    SELECT credit_wallet_balance(v_request.user_id, v_request.amount, v_request.transaction_ref, 'Manual Payment Approved') INTO v_wallet_result;
    IF (v_wallet_result->>'success')::BOOLEAN THEN
        UPDATE public.manual_payment_requests SET status = 'approved', admin_note = p_admin_note, updated_at = now() WHERE id = p_request_id;
        RETURN jsonb_build_object('success', true, 'message', 'Approved and credited');
    ELSE
        RETURN v_wallet_result;
    END IF;
END;
$$;
