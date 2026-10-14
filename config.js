/* ============================================================
 * Mission Control — konfigurasi Supabase untuk frontend publik.
 * Project: https://gvuhcoyyxcaxehehztbt.supabase.co
 *
 * AMAN untuk publik: ini publishable/anon key (dirancang untuk
 * diekspos di frontend); yang membatasi akses adalah RLS di
 * supabase-schema.sql. JANGAN taruh service_role/secret key di sini.
 * ============================================================ */
window.MC_CONFIG = {
  SUPABASE_URL: 'https://gvuhcoyyxcaxehehztbt.supabase.co',
  SUPABASE_ANON_KEY: 'sb_publishable_ksZBuvu8AZEHu5YAnPcBsw_k2AqJXIz'
};
