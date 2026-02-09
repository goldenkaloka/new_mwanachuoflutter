-- =====================================================
-- Product Orders & Offers System Migration
-- =====================================================
-- This migration creates tables for:
-- 1. Product orders (marketplace purchases)
-- 2. Product order items (multi-item orders)
-- 3. Product offers (negotiation system)
-- 4. Offer history (counter-offers tracking)

-- =====================================================
-- PRODUCT ORDERS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.product_orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    buyer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    seller_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Pricing
    total_amount NUMERIC NOT NULL DEFAULT 0,
    original_price NUMERIC, -- Original listing price before negotiation
    agreed_price NUMERIC, -- Final negotiated price (if different from original)
    
    -- Payment
    payment_method TEXT NOT NULL CHECK (payment_method IN ('zenopay', 'cash', 'campus_delivery')),
    payment_status TEXT DEFAULT 'pending' NOT NULL CHECK (payment_status IN ('pending', 'paid', 'failed', 'refunded')),
    
    -- Delivery
    delivery_method TEXT NOT NULL CHECK (delivery_method IN ('pickup', 'campus_delivery', 'meetup')),
    delivery_spot_id UUID REFERENCES public.campus_spots(id), -- For campus pickup/delivery
    delivery_address TEXT,
    delivery_phone TEXT,
    
    -- Status
    order_status TEXT DEFAULT 'pending_payment' NOT NULL CHECK (
        order_status IN ('pending_payment', 'paid', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded')
    ),
    
    -- Tracking
    tracking_notes TEXT,
    
    -- Links to chat and offers
    conversation_id UUID REFERENCES public.conversations(id), -- Link to negotiation chat
    offer_id UUID, -- Link to accepted offer (if applicable)
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =====================================================
-- PRODUCT ORDER ITEMS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS public.product_order_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES public.product_orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id),
    
    -- Product snapshot (preserve product details at time of purchase)
    product_snapshot JSONB NOT NULL DEFAULT '{}'::jsonb,
    -- Snapshot structure: { "title": "...", "images": [...], "seller_name": "...", "description": "..." }
    
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    price_at_time NUMERIC NOT NULL,
    
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =====================================================
-- PRODUCT OFFERS TABLE (Negotiation System)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.product_offers (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    buyer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    seller_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    
    -- Offer details
    offer_amount NUMERIC NOT NULL CHECK (offer_amount > 0),
    original_price NUMERIC NOT NULL,
    message TEXT, -- Optional message from buyer
    
    -- Status
    status TEXT DEFAULT 'pending' NOT NULL CHECK (
        status IN ('pending', 'accepted', 'declined', 'countered', 'expired')
    ),
    
    -- Expiration (offers expire after 24 hours)
    expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '24 hours') NOT NULL,
    
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =====================================================
-- OFFER HISTORY TABLE (Counter-offers tracking)
-- =====================================================
CREATE TABLE IF NOT EXISTS public.offer_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    offer_id UUID NOT NULL REFERENCES public.product_offers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    amount NUMERIC NOT NULL CHECK (amount > 0),
    message TEXT,
    action TEXT NOT NULL CHECK (action IN ('offer', 'counter', 'accept', 'decline')),
    
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================
CREATE INDEX idx_product_orders_buyer ON public.product_orders(buyer_id);
CREATE INDEX idx_product_orders_seller ON public.product_orders(seller_id);
CREATE INDEX idx_product_orders_status ON public.product_orders(order_status);
CREATE INDEX idx_product_orders_conversation ON public.product_orders(conversation_id);
CREATE INDEX idx_product_orders_created ON public.product_orders(created_at DESC);

CREATE INDEX idx_product_order_items_order ON public.product_order_items(order_id);
CREATE INDEX idx_product_order_items_product ON public.product_order_items(product_id);

CREATE INDEX idx_product_offers_buyer ON public.product_offers(buyer_id);
CREATE INDEX idx_product_offers_seller ON public.product_offers(seller_id);
CREATE INDEX idx_product_offers_product ON public.product_offers(product_id);
CREATE INDEX idx_product_offers_conversation ON public.product_offers(conversation_id);
CREATE INDEX idx_product_offers_status ON public.product_offers(status);
CREATE INDEX idx_product_offers_expires ON public.product_offers(expires_at);

CREATE INDEX idx_offer_history_offer ON public.offer_history(offer_id);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.product_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offer_history ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- PRODUCT ORDERS POLICIES
-- =====================================================

-- Buyers can view their own orders
CREATE POLICY "Buyers can view their orders" ON public.product_orders
    FOR SELECT TO authenticated USING (auth.uid() = buyer_id);

-- Sellers can view orders for their products
CREATE POLICY "Sellers can view their orders" ON public.product_orders
    FOR SELECT TO authenticated USING (auth.uid() = seller_id);

-- Buyers can create orders
CREATE POLICY "Buyers can create orders" ON public.product_orders
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = buyer_id);

-- Buyers can update their own orders (e.g., cancel)
CREATE POLICY "Buyers can update their orders" ON public.product_orders
    FOR UPDATE TO authenticated USING (auth.uid() = buyer_id);

-- Sellers can update order status
CREATE POLICY "Sellers can update order status" ON public.product_orders
    FOR UPDATE TO authenticated USING (auth.uid() = seller_id);

-- =====================================================
-- PRODUCT ORDER ITEMS POLICIES
-- =====================================================

-- View if you can view the parent order
CREATE POLICY "View order items if related to order" ON public.product_order_items
    FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.product_orders 
            WHERE public.product_orders.id = product_order_items.order_id 
            AND (
                public.product_orders.buyer_id = auth.uid() 
                OR public.product_orders.seller_id = auth.uid()
            )
        )
    );

