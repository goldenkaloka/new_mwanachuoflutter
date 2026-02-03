-- Fix grant_business_trial to avoid invalid ON CONFLICT
CREATE OR REPLACE FUNCTION public.grant_business_trial()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_plan_id UUID;
BEGIN
    IF NEW.user_type = 'business' THEN
        -- Get the first active subscription plan
        SELECT id INTO v_plan_id
        FROM public.subscription_plans
        WHERE is_active = true
        ORDER BY created_at
        LIMIT 1;

        -- Create a 2-month free trial subscription if one doesn't exist
        IF NOT EXISTS (SELECT 1 FROM public.seller_subscriptions WHERE seller_id = NEW.id) THEN
            INSERT INTO public.seller_subscriptions (
                seller_id,
                plan_id,
                status,
                is_trial,
                billing_period,
                current_period_start,
                current_period_end,
                grace_period_end,
                auto_renew
            ) VALUES (
                NEW.id,
                v_plan_id,
                'active',
                true,
                'monthly',
                NOW(),
                NOW() + INTERVAL '2 months',
                NOW() + INTERVAL '2 months' + INTERVAL '7 days',
                false
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

-- Fix handle_new_user to insert into public.users AND public.wallets
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert into public.users
    INSERT INTO public.users (id, email, full_name, phone_number, user_type, role)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'name',
        NEW.raw_user_meta_data->>'phone_number',
        COALESCE(NEW.raw_user_meta_data->>'user_type', 'student'),
        'buyer'
    )
    ON CONFLICT (id) DO UPDATE
    SET
        email = EXCLUDED.email,
        full_name = EXCLUDED.full_name,
        phone_number = EXCLUDED.phone_number,
        user_type = EXCLUDED.user_type;

    -- Create wallet for new user with 0 balance
    INSERT INTO public.wallets (user_id, balance, currency)
    VALUES (NEW.id, 0.00, 'TZS')
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
