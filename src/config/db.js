const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_ANON_KEY;

if (!url || !key) {
  throw new Error('Faltan SUPABASE_URL o SUPABASE_ANON_KEY en .env');
}

const supabase = createClient(url, key);

module.exports = supabase;
