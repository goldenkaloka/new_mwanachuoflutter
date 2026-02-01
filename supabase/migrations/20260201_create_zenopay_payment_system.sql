-- Migration: Create wallets, transactions, and zenopay orders
-- Date: 2026-02-01

-- 1. Create Wallets Table
CREATE TABLE IF NOT EXISTS public.wallets (
    user_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (balance >= 0),
    currency TEXT NOT NULL DEFAULT 'TZS',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Create Wallet Transactions Table
CREATE TYPE wallet_transaction_type AS ENUM ('deposit', 'fee', 'payment', 'refund');

CREATE TABLE IF NOT EXISTS public.wallet_transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    wallet_id UUID NOT NULL REFERENCES public.wallets(user_id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL, -- Positive for deposit/refund, Negative for fee/payment
    type wallet_transaction_type NOT NULL,
    reference_id TEXT, -- Can be order_id, product_id, etc.
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Create ZenoPay Orders Table
-- specific to ZenoPay integration to track lifecycle of a payment
CREATE TABLE IF NOT EXISTS public.zenopay_orders (
    order_id TEXT PRIMARY KEY, -- ZenoPay Order ID
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'completed', 'failed')),
    type TEXT NOT NULL CHECK (type IN ('wallet_topup', 'subscription', 'promotion')),
    metadata JSONB DEFAULT '{}'::jsonb, -- Store extra info like plan_id, duration_days
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 4. Enable RLS
ALTER TABLE public.wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.zenopay_orders ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies
-- Wallets: Users can view their own wallet
CREATE POLICY "Users can view own wallet" ON public.wallets
    FOR SELECT USING (auth.uid() = user_id);

-- Wallet Transactions: Users can view their own transactions
CREATE POLICY "Users can view own wallet transactions" ON public.wallet_transactions
    FOR SELECT USING (wallet_id = auth.uid());

-- ZenoPay Orders: Users can view their own orders
CREATE POLICY "Users can view own zenopay orders" ON public.zenopay_orders
    FOR SELECT USING (user_id = auth.uid());

-- 6. Trigger to update updated_at on wallets
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_wallets_updated_at
    BEFORE UPDATE ON public.wallets
    FOR EACH ROW
    EXECUTE PROCEDURE update_updated_at_column();

-- 7. RPC: Deduct Wallet Balance (Atomic)
CREATE OR REPLACE FUNCTION deduct_wallet_balance(
    p_user_id UUID,
    p_amount NUMERIC,
    p_description TEXT,
    p_reference_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_balance NUMERIC;
    v_new_balance NUMERIC;
BEGIN
    -- Lock the wallet row for update
    SELECT balance INTO v_current_balance
    FROM public.wallets
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF v_current_balance IS NULL THEN
        -- Create wallet if it doesn't exist (auto-init)
        INSERT INTO public.wallets (user_id, balance)
        VALUES (p_user_id, 0)
        RETURNING balance INTO v_current_balance;
    END IF;

    IF v_current_balance < p_amount THEN
        RETURN jsonb_build_object(
            'success', false,
            'message', 'Insufficient balance',
            'current_balance', v_current_balance
        );
    END IF;

    v_new_balance := v_current_balance - p_amount;

    -- Update wallet
    UPDATE public.wallets
    SET balance = v_new_balance
    WHERE user_id = p_user_id;

    -- Record transaction
    INSERT INTO public.wallet_transactions (wallet_id, amount, type, reference_id, description)
    VALUES (p_user_id, -p_amount, 'fee', p_reference_id, p_description);

    RETURN jsonb_build_object(
        'success', true,
        'new_balance', v_new_balance,
        'message', 'Deduction successful'
    );
END;
$$;

-- 8. RPC: Credit Wallet (For ZenoPay Webhook)
CREATE OR REPLACE FUNCTION credit_wallet_balance(
    p_user_id UUID,
    p_amount NUMERIC,
    p_order_id TEXT,
    p_description TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_balance NUMERIC;
    v_new_balance NUMERIC;
BEGIN
    -- Upsert wallet (create if not exists)
    INSERT INTO public.wallets (user_id, balance)
    VALUES (p_user_id, p_amount)
    ON CONFLICT (user_id) 
    DO UPDATE SET balance = public.wallets.balance + excluded.balance
    RETURNING balance INTO v_new_balance;

    -- Record transaction
    INSERT INTO public.wallet_transactions (wallet_id, amount, type, reference_id, description)
    VALUES (p_user_id, p_amount, 'deposit', p_order_id, p_description);

    -- Update ZenoPay Order status if it exists
    UPDATE public.zenopay_orders
    SET status = 'completed', completed_at = now()
    WHERE order_id = p_order_id;

    RETURN jsonb_build_object(
        'success', true,
        'new_balance', v_new_balance,
        'message', 'Credit successful'
    );
END;
$$;
