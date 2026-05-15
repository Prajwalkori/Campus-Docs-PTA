// Vercel Serverless Function - Assign Admin Role
// Deploy to Vercel with env variables: SUPABASE_URL, SERVICE_ROLE_KEY

import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_ROLE_KEY = process.env.SERVICE_ROLE_KEY;

if (!SUPABASE_URL || !SERVICE_ROLE_KEY) {
  throw new Error('Missing required environment variables: SUPABASE_URL or SERVICE_ROLE_KEY');
}

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

export default async function handler(req, res) {
  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { user_id } = req.body;

    if (!user_id) {
      return res.status(400).json({ error: 'user_id is required' });
    }

    // Update profiles table to set role as 'admin'
    const { data, error } = await supabase
      .from('profiles')
      .update({ role: 'admin' })
      .eq('id', user_id)
      .select();

    if (error) {
      return res.status(500).json({ error: error.message });
    }

    return res.status(200).json({ 
      success: true, 
      message: 'User assigned as admin',
      data 
    });
  } catch (error) {
    console.error('Error assigning admin role:', error);
    return res.status(500).json({ error: error.message });
  }
}
