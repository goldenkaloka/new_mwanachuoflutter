-- Create Campus Spots table
CREATE TABLE IF NOT EXISTS public.campus_spots (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    university_id TEXT, -- Optional linkage to university
    icon TEXT, -- Material icon name
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable RLS for campus_spots
ALTER TABLE public.campus_spots ENABLE ROW LEVEL SECURITY;

-- Policies for campus_spots
CREATE POLICY "Enable read access for all authenticated users" ON public.campus_spots
    FOR SELECT TO authenticated USING (true);

-- Create Orders table
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, -- Student
    vendor_id UUID NOT NULL REFERENCES auth.users(id), -- Cook/Seller
    runner_id UUID REFERENCES auth.users(id), -- Delivery Boy (Optional initially)
    status TEXT DEFAULT 'pending' NOT NULL CHECK (status IN ('pending', 'confirmed', 'cooking', 'ready_for_pickup', 'on_way', 'delivered', 'cancelled')),
    total_amount NUMERIC NOT NULL DEFAULT 0,
    payment_status TEXT DEFAULT 'pending' NOT NULL CHECK (payment_status IN ('pending', 'paid', 'failed')),
    delivery_spot_id UUID REFERENCES public.campus_spots(id),
    meeting_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable RLS for orders
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Policies for orders
-- Students can see their own orders
CREATE POLICY "Users can view their own orders" ON public.orders
    FOR SELECT TO authenticated USING (auth.uid() = user_id);

-- Vendors can see orders assigned to them
CREATE POLICY "Vendors can view orders assigned to them" ON public.orders
    FOR SELECT TO authenticated USING (auth.uid() = vendor_id);

-- Runners can see orders assigned to them OR ready for pickup (if looking for jobs)
CREATE POLICY "Runners can view assigned or available orders" ON public.orders
    FOR SELECT TO authenticated 
    USING (
        auth.uid() = runner_id 
        OR (runner_id IS NULL AND status = 'ready_for_pickup')
    );

-- Students can insert orders
CREATE POLICY "Students can create orders" ON public.orders
    FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

-- Vendors can update status of their orders
CREATE POLICY "Vendors can update their orders" ON public.orders
    FOR UPDATE TO authenticated USING (auth.uid() = vendor_id);

-- Runners can update status of their assigned orders or claim open ones
CREATE POLICY "Runners can update assigned orders" ON public.orders
    FOR UPDATE TO authenticated USING (
        auth.uid() = runner_id 
        OR (runner_id IS NULL AND status = 'ready_for_pickup')
    );


-- Create Order Items table
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id),
    quantity INTEGER NOT NULL DEFAULT 1,
    price_at_time NUMERIC NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Enable RLS for order_items
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Policies for order_items
-- Viewable if the parent order is viewable (This is complex in RLS, simplified strategy: view if you are related to the order)
-- Using EXISTS for cleaner logic

CREATE POLICY "View order items if related to order" ON public.order_items
    FOR SELECT TO authenticated USING (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE public.orders.id = order_items.order_id 
            AND (
                public.orders.user_id = auth.uid() 
                OR public.orders.vendor_id = auth.uid() 
                OR public.orders.runner_id = auth.uid()
                OR (public.orders.runner_id IS NULL AND public.orders.status = 'ready_for_pickup')
            )
        )
    );

CREATE POLICY "Students can create order items" ON public.order_items
    FOR INSERT TO authenticated WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.orders 
            WHERE public.orders.id = order_items.order_id 
            AND public.orders.user_id = auth.uid()
        )
    );

-- Indexes for performance
CREATE INDEX idx_orders_user_id ON public.orders(user_id);
CREATE INDEX idx_orders_vendor_id ON public.orders(vendor_id);
CREATE INDEX idx_orders_runner_id ON public.orders(runner_id);
CREATE INDEX idx_orders_status ON public.orders(status);
CREATE INDEX idx_campus_spots_university ON public.campus_spots(university_id);