-- Buyers can create order items for their orders
CREATE POLICY "Buyers can create order items" ON public.product_order_items
    FOR INSERT TO authenticated WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.product_orders 
            WHERE public.product_orders.id = product_order_items.order_id 
            AND public.product_orders.buyer_id = auth.uid()
        )
    );

-- =====================================================
-- PRODUCT OFFERS POLICIES
-- =====================================================

-- Buyers can view their own offers
CREATE POLICY "Buyers can view their offers" ON public.product_offers
    FOR SELECT TO authenticated USING (auth.uid() = buyer_id);

-- Sellers can view offers on their products
CREATE POLICY "Sellers can view offers on their products" ON public.product_offers
    FOR SELECT TO authenticated USING (auth.uid() = seller_id);

-- Buyers can create offers
CREATE POLICY "Buyers can create offers" ON public.product_offers
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = buyer_id);

-- Buyers can update their own offers (e.g., withdraw)
CREATE POLICY "Buyers can update their offers" ON public.product_offers
    FOR UPDATE TO authenticated USING (auth.uid() = buyer_id);

-- Sellers can update offers on their products (accept/decline/counter)
CREATE POLICY "Sellers can update offers on their products" ON public.product_offers
    FOR UPDATE TO authenticated USING (auth.uid() = seller_id);

-- =====================================================
-- OFFER HISTORY POLICIES
-- =====================================================

-- View if you can view the parent offer
CREATE POLICY "View offer history if related to offer" ON public.offer_history
    FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.product_offers 
            WHERE public.product_offers.id = offer_history.offer_id 
            AND (
                public.product_offers.buyer_id = auth.uid() 
                OR public.product_offers.seller_id = auth.uid()
            )
        )
    );

-- Anyone involved in the offer can add to history
CREATE POLICY "Participants can create offer history" ON public.offer_history
    FOR INSERT TO authenticated WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.product_offers 
            WHERE public.product_offers.id = offer_history.offer_id 
            AND (
                public.product_offers.buyer_id = auth.uid() 
                OR public.product_offers.seller_id = auth.uid()
            )
        )
    );

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Update updated_at timestamp on product_orders
CREATE OR REPLACE FUNCTION update_product_order_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER product_orders_updated_at
    BEFORE UPDATE ON public.product_orders
    FOR EACH ROW
    EXECUTE FUNCTION update_product_order_updated_at();

-- Update updated_at timestamp on product_offers
CREATE TRIGGER product_offers_updated_at
    BEFORE UPDATE ON public.product_offers
    FOR EACH ROW
    EXECUTE FUNCTION update_product_order_updated_at();

-- =====================================================
-- NOTIFICATION FUNCTION (for new orders and offers)
-- =====================================================

-- Notify seller when new order is placed
CREATE OR REPLACE FUNCTION notify_seller_new_order()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert notification for seller
    INSERT INTO public.notifications (
        user_id,
        title,
        message,
        type,
        data,
        created_at
    ) VALUES (
        NEW.seller_id,
        'New Product Order',
        'You have a new order!',
        'product_order',
        jsonb_build_object(
            'order_id', NEW.id,
            'buyer_id', NEW.buyer_id,
            'total_amount', NEW.total_amount
        ),
        now()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER product_order_created_notification
    AFTER INSERT ON public.product_orders
    FOR EACH ROW
    EXECUTE FUNCTION notify_seller_new_order();

-- Notify seller when new offer is made
CREATE OR REPLACE FUNCTION notify_seller_new_offer()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.notifications (
        user_id,
        title,
        message,
        type,
        data,
        created_at
    ) VALUES (
        NEW.seller_id,
        'New Offer Received',
        'Someone made an offer on your product!',
        'product_offer',
        jsonb_build_object(
            'offer_id', NEW.id,
            'product_id', NEW.product_id,
            'buyer_id', NEW.buyer_id,
            'offer_amount', NEW.offer_amount,
            'original_price', NEW.original_price
        ),
        now()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER product_offer_created_notification
    AFTER INSERT ON public.product_offers
    FOR EACH ROW
    EXECUTE FUNCTION notify_seller_new_offer();

-- Notify buyer when offer is accepted/declined/countered
CREATE OR REPLACE FUNCTION notify_buyer_offer_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status != OLD.status THEN
        INSERT INTO public.notifications (
            user_id,
            title,
            message,
            type,
            data,
            created_at
        ) VALUES (
            NEW.buyer_id,
            CASE NEW.status
                WHEN 'accepted' THEN 'Offer Accepted!'
                WHEN 'declined' THEN 'Offer Declined'
                WHEN 'countered' THEN 'Counter Offer Received'
                ELSE 'Offer Status Updated'
            END,
            CASE NEW.status
                WHEN 'accepted' THEN 'Your offer was accepted! Complete your purchase now.'
                WHEN 'declined' THEN 'Your offer was declined by the seller.'
                WHEN 'countered' THEN 'The seller sent you a counter offer.'
                ELSE 'Your offer status has been updated.'
            END,
            'product_offer_status',
            jsonb_build_object(
                'offer_id', NEW.id,
                'product_id', NEW.product_id,
                'status', NEW.status,
                'offer_amount', NEW.offer_amount
            ),
            now()
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER product_offer_status_notification
    AFTER UPDATE ON public.product_offers
    FOR EACH ROW
    EXECUTE FUNCTION notify_buyer_offer_status();
