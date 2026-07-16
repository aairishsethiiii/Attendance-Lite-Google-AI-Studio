-- =====================================================================
-- AttendanceLite - Complete Supabase SQL Database Schema & RLS Policies
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. ENUMS AND CUSTOM TYPES
-- ---------------------------------------------------------------------
-- Define a roles enum to distinguish students from administrators
CREATE TYPE public.user_role AS ENUM ('student', 'admin');
CREATE TYPE public.attendance_status AS ENUM ('present', 'absent');

-- ---------------------------------------------------------------------
-- 2. TABLES DEFINITIONS
-- ---------------------------------------------------------------------

-- Profiles Table
-- Holds student and teacher identities, referencing Supabase Auth
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
    name TEXT NOT NULL,
    class TEXT,
    role public.user_role NOT NULL DEFAULT 'student'::public.user_role,
    enrollment_date DATE NOT NULL DEFAULT CURRENT_DATE
);

-- School Calendar Days Table
-- Tracks school vs non-school days, holidays, and terms
CREATE TABLE public.school_days (
    date DATE PRIMARY KEY,
    is_school_day BOOLEAN NOT NULL DEFAULT TRUE,
    holiday_name TEXT
);

-- Attendance Logs Table
-- Records check-ins, guaranteeing unique student entries per school day
CREATE TABLE public.attendance (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    status public.attendance_status NOT NULL DEFAULT 'present'::public.attendance_status,
    marked_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_student_per_day UNIQUE (user_id, date)
);

-- ---------------------------------------------------------------------
-- 3. ENABLE ROW LEVEL SECURITY (RLS)
-- ---------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.school_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

-- ---------------------------------------------------------------------
-- 4. SECURITY POLICIES (RLS)
-- ---------------------------------------------------------------------

-- == PROFILES TABLE POLICIES ==

-- Policy A: Students can view their own profile details
CREATE POLICY "Students can view own profile" 
ON public.profiles 
FOR SELECT 
USING (auth.uid() = id);

-- Policy B: Students can update their own profile details (such as names or class changes)
CREATE POLICY "Students can update own profile" 
ON public.profiles 
FOR UPDATE 
USING (auth.uid() = id);

-- Policy C: Administrators can view all student and administrator profiles
CREATE POLICY "Admins can view all profiles" 
ON public.profiles 
FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'::public.user_role
    )
);

-- Policy D: Administrators can insert or update any profile row
CREATE POLICY "Admins have full write control on profiles" 
ON public.profiles 
FOR ALL 
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'::public.user_role
    )
);


-- == SCHOOL DAYS TABLE POLICIES ==

-- Policy A: Anyone (authenticated or public) can view school calendar days
CREATE POLICY "School calendar is publicly viewable" 
ON public.school_days 
FOR SELECT 
USING (true);

-- Policy B: Only administrators can add or alter school days / holidays
CREATE POLICY "Admins manage school calendar days" 
ON public.school_days 
FOR ALL 
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'::public.user_role
    )
);


-- == ATTENDANCE LOGS TABLE POLICIES ==

-- Policy A: Students can view only their own attendance records
CREATE POLICY "Students view own attendance logs" 
ON public.attendance 
FOR SELECT 
USING (auth.uid() = user_id);

-- Policy B: Students can log their own attendance check-ins (Mark Present)
CREATE POLICY "Students insert own attendance check-in" 
ON public.attendance 
FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Policy C: Administrators can view all logged school attendances
CREATE POLICY "Admins view all attendance logs" 
ON public.attendance 
FOR SELECT 
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'::public.user_role
    )
);

-- Policy D: Administrators can add, override, or delete any attendance logs
CREATE POLICY "Admins overwrite any attendance logs" 
ON public.attendance 
FOR ALL 
USING (
    EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'::public.user_role
    )
);

-- ---------------------------------------------------------------------
-- 5. SIGN UP TRIGGERS AND HANDLERS
-- ---------------------------------------------------------------------

-- Create a background function to automatically populate public.profiles
-- when a new user registers with email/password through Supabase Auth.
CREATE OR REPLACE FUNCTION public.handle_auth_user_signup()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, name, class, role)
    VALUES (
        new.id,
        COALESCE(new.raw_user_meta_data->>'name', 'Student User'),
        COALESCE(new.raw_user_meta_data->>'class', 'Unassigned'),
        -- New signups always default to student role unless explicitly passed as admin metadata
        COALESCE((new.raw_user_meta_data->>'role')::public.user_role, 'student'::public.user_role)
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach trigger to auth.users schema
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_auth_user_signup();

-- ---------------------------------------------------------------------
-- 6. SEED DATA (OPTIONAL SEED FOR DEMO CONVENIENCE)
-- ---------------------------------------------------------------------
-- Insert standard school days (e.g. July 2026 school days)
-- WEEKENDS can be excluded or added with is_school_day = FALSE.
-- For simple automation, populate some sample calendar dates:
INSERT INTO public.school_days (date, is_school_day, holiday_name) VALUES
('2026-07-01', TRUE, NULL),
('2026-07-02', TRUE, NULL),
('2026-07-03', TRUE, NULL),
('2026-07-04', FALSE, 'Independence Day'),
('2026-07-05', FALSE, 'Weekend'),
('2026-07-06', TRUE, NULL),
('2026-07-07', TRUE, NULL),
('2026-07-08', TRUE, NULL),
('2026-07-09', TRUE, NULL),
('2026-07-10', TRUE, NULL),
('2026-07-11', FALSE, 'Weekend'),
('2026-07-12', FALSE, 'Weekend'),
('2026-07-13', TRUE, NULL),
('2026-07-14', TRUE, NULL),
('2026-07-15', TRUE, NULL),
('2026-07-16', TRUE, NULL),
('2026-07-17', TRUE, NULL);
