# AttendanceLite - School Attendance Made Simple

AttendanceLite is a high-fidelity, lightning-fast school attendance platform built with modern HTML, CSS (Tailwind v4), vanilla TypeScript (compiled via Vite), and Supabase. It features dynamic client-side routing, responsive progress rings, calendar log history grids, an admin panel with search & filter parameters, instant attendance toggling, and an interactive inline SVG analytics chart.

---

## 🛠️ Tech Stack & Features

- **Front-End**: Vanilla HTML5, TypeScript, Tailwind CSS v4, Canvas Particle Engine.
- **Routing**: Single-Page App (SPA) hash-router (`#/`, `#/signup`, `#/login`, `#/dashboard`, `#/admin`).
- **Database**: Supabase Auth & PostgreSQL Firestore proxy.
- **Durable Persistence**: Dynamic Row Level Security (RLS) guaranteeing that students only access their own records while teachers read and overwrite entire rosters.
- **Dual Mode**: Features an automatic **Demo Mode** fallback. If Supabase keys are not present in `.env`, the app automatically launches with realistic seeded local data inside `localStorage`!

---

## 🚀 Setting Up Supabase Database

To connect a live Supabase project, execute the following steps:

### Step 1: Create the Tables & Security Policies
1. Open your [Supabase Workspace](https://supabase.com).
2. Go to the **SQL Editor** tab from the left sidebar.
3. Click **New Query**, and paste the entire contents of the `supabase-schema.sql` file.
4. Click **Run** to execute the query. This builds:
   - `profiles` table with enums.
   - `attendance` check-in table.
   - `school_days` calendar configurations.
   - All Row Level Security (RLS) Policies.
   - An automatic metadata-trigger to link signup credentials with database student listings.

### Step 2: Retrieve API Keys
Go to **Project Settings** > **API** in the Supabase console, and copy:
1. `Project URL` (Corresponds to `SUPABASE_URL`)
2. `anon public` key (Corresponds to `SUPABASE_ANON_KEY`)

---

## 💻 Local Development

### Step 1: Clone and Configure Env Variables
Define your keys in a `.env` file at the root of the project:

```env
SUPABASE_URL="https://your-project-id.supabase.co"
SUPABASE_ANON_KEY="your-anon-public-api-key"
```

### Step 2: Install and Run Dev Server
```bash
# Install packages
npm install

# Start the local development server (binds to port 3000)
npm run dev
```

Open `http://localhost:3000` in your browser.

---

## 🎨 User Experience Guides

### A. Demo Mode testing
If you do not configure Supabase credentials, you can immediately preview the full high-fidelity interface using pre-configured mock credentials:

- **Student Login**:
  - Email: `irish@example.com`
  - Password: *Use any password*
- **Administrator Login**:
  - Email: `admin@example.com`
  - Password: *Use any password*

### B. Functional Highlights
- **Streak 🔥 Counts**: Calculated on-the-fly by checking consecutive present school days backwards from today.
- **Progress Rings**: Fully animated inline SVGs representing student attendance rates (color-coded: Green for ok, Amber for caution, Red for warnings).
- **Admin Table Filters**: Updates on-the-fly when typing student names, selecting classes, or picking any calendar date!
- **Interactive Toggles**: Administrators can double-click status switches or click table actions to instantly overwrite student log tables, which automatically updates the aggregate stats.
