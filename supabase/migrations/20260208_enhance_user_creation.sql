CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (
        id,
        email,
        full_name,
        phone_number,
        user_type,
        role,
        business_name,
        business_category,
        tin_number
    )
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'name',
        NEW.raw_user_meta_data->>'phone_number',
        COALESCE(NEW.raw_user_meta_data->>'user_type', 'student'),
        COALESCE(NEW.raw_user_meta_data->>'role', 'buyer'),
        NEW.raw_user_meta_data->>'business_name',
        NEW.raw_user_meta_data->>'business_category',
        NEW.raw_user_meta_data->>'tin_number'
    )
    ON CONFLICT (id) DO UPDATE
    SET
        email = EXCLUDED.email,
        full_name = EXCLUDED.full_name,
        phone_number = EXCLUDED.phone_number,
        user_type = EXCLUDED.user_type,
        role = EXCLUDED.role,
        business_name = EXCLUDED.business_name,
        business_category = EXCLUDED.business_category,
        tin_number = EXCLUDED.tin_number;

    -- Wallet creation logic
    INSERT INTO public.wallets (user_id, balance, currency)
    VALUES (NEW.id, 0.00, 'TZS')
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
